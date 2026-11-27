import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/controller.dart';
import '../../core/design.dart';
import '../../core/evidence_photo.dart';
import '../../core/layout.dart';
import '../../core/models.dart';
import '../../data/supabase_repository.dart';

class ProjectChatScreen extends ConsumerStatefulWidget {
  const ProjectChatScreen(this.projectId, {super.key});
  final String projectId;

  @override
  ConsumerState<ProjectChatScreen> createState() => _ProjectChatScreenState();
}

class _ProjectChatScreenState extends ConsumerState<ProjectChatScreen> {
  final _draft = TextEditingController();
  List<Json> _messages = [];
  String? _error;
  Timer? _refreshTimer;
  RealtimeChannel? _chatChannel;
  SupabaseTeamRepository? _subscribedRepo;
  bool _loading = false, _syncing = false, _sending = false, _loaded = false;
  bool _hasOlder = false;
  bool _attachmentsEnabled = false;
  bool _picking = false;
  Uint8List? _photo;
  EvidencePhotoType? _photoType;
  String? _fileUrl;
  String? _requestId;

  bool get _canSend =>
      _draft.text.trim().isNotEmpty || _fileUrl != null || _photo != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_load());
      final repo = ref.read(controllerProvider).repository;
      if (repo is SupabaseTeamRepository) {
        _subscribedRepo = repo;
        _chatChannel = repo.watchProjectChat(widget.projectId, () {
          if (mounted && !_sending) unawaited(_load(silent: true));
        });
      }
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        unawaited(_load(silent: true));
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    final channel = _chatChannel;
    final repo = _subscribedRepo;
    _chatChannel = null;
    _subscribedRepo = null;
    if (channel != null && repo != null) {
      unawaited(repo.removeChannel(channel));
    }
    _draft.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (picked == null || !mounted) return;
      if (await picked.length() > maxEvidencePhotoBytes) {
        if (mounted) toast(context, 'Foto maksimal 5 MB.');
        return;
      }
      final bytes = await picked.readAsBytes();
      final type = detectEvidencePhoto(bytes);
      if (!mounted) return;
      if (type == null || bytes.length > maxEvidencePhotoBytes) {
        toast(context, 'Pilih foto JPG, PNG, atau WebP maksimal 5 MB.');
        return;
      }
      setState(() {
        _photo = bytes;
        _photoType = type;
        _requestId = null;
      });
    } catch (_) {
      if (mounted) toast(context, 'Foto belum dapat dipilih. Coba lagi.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickLink() async {
    var draft = _fileUrl ?? '';
    final form = GlobalKey<FormState>();
    final link = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Tambahkan tautan file'),
            content: Form(
              key: form,
              child: TextFormField(
                initialValue: draft,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Tautan file'),
                onChanged: (value) => draft = value,
                validator:
                    (value) =>
                        validEvidence(normalizeEvidenceLink(value ?? ''))
                            ? null
                            : 'Masukkan tautan HTTP atau HTTPS yang valid.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  if (form.currentState!.validate()) {
                    Navigator.pop(ctx, normalizeEvidenceLink(draft));
                  }
                },
                child: const Text('Tambahkan'),
              ),
            ],
          ),
    );
    if (mounted && link != null) {
      setState(() {
        _fileUrl = link;
        _requestId = null;
      });
    }
  }

  Future<void> _openLink(String link) async {
    if (!validEvidence(link)) return;
    try {
      if (await launchUrl(
        Uri.parse(link),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      // Surface a useful error if the browser could not open the link.
    }
    if (mounted) toast(context, 'Tautan tidak dapat dibuka.');
  }

  Future<void> _load({
    bool older = false,
    bool send = false,
    bool silent = false,
  }) async {
    if (_loading || _syncing || _sending || (send && (_picking || !_canSend))) {
      return;
    }
    if (send && !_attachmentsEnabled && (_photo != null || _fileUrl != null)) {
      return;
    }
    final controller = ref.read(controllerProvider);
    final repo = controller.repository;
    final uid = controller.uid;
    if (repo is! SupabaseTeamRepository || uid == null) return;
    final cursor = older ? (_messages.lastOrNull?['id']) : null;
    if (older && cursor == null) return;
    final message = send ? _draft.text.trim() : null;
    final requestId = send ? (_requestId ??= const Uuid().v4()) : null;
    if (silent && !send && !older) {
      _syncing = true;
    } else {
      setState(() {
        _loading = !send;
        _sending = send;
      });
    }
    try {
      String? path;
      if (send && _photo != null) {
        final type = _photoType!;
        path = '${widget.projectId}/$uid/$requestId.${type.extension}';
        await repo.uploadChatImage(path, _photo!, type);
      }
      final result = await repo.command(uid, 'projectChat', {
        'projectId': widget.projectId,
        if (cursor != null) 'beforeId': cursor,
        if (message != null) 'message': message,
        if (requestId != null) 'clientMessageId': requestId,
        if (path != null) 'imagePath': path,
        if (send && _fileUrl != null) 'fileUrl': _fileUrl,
      });
      if (!mounted) return;
      final page = rowsOf(result, 'messages');
      final newestIds = page.map((row) => row['id']).toSet();
      setState(() {
        if (!_loaded || older) _hasOlder = page.length == 50;
        _messages =
            older
                ? [..._messages, ...page]
                : [
                  ...page,
                  ..._messages.where((row) => !newestIds.contains(row['id'])),
                ];
        _loaded = true;
        _attachmentsEnabled = result['attachments'] == true;
        _error = null;
        if (send) {
          _draft.clear();
          _photo = null;
          _photoType = null;
          _fileUrl = null;
          _requestId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorMessage(e);
        if (_error == 'Chat hanya tersedia untuk anggota proyek.') {
          _messages = [];
          _hasOlder = false;
        }
      });
    } finally {
      _syncing = false;
      if (mounted && (_loading || _sending)) {
        setState(() => _loading = _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final project = c.project(widget.projectId);
    if (project == null || !stringsOf(project, 'memberIds').contains(c.uid)) {
      return const PageFrame(
        title: 'Chat proyek',
        child: EmptyState(
          'Akses terbatas',
          'Chat hanya tersedia untuk anggota proyek.',
        ),
      );
    }
    return PageFrame(
      title: 'Chat proyek',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              textOf(project, 'name'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ErrorBanner(_error!),
            ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child:
                _messages.isEmpty
                    ? Center(
                      child: Text(
                        _loaded && _error == null ? 'Belum ada pesan' : '',
                      ),
                    )
                    : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_hasOlder ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return TextButton(
                            onPressed:
                                _loading || _sending
                                    ? null
                                    : () => _load(older: true),
                            child: const Text('Muat pesan sebelumnya'),
                          );
                        }
                        final row = _messages[index];
                        final mine = row['authorId'] == c.uid;
                        return Align(
                          alignment:
                              mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: Surface(
                                color: mine ? C.sky : Colors.white,
                                radius: 18,
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      mine ? 'Kamu' : c.name(row['authorId']),
                                      style: T.bodyStrong.copyWith(
                                        color: mine ? C.blue : C.ink,
                                      ),
                                    ),
                                    if (textOf(row, 'body').isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(textOf(row, 'body'), style: T.body),
                                    ],
                                    if (row['imagePath'] is String &&
                                        c.repository is SupabaseTeamRepository)
                                      _ChatPhoto(
                                        key: ValueKey(row['imagePath']),
                                        path: row['imagePath'] as String,
                                        repository:
                                            c.repository
                                                as SupabaseTeamRepository,
                                      ),
                                    if (validEvidence(textOf(row, 'fileUrl')))
                                      TextButton(
                                        onPressed:
                                            () => _openLink(
                                              textOf(row, 'fileUrl'),
                                            ),
                                        child: Text(
                                          'Buka file · ${Uri.parse(textOf(row, 'fileUrl')).host}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateLabel(row['createdAt'], time: true),
                                      style: T.caption,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          if (_attachmentsEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_photo != null || _fileUrl != null)
                    Wrap(
                      spacing: 8,
                      children: [
                        if (_photo != null)
                          InputChip(
                            avatar: Image.memory(
                              _photo!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            ),
                            label: const Text('Foto terpilih'),
                            onDeleted:
                                _sending
                                    ? null
                                    : () => setState(() {
                                      _photo = null;
                                      _photoType = null;
                                      _requestId = null;
                                    }),
                          ),
                        if (_fileUrl != null)
                          InputChip(
                            label: Text(
                              Uri.parse(_fileUrl!).host,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onDeleted:
                                _sending
                                    ? null
                                    : () => setState(() {
                                      _fileUrl = null;
                                      _requestId = null;
                                    }),
                          ),
                      ],
                    ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Pilih foto',
                        onPressed: _picking || _sending ? null : _pickPhoto,
                        icon: const Icon(LucideIcons.imagePlus),
                      ),
                      IconButton(
                        tooltip: 'Tambahkan tautan file',
                        onPressed: _sending ? null : _pickLink,
                        icon: const Icon(LucideIcons.link),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _draft,
                    readOnly: _sending,
                    onChanged: (_) => setState(() => _requestId = null),
                    minLines: 1,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: const InputDecoration(labelText: 'Tulis pesan'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed:
                      _loading || _sending || _picking || !_canSend
                          ? null
                          : () => _load(send: true),
                  child: Text(_sending ? 'Mengirim…' : 'Kirim'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatPhoto extends StatefulWidget {
  const _ChatPhoto({super.key, required this.path, required this.repository});
  final String path;
  final SupabaseTeamRepository repository;

  @override
  State<_ChatPhoto> createState() => _ChatPhotoState();
}

class _ChatPhotoState extends State<_ChatPhoto> {
  late Future<Uint8List> _bytes = widget.repository.downloadChatImage(
    widget.path,
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _bytes,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton(
          onPressed:
              () => setState(() {
                _bytes = widget.repository.downloadChatImage(widget.path);
              }),
          child: const Text('Muat ulang foto'),
        );
      }
      final bytes = snapshot.data;
      if (bytes == null) {
        return const SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return InkWell(
        onTap:
            () => showDialog<void>(
              context: context,
              builder:
                  (ctx) => Dialog(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: InteractiveViewer(
                            child: Image.memory(
                              bytes,
                              semanticLabel: 'Foto chat',
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
                  ),
            ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            semanticLabel: 'Buka foto chat',
          ),
        ),
      );
    },
  );
}
