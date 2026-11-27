<div align="center">
  <img src="docs/jejaktim-logo.svg" alt="Logo JejakTim" width="112" />
  <h1>JejakTim</h1>
  <p><strong>Ruang kerja sederhana untuk tugas kelompok mahasiswa.</strong></p>
  <p>Catat tugas, lihat progres, beri review, dan simpan jejak kerja tim dalam satu tempat.</p>

  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-54C5F8?logo=flutter&logoColor=white" alt="Dibuat dengan Flutter" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dibuat dengan Dart" /></a>
  <a href="https://supabase.com"><img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white" alt="Didukung Supabase" /></a>
  <a href="https://github.com/OrganicoconutSugar/JejakTim"><img src="https://img.shields.io/badge/platform-Android%20%7C%20Web-202633" alt="Platform Android dan Web" /></a>
</div>

## JejakTim itu apa?

JejakTim adalah aplikasi kolaborasi untuk kelompok mahasiswa. Aplikasi ini membantu tim membagi tugas dengan jelas, memperbarui progres, mengirim bukti pekerjaan, melakukan peer review, berdiskusi lewat chat proyek, dan mengekspor laporan kontribusi PDF dalam satu tempat.

Nama **JejakTim** dipilih karena setiap langkah kerja tim tetap tercatat dan mudah dilihat kembali. Logo tiga jalur berwarna yang bertemu melambangkan beberapa orang yang bergerak dengan peran berbeda, lalu menyatukan hasilnya di satu tujuan.

## Fitur Utama

- Autentikasi email & Google OAuth berbasis **Supabase Auth**.
- Buat proyek dengan ikon/foto khusus dan bagikan kode undangan ke anggota.
- Buat tugas, tentukan penanggung jawab dan reviewer yang berbeda dari pelaksana.
- Catat progres atau kendala, kirim bukti foto atau tautan, minta revisi, lalu setujui hasil kerja.
- Chat proyek dengan lampiran foto & tautan file khusus anggota proyek.
- Ringkasan Team Insight berbasis data tugas aktual.
- Ekspor **Laporan Proses & Kontribusi PDF** lengkap dengan penanggung jawab, reviewer, dan ringkasan jejak kontribusi per anggota.

## Teknologi yang digunakan

| Bagian | Teknologi |
| --- | --- |
| Aplikasi | Flutter dan Dart |
| Tampilan | Material 3, custom design tokens, Outfit dan Roboto |
| Navigasi | `go_router` |
| State | Riverpod |
| Backend & Realtime | Supabase (Auth, Postgres RPC, RLS, Storage, Realtime) |
| Media & Dokumen | `video_player`, `image_picker`, SVG, PDF & `printing` |

## Menjalankan di komputer

1. Jalankan seluruh skema SQL di folder [`supabase/`](supabase/) secara berurutan (`001` hingga `008`) melalui Supabase SQL Editor.
2. Siapkan konfigurasi Supabase di `app/supabase.config.json` (lihat contoh di [`app/supabase.config.example.json`](app/supabase.config.example.json)).
3. Jalankan aplikasi:

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define-from-file=supabase.config.json
```

Untuk Android:

```bash
cd app
flutter run --dart-define-from-file=supabase.config.json
```

## Struktur singkat

```text
app/                 Aplikasi Flutter (UI, routing, repository, test)
app/assets/          Logo, ilustrasi, ikon, font, foto onboarding, dan video pembuka
supabase/            Skema, kebijakan RLS/Storage, dan fungsi RPC Supabase (001–007)
docs/                Asset identitas JejakTim untuk dokumentasi
```

## Status proyek

JejakTim berjalan penuh dengan backend **Supabase** di platform Android dan Web. Integrasi model AI generatif untuk Team Insight masih dalam tahap pengembangan; ringkasan pada halaman Insight saat ini dihitung langsung dari data tugas aktual.

## Pengujian

```bash
cd app
flutter analyze
flutter test
```

<div align="center">
  <sub>Dibuat dengan Flutter & Supabase untuk membantu tim mahasiswa bekerja lebih rapi.</sub>
</div>
