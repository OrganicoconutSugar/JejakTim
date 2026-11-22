# Audit QA fungsional — JejakTim Flutter

**Target:** `/Users/macbook/Documents/ChatGPT/Indoneris/app`  
**Mode:** read-only pada kode proyek; tidak ada perubahan pada source, test, lockfile, dependensi, atau generated file di `app/` oleh audit. Satu side effect dari test yang sudah ada membuat/memperbarui PDF di sibling `outputs/`; dicatat sebagai Temuan 3. Proyek bukan repository Git, sehingga status perubahan tidak tersedia.

## Ringkasan

Ditemukan **3 temuan terverifikasi**: **2 Medium**, **1 Low**. Tidak ada Critical/High yang terbukti pada cakupan ini.

| Severity | Jumlah |
|---|---:|
| Critical | 0 |
| High | 0 |
| Medium | 2 |
| Low | 1 |

## Temuan

### 1. [Medium] Tugas selesai masih menerima pembaruan progres

**Lokasi:** `lib/data/demo_repository.dart:466-484` (cabang `addUpdate` tidak memeriksa status tugas); pembatasan UI hanya menyembunyikan tombol di `lib/features/tasks/task_screens.dart:461-466`, sementara layar aksi cukup memeriksa peran di `:714-720`.

Tugas berstatus `done` dapat diubah melalui aksi `addUpdate`. Ini mengubah versi dan riwayat tugas yang seharusnya final. Batasan hanya ada pada tampilan, bukan pada validasi domain demo.

**Reproduksi:**
```text
1. Inisialisasi DemoRepository baru.
2. Muat tugas `t3` sebagai `raka`; seed mendefinisikannya berstatus `done`.
3. Panggil `command('raka', 'addUpdate', {projectId: 'p1', taskId: 't3',
   version: 1, message: 'Update sesudah selesai', kind: 'progress'})`.
4. Periksa hasil command.
```

**Output nyata:**
```text
REPRO_STATE status=done updates=1 version=2
```

**Diharapkan:** command ditolak dengan pesan bahwa tugas selesai/dibatalkan tidak dapat diberi progres.  
**Aktual:** command berhasil, menambahkan satu update dan menaikkan versi menjadi 2 walau status tetap `done`.

---

### 2. [Medium] Data demo lokal yang rusak menggagalkan inisialisasi aplikasi tanpa pemulihan

**Lokasi:** `lib/data/demo_repository.dart:35-36`; konstruktor langsung menjalankan `jsonDecode(saved) as Json` tanpa `try/catch`. `AppController` selalu membangun `DemoRepository` pada `lib/core/controller.dart:27-29`, termasuk sebelum pengguna memilih demo.

Satu nilai SharedPreferences demo yang bukan JSON valid melempar `FormatException`. Karena pembuatan controller terjadi saat bootstrap, aplikasi tidak mencapai UI yang bisa menawarkan reset/recovery.

**Reproduksi:**
```text
1. Set SharedPreferences: `jejaktim.demo.v1 = '{not-json'`.
2. Buat `DemoRepository(await SharedPreferences.getInstance())`
   (jalur yang dipakai konstruktor AppController).
3. Amati exception.
```

**Output nyata:**
```text
REPRO_ERROR FormatException: Unexpected character
```

**Diharapkan:** data lokal invalid diabaikan/diganti seed yang bersih dan pengguna diberi pemberitahuan pemulihan.  
**Aktual:** konstruktor melempar exception; sesi demo dan bootstrap aplikasi terhenti.

---

### 3. [Low] Test ekspor laporan menulis artefak permanen di luar direktori app

**Lokasi:** `test/report_test.dart:7`, khususnya `File('../outputs/JejakTim-contoh-laporan.pdf').writeAsBytes(bytes)`.

Menjalankan test yang seharusnya menjadi verifikasi membuat/memperbarui PDF di sibling directory `../outputs`. Ini membuat `flutter test` tidak aman untuk workflow audit/read-only dan berisiko mengotori workspace/CI.

**Reproduksi:**
```text
cd /Users/macbook/Documents/ChatGPT/Indoneris/app
flutter test --no-pub test/report_test.dart
stat -f '%N | size=%z | modified=%Sm' -t '%Y-%m-%d %H:%M:%S %z' \
  ../outputs/JejakTim-contoh-laporan.pdf
```

**Output nyata:**
```text
report snapshot exports a readable PDF artifact
All tests passed!
/Users/macbook/Documents/ChatGPT/Indoneris/outputs/JejakTim-contoh-laporan.pdf | size=7189 | modified=2026-11-18 23:07:46 +0700
```

**Diharapkan:** test memakai direktori temporer atau hanya memeriksa bytes, tanpa menulis artefak persisten.  
**Aktual:** PDF dibuat/diperbarui di `Indoneris/outputs`. File tidak dihapus oleh audit karena keberadaannya sebelum eksekusi tidak dapat dipastikan.

## Verifikasi yang dijalankan

| Cakupan | Perintah / hasil |
|---|---|
| Analisis statis | `flutter analyze --no-pub` → `No issues found! (ran in 51.1s)` |
| Domain, validasi auth, dan PDF | `flutter test --no-pub test/domain_flow_test.dart test/auth_test.dart test/report_test.dart` → `+7: All tests passed!` |
| Splash, registrasi, semantik logo | `flutter test --no-pub test/splash_video_test.dart test/register_test.dart test/brand_logo_test.dart` → `+4: All tests passed!` |
| Responsif teruji | `layout_test.dart` pada `360x800` / text `2.0` → lulus; `800x390` / text `2.0` → lulus. Keduanya memompa 11 layar dan memeriksa exception Flutter. |
| Reproduksi temuan | Test sementara **di cache audit, bukan project** → `+2: All tests passed!`, dengan output `REPRO_STATE ...` dan `REPRO_ERROR ...` di atas. |

## Tidak diverifikasi

- **Seluruh suite dalam satu eksekusi:** `flutter test --no-pub` dihentikan batas waktu 300 detik pada `+16`; runner menerima `SIGTERM (-15)` saat finalisasi dan mengeluarkan exit `124`. Ini adalah batas waktu tool, **bukan** bukti kegagalan produk. File-file test utama kemudian dijalankan secara terpisah seperti tabel di atas; namun semua kombinasi ukuran/scale pada `layout_test.dart` belum selesai sebagai satu suite.
- **Firebase/Auth Google/Cloud Functions/`deleteAccount`:** tidak diverifikasi terhadap layanan nyata. Audit tidak menyalakan server/emulator dan backend Cloud Functions tidak ada dalam target kode.
- **Berbagi PDF ke aplikasi sistem/browser:** pembentukan PDF tervalidasi oleh test; interaksi `Printing.sharePdf` pada perangkat nyata tidak dijalankan.
- **Aksesibilitas manual perangkat:** inspeksi kode menunjukkan tooltip/label pada tombol utama dan test `BrandLogo` semantik lulus. Pembaca layar dan navigasi keyboard perangkat nyata tidak dijalankan.

## Cakupan yang lolos inspeksi

- Validasi email, kata sandi, URL bukti HTTPS, revisi/versi stale, isolasi proyek, preview/join undangan, dan fallback AI tercakup oleh test domain yang lulus.
- Tidak ada exception pada dua profil responsif yang dijalankan, termasuk layar sempit dengan skala teks 2.0 dan lanskap rendah dengan skala teks 2.0.
