import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../core/illustrated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/controller.dart';
import '../../core/models.dart';
import '../../core/design.dart';
import '../../core/layout.dart';
import '../../core/evidence_photo.dart';

Widget profilePhoto(Map<String, dynamic> profile, {double size = 80}) {
  final data = textOf(profile, 'avatarDataUrl');
  if (!data.startsWith('data:image/') || !data.contains(',')) {
    return Avatar(textOf(profile, 'name'), size: size);
  }
  try {
    return ClipOval(
      child: Image.memory(
        base64Decode(data.split(',').last),
        width: size,
        height: size,
        fit: BoxFit.cover,
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
    return PageFrame(
      navIndex: 3,
      child: ContentList(
        children: [
          const SizedBox(height: 8),
          Text(
            'Ruang untukmu.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 28),
          Surface(
            color: C.panel,
            child: Column(
              children: [
                profilePhoto(c.profile),
                const SizedBox(height: 16),
                Text(
                  textOf(c.profile, 'name'),
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  textOf(c.profile, 'email'),
                  style: const TextStyle(color: C.muted),
                ),
                const SizedBox(height: 12),
                Pill(
                  textOf(c.profile, 'major', 'Mahasiswa'),
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/profile/edit'),
                  icon: const AppIcon(LucideIcons.pencil, size: 16),
                  label: const Text('Edit profil'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _item(
            context,
            LucideIcons.bell,
            'Notifikasi',
            '/profile/notifications',
          ),
          _item(
            context,
            LucideIcons.shieldCheck,
            'Privasi & data',
            '/profile/privacy',
          ),
          _item(
            context,
            LucideIcons.fileText,
            'Ketentuan penggunaan',
            '/profile/terms',
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const DimensionalIcon(
              LucideIcons.compass,
              color: C.purple,
              size: 42,
            ),
            title: const Text('Lihat perkenalan aplikasi'),
            trailing: const AppIcon(LucideIcons.chevronRight, size: 18),
            onTap: () => context.push('/onboarding'),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            onPressed: () async {
              await c.logout();
              if (context.mounted) context.go('/auth/login');
            },
            icon: const AppIcon(LucideIcons.logOut, size: 18),
            label: const Text('Keluar'),
          ),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              'JejakTim AI · 1.0.0\nKerja bareng, kontribusi terlihat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: C.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: DimensionalIcon(
      icon,
      color:
          icon == LucideIcons.bell
              ? const Color(0xFFDF8B2A)
              : const Color(0xFF168B88),
      size: 42,
    ),
    title: Text(title),
    trailing: const AppIcon(LucideIcons.chevronRight, size: 18),
    onTap: () => context.push(route),
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
        Center(
          child: Column(
            children: [
              avatarBytes == null
                  ? profilePhoto(ref.watch(controllerProvider).profile)
                  : ClipOval(
                    child: Image.memory(
                      avatarBytes!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
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
                icon: const AppIcon(LucideIcons.camera, size: 18),
                label: const Text('Unggah foto profil'),
              ),
            ],
          ),
        ),
        const Text(
          'Kenalkan dirimu pada tim.',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        if (error != null) ...[ErrorBanner(error!), const SizedBox(height: 16)],
        Form(
          key: form,
          child: Column(
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama lengkap'),
                validator: (v) => requiredText(v, max: 80),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: institution,
                decoration: const InputDecoration(
                  labelText: 'Perguruan tinggi (opsional)',
                ),
                maxLength: 120,
              ),
              const SizedBox(height: 16),
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
        const SizedBox(height: 24),
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
            color: C.panel,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pengingat di aplikasi'),
              subtitle: const Text(
                'Tampilkan permintaan review dan revisi tugas.',
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
          const SizedBox(height: 20),
          const Text(
            'Notifikasi tampil saat aplikasi dibuka. Push notification tidak diaktifkan pada versi lokal ini.',
            style: TextStyle(color: C.muted),
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
          const AppIcon(LucideIcons.shieldCheck, size: 52, color: C.blue),
          const SizedBox(height: 24),
          Text(
            'Kolaborasi yang\nsaling menjaga.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 24),
          const Text(
            'Data seperlunya',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'JejakTim menggunakan nama, email untuk autentikasi, profil opsional, dan riwayat tugas. Tidak mengakses lokasi, kontak, NIM, atau nilai akademik.',
          ),
          const SectionTitle('Bukti kerja tetap milikmu'),
          const Text(
            'Tautan bukti dibagikan kepada anggota proyek. Atur izin dokumen di penyedia aslinya. Isi dokumen tidak diambil atau dikirim ke AI.',
          ),
          const SectionTitle('AI membantu, tim memutuskan'),
          const Text(
            'Penyedia AI belum dikonfigurasi pada versi lokal. Saat diaktifkan, analisis menggunakan agregat minimal dengan persetujuan sebelum menjalankan. Tidak ada ranking, label moral, atau perubahan tugas otomatis.',
          ),
          const SectionTitle('Laporan & penyimpanan'),
          const Text(
            'PDF dibuat di perangkat dari snapshot terotorisasi. Laporan yang sudah dibagikan berada di kendali penerima. Retensi cloud final belum ditetapkan; konfigurasi pengembangan memberi expiry snapshot 30 hari, tanpa menjanjikan penghapusan otomatis sebelum TTL diaktifkan.',
          ),
          const SectionTitle('Foto profil'),
          const Text(
            'Foto profil tampil kepada anggota proyek yang sama. Kamu dapat menggantinya melalui Edit profil.',
          ),
          const SectionTitle('Hapus akun'),
          const Text(
            'Ketua perlu menyelesaikan atau mengalihkan kepemilikan proyek lebih dahulu. Penghapusan mencabut keanggotaan dan menghapus profil; nama profil dihapus, sementara ID pelaku dan riwayat kerja tetap disimpan untuk menjaga konteks tim.',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
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
            icon: const AppIcon(LucideIcons.trash2),
            label: const Text('Hapus akun'),
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
        Text(
          'Kerja bersama, dengan tanggung jawab.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SectionTitle('Akun dan akses'),
        const Text(
          'Gunakan akun milik sendiri. Undangan proyek hanya boleh dibagikan kepada anggota tim yang berwenang.',
        ),
        const SectionTitle('Konten dan bukti kerja'),
        const Text(
          'Unggah hanya materi yang boleh kamu bagikan. Anggota proyek dapat melihat tugas, progres, dan bukti kerja yang kamu kirim.',
        ),
        const SectionTitle('Saran AI'),
        const Text(
          'Saran koordinasi bersifat bantuan. Keputusan tugas dan penilaian kontribusi tetap berada pada anggota tim.',
        ),
        const SectionTitle('Akun dan data'),
        const Text(
          'Kamu dapat memperbarui profil dan meminta penghapusan akun melalui halaman Privasi & data. Beberapa riwayat kerja tetap disimpan untuk menjaga konteks proyek.',
        ),
      ],
    ),
  );
}
