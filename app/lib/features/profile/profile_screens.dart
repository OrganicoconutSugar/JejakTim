import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/controller.dart';
import '../../core/models.dart';
import '../../core/design.dart';
import '../../core/geo_icons.dart';
import '../../core/layout.dart';
import '../../core/evidence_photo.dart';

Widget profilePhoto(Map<String, dynamic> profile, {double size = 72}) {
  final data = textOf(profile, 'avatarDataUrl');
  if (!data.startsWith('data:image/') || !data.contains(',')) {
    return Avatar(textOf(profile, 'name'), size: size);
  }
  try {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: ClipOval(
        child: Image.memory(
          base64Decode(data.split(',').last),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  } catch (_) {
    return Avatar(textOf(profile, 'name'), size: size);
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    final activeProjects = c.projects.where((p) => p['status'] == 'active');
    final activeIds = activeProjects.map((p) => p['id']).toSet();
    final teamTasks =
        c.tasks
            .where(
              (t) =>
                  activeIds.contains(t['projectId']) &&
                  t['status'] != 'cancelled',
            )
            .toList();
    final completed = teamTasks.where((t) => t['status'] == 'done').length;
    final reviews = teamTasks.where((t) => t['status'] == 'submitted').length;
    final revisions =
        teamTasks.where((t) => t['status'] == 'revision_requested').length;
    final pct = teamTasks.isEmpty ? 0.0 : completed / teamTasks.length;

    return PageFrame(
      navIndex: 3,
      child: ContentList(
        children: [
          // Gradient Profile Card
          Surface(
            gradient: C.brandGradient,
            radius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    profilePhoto(c.profile, size: 68),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            textOf(c.profile, 'name', 'Pengguna'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: T.h1.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            textOf(c.profile, 'email'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: T.small.copyWith(
                              color: Colors.white.withValues(alpha: .85),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              textOf(c.profile, 'major', 'Mahasiswa'),
                              style: T.caption.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: S.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: C.blue,
                      minimumSize: const Size(48, 44),
                    ),
                    onPressed: () => context.push('/profile/edit'),
                    icon: const GeoIcon(GeoIconKind.pencil, size: 18),
                    label: const Text('Edit profil'),
                  ),
                ),
              ],
            ),
          ),

          const SectionTitle('Rangkuman kinerja tim'),
          Surface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStat(
                        '${activeIds.length}',
                        'Proyek aktif',
                        C.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProfileStat(
                        '$completed/${teamTasks.length}',
                        'Selesai',
                        C.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProfileStat(
                        '$reviews',
                        'Review',
                        C.purple,
                      ),
                    ),
                  ],
                ),
                if (teamTasks.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 7,
                      color: C.blue,
                      backgroundColor: C.sky,
                      semanticsLabel: 'Penyelesaian tugas proyek aktif',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      Text(
                        '$completed dari ${teamTasks.length} tugas selesai',
                        style: T.caption,
                      ),
                      Text(
                        '$revisions perlu revisi',
                        style: T.caption.copyWith(
                          color: revisions > 0 ? C.orange : C.muted,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Belum ada tugas dalam proyek aktif.',
                    style: T.small,
                  ),
                ],
                const Divider(height: 22),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go('/insights'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        GeoIcon(GeoIconKind.star, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lihat Insight tim',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: C.blue,
                            ),
                          ),
                        ),
                        GeoIcon(GeoIconKind.chevronRight, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SectionTitle('Pengaturan akun'),
          Surface(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _item(
                  context,
                  GeoIconKind.pencil,
                  'Edit profil dan foto',
                  '/profile/edit',
                ),
                const Divider(indent: 58),
                _item(
                  context,
                  GeoIconKind.bell,
                  'Notifikasi',
                  '/profile/notifications',
                ),
                const Divider(indent: 58),
                _item(
                  context,
                  GeoIconKind.shield,
                  'Privasi & data',
                  '/profile/privacy',
                ),
                const Divider(indent: 58),
                _item(
                  context,
                  GeoIconKind.document,
                  'Ketentuan penggunaan',
                  '/profile/terms',
                ),
              ],
            ),
          ),

          const SectionTitle('Bantuan'),
          Surface(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              leading: const GeoIcon(GeoIconKind.compass, size: 28),
              title: const Text('Lihat perkenalan aplikasi', style: T.bodyStrong),
              trailing: const GeoIcon(GeoIconKind.chevronRight, size: 16),
              onTap: () => context.push('/onboarding'),
            ),
          ),

          const SizedBox(height: S.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: C.blush,
                foregroundColor: C.rose,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                await c.logout();
                if (context.mounted) context.go('/auth/login');
              },
              icon: const GeoIcon(GeoIconKind.logout, size: 20),
              label: const Text('Keluar'),
            ),
          ),
          const SizedBox(height: S.xl),
          const Center(
            child: Text(
              'JejakTim AI · 1.0.0\nKerja bareng, kontribusi terlihat.',
              textAlign: TextAlign.center,
              style: T.caption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    GeoIconKind icon,
    String title,
    String route,
  ) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    leading: GeoIcon(icon, size: 28),
    title: Text(title, style: T.bodyStrong),
    trailing: const GeoIcon(GeoIconKind.chevronRight, size: 16),
    onTap: () => context.push(route),
  );
}

