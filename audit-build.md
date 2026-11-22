# Laporan Implementasi P0/P1 JejakTim

## Hasil

- `DemoRepository` kini memvalidasi data `jejaktim.demo.v1` sebelum dipakai. JSON rusak, akar JSON bertipe salah, atau koleksi utama bertipe salah akan dipulihkan ke seed bersih dan seed pemulihan ditulis kembali ke `SharedPreferences`; bootstrap tidak lagi melempar `FormatException`/`TypeError` dari data tersebut.
- `addUpdate` kini menolak tugas berstatus `done` dan `cancelled` dengan pesan pengguna: **“Tugas yang selesai atau dibatalkan tidak dapat diperbarui.”**
- Mode demo dibuat lebih jelas pada seluruh halaman terautentikasi melalui banner **“Mode demo lokal aktif”** dan penjelasan bahwa data contoh hanya tersimpan di perangkat.
- Beranda kini menampilkan dua aksi utama yang berbeda: **“Buat proyek baru”** dan **“Gabung dengan kode”**. Tata letak berubah dari kolom pada layar sempit menjadi baris pada ruang yang lebih lebar; kolom kode undangan tetap tersedia.
- Status loading kini menyertakan teks **“Memuat data tim…”** alih-alih hanya indikator putar.
- Tes laporan hanya memeriksa byte PDF di memori. Tes tidak lagi menulis `../outputs/JejakTim-contoh-laporan.pdf`, dan artefak lama tersebut sudah dihapus.

## File yang diubah/dibuat

- `app/lib/data/demo_repository.dart` — validasi/pemulihan penyimpanan demo dan aturan status `addUpdate`.
- `app/lib/core/layout.dart` — banner demo yang lebih terlihat serta teks loading.
- `app/lib/features/projects/project_screens.dart` — aksi utama Beranda yang berbeda dan responsif.
- `app/test/domain_flow_test.dart` — regresi JSON/type storage rusak serta penolakan update tugas selesai/dibatalkan.
- `app/test/home_actions_test.dart` — tes baru untuk kejelasan mode demo dan aksi Beranda pada ukuran 360×800 dan 800×390.
- `app/test/report_test.dart` — validasi PDF berbasis byte tanpa keluaran persisten.
- `audit-build.md` — laporan implementasi ini.

Tidak ada file generated, dependency, konfigurasi Firebase, atau secret yang diubah.

## Verifikasi dan keluaran aktual

1. RED sebelum perbaikan:
   - Pemulihan storage gagal dengan `FormatException: Unexpected character` dari `DemoRepository`.
   - `addUpdate` pada tugas `done` mengembalikan tugas dengan update baru, bukan `AppFailure`.
   - Tes UI tidak menemukan `Mode demo lokal aktif`.

2. Format:

   ```text
   Formatted lib/data/demo_repository.dart
   Formatted lib/features/projects/project_screens.dart
   Formatted test/domain_flow_test.dart
   Formatted test/home_actions_test.dart
   Formatted 6 files (4 changed) in 4.99 seconds.
   ```

3. Analisis statis:

   Perintah: `flutter analyze --no-pub`

   ```text
   Analyzing app...
   No issues found! (ran in 71.1s)
   ```

4. Tes terfokus:

   Perintah: `flutter test test/domain_flow_test.dart test/home_actions_test.dart test/report_test.dart`

   ```text
   +9: All tests passed!
   Verified: no persistent report PDF artifact
   ```

   Cakupan regresi baru mencakup JSON tidak valid, akar JSON non-object, koleksi utama salah tipe, persistensi seed pemulihan, status `done`/`cancelled`, banner demo, aksi Beranda, dua ukuran viewport, serta byte PDF.

5. Seluruh test suite dengan batas 540 detik:

   Perintah: `perl -e 'alarm shift; exec @ARGV' 540 flutter test`

   ```text
   01:39 +23: All tests passed!
   ```

6. Pemeriksaan artefak laporan setelah full suite:

   ```text
   /Users/macbook/Documents/ChatGPT/Indoneris/outputs/JejakTim-contoh-laporan.pdf: tidak ditemukan
   ```

## Kendala yang ditemui

- Percobaan pertama wrapper timeout berbasis `python3 -c` gagal sebelum menjalankan tes karena quoting baris baru:

  ```text
  SyntaxError: unexpected character after line continuation character
  ```

  Tes penuh kemudian dijalankan ulang dengan alarm Perl dan berhasil seperti keluaran di atas.
- Proyek bukan repositori Git (`fatal: not a git repository`), sehingga tidak ada commit hash yang dapat dicatat.
- Perintah `diff` terhadap backup mengembalikan exit code 1 karena file memang berbeda; diff mengonfirmasi perubahan terbatas pada tiga file sumber yang disebutkan.

## Batasan tersisa

- Pemulihan data demo sengaja mengganti data lokal yang rusak dengan seed bersih; tidak ada migrasi parsial untuk menyelamatkan bagian JSON yang masih valid.
- Validasi recovery berfokus pada bentuk akar dan enam koleksi utama. Validasi domain rinci tetap dilakukan saat tindakan terkait dijalankan.
- Perubahan UI diverifikasi dengan widget test responsif, bukan pengujian visual manual pada perangkat fisik.
- Jalur produksi/Firebase tidak diubah dan tidak diuji ulang dalam pekerjaan ini.

## Backup

`/Users/macbook/.hermes/cache/scratch/jejaktim-before-ux-fix-20261118-232649`
