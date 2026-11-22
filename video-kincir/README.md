# Kincir portrait — Remotion

Video aset baling-baling untuk project mobile, memakai PNG asli tanpa menggambar ulang.
Remotion dikunci pada 4.0.320 dan TypeScript pada 5.8.3 untuk kompatibilitas
dengan macOS 13 pada perangkat ini. Remotion 4.0.544 gagal menjalankan FFmpeg
karena membutuhkan macOS 15. Instalasi versi lama melaporkan 14 temuan audit
dependensi; editor ini ditujukan untuk pekerjaan lokal dengan aset tepercaya.

- 1080 × 1920 (9:16), 60 fps, 8 detik.
- Putaran searah jarum jam, 1 putaran / 2 detik, total 4 putaran.
- Loop mulus: tidak ada fade atau jeda di sambungan.
- Poros gambar di (619, 648.5), ditempatkan pada tengah video.
- Ukuran 82% dari aset asli; seluruh baling-baling tetap aman di dalam frame sepanjang rotasi.
- Tanpa audio, teks, atau watermark tambahan.

## Editor

```sh
npm install
npm run studio
```

Pilih `KincirPortrait` untuk latar putih, atau `KincirTransparent` untuk alpha.
Launcher menyalin runtime ke folder sementara agar kompatibel dengan nama folder
project yang mengandung `!`. Setelah mengubah sumber ketika Studio sedang terbuka,
jalankan ulang `npm run studio` untuk menyinkronkan perubahan.
Di panel Props, ubah `secondsPerTurn` untuk kecepatan (angka kecil = lebih cepat)
dan `background` untuk warna latar. Agar loop mulus, durasi 8 detik harus habis
dibagi `secondsPerTurn` (contoh: 1, 2, 4, 8).

## Render

```sh
npm run render
npm run render:transparent
```

MP4 H.264 untuk pemutaran umum pada mobile. WebM VP9 alpha untuk integrasi
yang mendukung video transparan; periksa dukungan di player aplikasi target.
MP4 tidak menyimpan transparansi.

Animasi ditentukan oleh nomor frame, mengikuti [konsep Remotion](https://www.remotion.dev/docs/idea).
Perintah render: [dokumentasi resmi](https://www.remotion.dev/docs/cli/render).

Implementasi animasi berada di `src/index.tsx`. Ubah `scale` untuk ukuran aset;
ubah `durationInFrames` pada Composition untuk durasi video.