class _ProfileStat extends StatelessWidget {
  final String value, label;
  final Color accent;
  const _ProfileStat(this.value, this.label, this.accent);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: C.panel,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: T.h2.copyWith(color: accent, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: T.caption,
        ),
      ],
    ),
  );
}

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditState();
}

class _ProfileEditState extends ConsumerState<ProfileEditScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      institution = TextEditingController(),
      major = TextEditingController();
  bool busy = false;
  Uint8List? avatarBytes;
  String? avatarMime;
  String? error;
  @override
  void initState() {
    super.initState();
    final p = ref.read(controllerProvider).profile;
    name.text = textOf(p, 'name');
    institution.text = textOf(p, 'institution');
    major.text = textOf(p, 'major');
  }

  @override
  void dispose() {
    name.dispose();
    institution.dispose();
    major.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Edit profil',
    child: ContentList(
      children: [
        Surface(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              avatarBytes == null
                  ? profilePhoto(
                    ref.watch(controllerProvider).profile,
                    size: 84,
                  )
                  : ClipOval(
                    child: Image.memory(
                      avatarBytes!,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed:
                    busy
                        ? null
                        : () async {
                          try {
                            final chosen = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 512,
                              maxHeight: 512,
                              imageQuality: 65,
                            );
                            if (chosen == null) return;
                            final bytes = await chosen.readAsBytes();
                            final type = detectEvidencePhoto(bytes);
                            if (type == null || bytes.length > 250 * 1024) {
                              throw const AppFailure(
                                'Gunakan JPG, PNG, atau WebP maksimal 250 KB.',
                              );
                            }
                            if (mounted) {
                              setState(() {
                                avatarBytes = bytes;
                                avatarMime = type.mimeType;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => error = errorMessage(e));
                            }
                          }
                        },
                icon: const GeoIcon(GeoIconKind.camera, size: 20),
                label: const Text('Unggah foto profil'),
              ),
            ],
          ),
        ),
        const SizedBox(height: S.lg),
        const Text('Kenalkan dirimu pada tim.', style: T.h2),
        const SizedBox(height: S.md),
        if (error != null) ...[
          ErrorBanner(error!),
          const SizedBox(height: S.md),
        ],
        Form(
          key: form,
          child: Column(
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama lengkap'),
                validator: (v) => requiredText(v, max: 80),
              ),
              const SizedBox(height: S.md),
              TextFormField(
                controller: institution,
                decoration: const InputDecoration(
                  labelText: 'Perguruan tinggi (opsional)',
                ),
                maxLength: 120,
              ),
              const SizedBox(height: S.sm),
              TextFormField(
                controller: major,
                decoration: const InputDecoration(
                  labelText: 'Program studi (opsional)',
                ),
                maxLength: 120,
              ),
            ],
          ),
        ),
        const SizedBox(height: S.xl),
        PrimaryButton(
          'Simpan profil',
          busy: busy,
          onPressed: () async {
            if (!form.currentState!.validate()) return;
            setState(() {
              busy = true;
              error = null;
            });
            try {
              await ref.read(controllerProvider).act('saveProfile', {
                'name': name.text.trim(),
                'institution': institution.text.trim(),
                'major': major.text.trim(),
                if (avatarBytes != null)
                  'avatarDataUrl':
                      'data:$avatarMime;base64,${base64Encode(avatarBytes!)}',
              });
              if (context.mounted) {
                context.pop();
                toast(context, 'Profil diperbarui.');
              }
            } catch (e) {
              if (mounted) setState(() => error = errorMessage(e));
            } finally {
              if (mounted) setState(() => busy = false);
            }
          },
        ),
      ],
    ),
  );
}

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    final enabled = (c.profile['notificationPrefs'] as Map?)?['inApp'] != false;
    return PageFrame(
      title: 'Notifikasi',
      child: ContentList(
        children: [
          Surface(
            color: C.sky,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pengingat di aplikasi', style: T.bodyStrong),
              subtitle: const Text(
                'Tampilkan pengingat di halaman Notifikasi.',
                style: T.caption,
              ),
              value: enabled,
              onChanged:
                  c.busy
                      ? null
                      : (v) async {
                        try {
                          await c.act('saveProfile', {
                            'name': c.profile['name'],
                            'notificationPrefs': {'inApp': v, 'push': false},
                          });
                        } catch (e) {
                          if (context.mounted) toast(context, errorMessage(e));
                        }
                      },
            ),
          ),
          const SectionTitle('Jenis pengingat'),
          Surface(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (final (i, item) in const [
                  (
                    'review',
                    'Permintaan review',
                    'Hasil kerja yang menunggu tinjauanmu.',
                  ),
                  (
                    'revision',
                    'Permintaan revisi',
                    'Tugasmu yang dikembalikan reviewer.',
                  ),
                  (
                    'deadline',
                    'Tenggat mendekat',
                    'Tugasmu yang jatuh tempo hari ini atau tiga hari ke depan.',
                  ),
                ].indexed) ...[
                  if (i > 0) const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.$2, style: T.bodyStrong),
                    subtitle: Text(item.$3, style: T.caption),
                    value: c.notificationCategoryEnabled(item.$1),
                    onChanged:
                        enabled
                            ? (v) async {
                              try {
                                await c.setNotificationCategory(item.$1, v);
                              } catch (e) {
                                if (context.mounted) {
                                  toast(context, errorMessage(e));
                                }
                              }
                            }
                            : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: S.md),
          const Text(
            'Pilihan jenis pengingat disimpan di perangkat ini.',
            style: T.caption,
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    return PageFrame(
      title: 'Privasi & data',
      child: ContentList(
        children: [
          const PageHeader(
            'Kolaborasi yang\nsaling menjaga.',
            subtitle: 'Transparan soal data yang digunakan di JejakTim.',
            trailing: GeoIcon(GeoIconKind.shield, size: 46),
          ),
          ...const [
            (
              'Data seperlunya',
              'JejakTim menggunakan nama, email untuk autentikasi, profil opsional, dan riwayat tugas. Tidak mengakses lokasi, kontak, NIM, atau nilai akademik.',
            ),
            (
              'Bukti kerja tetap milikmu',
              'Tautan bukti dibagikan kepada anggota proyek. Atur izin dokumen di penyedia aslinya. Isi dokumen tidak diambil atau dikirim ke AI.',
            ),
            (
              'AI membantu, tim memutuskan',
              'Analisis AI menggunakan agregat status tugas, tenggat relatif, dan kode anggota anonim setelah kamu menyetujuinya. Nama, email, foto, dan isi dokumen bukti tidak dikirim ke penyedia AI. Jika AI tidak aktif atau offline, aplikasi menampilkan analisis ritme lokal tanpa skor atau ranking.',
            ),
            (
              'Laporan & penyimpanan',
              'PDF dibuat di perangkat dari snapshot terotorisasi. Laporan yang sudah dibagikan berada di kendali penerima. Retensi cloud final belum ditetapkan; konfigurasi pengembangan memberi expiry snapshot 30 hari, tanpa menjanjikan penghapusan otomatis sebelum TTL diaktifkan.',
            ),
            (
              'Foto profil',
              'Foto profil tampil kepada anggota proyek yang sama. Kamu dapat menggantinya melalui Edit profil.',
            ),
            (
              'Hapus akun',
              'Ketua perlu menyelesaikan atau mengalihkan kepemilikan proyek lebih dahulu. Penghapusan mencabut keanggotaan dan menghapus profil; nama profil dihapus, sementara ID pelaku dan riwayat kerja tetap disimpan untuk menjaga konteks tim.',
            ),
          ].map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: S.md),
              child: Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.$1, style: T.title),
                    const SizedBox(height: 6),
                    Text(section.$2, style: T.body),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: S.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: C.blush,
                foregroundColor: C.rose,
              ),
              onPressed: () async {
                if (await confirm(
                  context,
                  'Hapus akun secara permanen?',
                  'Profil dan keanggotaan akan dihapus. Akun harus baru diautentikasi; masuk ulang jika diminta.',
                  label: 'Hapus akun',
                )) {
                  try {
                    await c.act('deleteAccount', {});
                    await c.logout();
                    if (context.mounted) context.go('/auth/login');
                  } catch (e) {
                    if (context.mounted) toast(context, errorMessage(e));
                  }
                }
              },
              icon: const GeoIcon(GeoIconKind.trash, size: 20),
              label: const Text('Hapus akun'),
            ),
          ),
        ],
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Ketentuan penggunaan',
    child: ContentList(
      children: [
        const PageHeader(
          'Kerja bersama,\ndengan tanggung jawab.',
          subtitle: 'Panduan ringkas penggunaan JejakTim.',
          trailing: GeoIcon(GeoIconKind.document, size: 46),
        ),
        ...const [
          (
            'Akun dan akses',
            'Gunakan akun milik sendiri. Undangan proyek hanya boleh dibagikan kepada anggota tim yang berwenang.',
          ),
          (
            'Konten dan bukti kerja',
            'Unggah hanya materi yang boleh kamu bagikan. Anggota proyek dapat melihat tugas, progres, dan bukti kerja yang kamu kirim.',
          ),
          (
            'Saran AI',
            'Saran koordinasi bersifat bantuan. Keputusan tugas dan penilaian kontribusi tetap berada pada anggota tim.',
          ),
          (
            'Akun dan data',
            'Kamu dapat memperbarui profil dan meminta penghapusan akun melalui halaman Privasi & data. Beberapa riwayat kerja tetap disimpan untuk menjaga konteks proyek.',
          ),
        ].map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: S.md),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.$1, style: T.title),
                  const SizedBox(height: 6),
                  Text(section.$2, style: T.body),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
