import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design.dart';

String buildInviteQrPayload(String code) =>
    'jejaktim://join/${code.trim().toUpperCase()}';

String buildInviteShareText(String projectName, String code) {
  final cleanCode = code.trim().toUpperCase();
  final label = projectName.trim().isEmpty ? 'proyek kelompok' : projectName.trim();
  return 'Yuk gabung ke proyek "$label" di JejakTim!\n'
      'Kode undangan: $cleanCode\n'
      'Buka aplikasi JejakTim → Gabung dengan kode, lalu masukkan kode atau pindai QR dari ketua.';
}

String? extractInviteCode(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) {
    final queryCode = uri.queryParameters['code']?.trim();
    if (queryCode != null && _validCode(queryCode)) {
      return queryCode.toUpperCase();
    }
    if (uri.scheme == 'jejaktim' && uri.host == 'join') {
      final segment = uri.pathSegments.firstOrNull?.trim();
      if (segment != null && _validCode(segment)) {
        return segment.toUpperCase();
      }
    }
    final inviteIdx = uri.pathSegments.indexOf('invite');
    if (inviteIdx >= 0 && inviteIdx + 1 < uri.pathSegments.length) {
      final candidate = uri.pathSegments[inviteIdx + 1].trim();
      if (_validCode(candidate)) {
        return candidate.toUpperCase();
      }
    }
  }

  if (_validCode(trimmed)) {
    return trimmed.toUpperCase();
  }
  return null;
}

bool _validCode(String candidate) =>
    RegExp(r'^[A-Za-z0-9-]{4,64}$').hasMatch(candidate);

class InviteQrDialog extends StatelessWidget {
  final String projectName;
  final String code;

  const InviteQrDialog({
    super.key,
    required this.projectName,
    required this.code,
  });

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) toast(context, 'Kode undangan disalin.');
  }

  Future<void> _share(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: buildInviteShareText(projectName, code),
          subject: 'Undangan proyek JejakTim: $projectName',
        ),
      );
    } catch (_) {
      if (context.mounted) {
        await _copy(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrPayload = buildInviteQrPayload(code);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Ajak timmu bergabung'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pindai QR ini langsung dari aplikasi JejakTim, atau bagikan kodenya kepada calon anggota.',
              textAlign: TextAlign.center,
              style: T.small,
            ),
            const SizedBox(height: S.lg),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: C.line, width: 1.5),
              ),
              child: SizedBox(
                width: 184,
                height: 184,
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 184,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: C.blue,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: C.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: S.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: C.sky,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SelectableText(
                code,
                textAlign: TextAlign.center,
                style: T.h1.copyWith(letterSpacing: 1.4, color: C.blue),
              ),
            ),
            const SizedBox(height: S.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _copy(context),
                  icon: const Icon(LucideIcons.copy, size: 17),
                  label: const Text('Salin kode'),
                ),
                FilledButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(
                    LucideIcons.share2,
                    size: 17,
                    color: Colors.white,
                  ),
                  label: const Text('Bagikan'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}

class InviteQrScannerScreen extends StatefulWidget {
  const InviteQrScannerScreen({super.key});

  @override
  State<InviteQrScannerScreen> createState() => _InviteQrScannerScreenState();
}

class _InviteQrScannerScreenState extends State<InviteQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;
  bool _torchOn = false;
  String? _statusMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final code = extractInviteCode(raw);
      if (code != null) {
        _handled = true;
        Navigator.of(context).pop(code);
        return;
      }
    }
    if (mounted) {
      setState(
        () =>
            _statusMessage =
                'QR ini bukan kode undangan JejakTim. Coba arahkan ke QR undangan ketua.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Pindai QR undangan',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: _torchOn ? 'Matikan lampu' : 'Nyalakan lampu',
            onPressed: () async {
              try {
                await _controller.toggleTorch();
                if (mounted) setState(() => _torchOn = !_torchOn);
              } catch (_) {
                // Torch may not be available on some devices.
              }
            },
            icon: Icon(
              _torchOn ? LucideIcons.zapOff : LucideIcons.zap,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder:
                (context, error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Surface(
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.cameraOff,
                            size: 40,
                            color: C.blue,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Kamera belum dapat diakses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Izinkan akses kamera pada perangkatmu, atau kembali untuk mengetik kode undangan secara manual.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: C.muted),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Masukkan kode manual'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _statusMessage ??
                      'Arahkan kamera ke QR undangan dari ketua proyek.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
