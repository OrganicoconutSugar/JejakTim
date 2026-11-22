# Riset konsep logo JejakTim AI

## Konteks dan batasan

JejakTim AI adalah aplikasi Android kolaborasi tugas mahasiswa: kontribusi anggota terlihat, sementara AI membantu pekerjaan, bukan menilai orang. Arahan visual: ilustrasi vektor flat, outline gelap, warna pastel biru/kuning/merah/hijau, hampir tanpa bayangan, dan tanpa kotak latar di belakang simbol. Dokumen ini adalah riset dan usulan arah; belum ada desain, aset, uji pengguna, atau pemeriksaan kemiripan merek.

## Temuan dari sumber primer

1. **Ikon Android adaptif.** Android meminta lapisan foreground dan background masing-masing 108 × 108 dp. Simbol utama dianjurkan minimal 48 × 48 dp dan maksimal 66 × 66 dp di tengah agar aman dari pemotongan berbagai bentuk. Lapisan monokrom tambahan mendukung ikon bertema. Android menyarankan tepi bersih tanpa mask atau bayangan di sekeliling outline pada lapisan. [Android Developers: Adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive)
2. **Ikon Google Play adalah aset terpisah.** Spesifikasi listing meminta PNG 512 × 512 px, sRGB, maksimum 1024 KB dan bentuk persegi penuh; Google Play menerapkan sudut dan bayangan. Google menyarankan latar penuh untuk logo tanpa bentuk pembingkai yang jelas. Ini tidak mengharuskan kotak dekoratif menjadi bagian logo: simbol dapat tetap bebas, sementara lapisan latar memenuhi kebutuhan wadah platform. [Android Developers: Google Play icon design specifications](https://developer.android.com/distribute/google-play/resources/icon-design-specifications)
3. **Keterbacaan kecil.** Material Design menjelaskan bahwa konsistensi dan bentuk yang sederhana membantu kejelasan ikon sistem pada ukuran kecil. Ini prinsip yang relevan sebagai analogi, bukan bukti bahwa suatu konsep logo tertentu pasti mudah dikenali. [Material Design: System icons](https://m2.material.io/design/iconography/system-icons.html)
4. **Kontras dan aksesibilitas.** WCAG2ICT menerapkan panduan 3:1 pada informasi grafis dan komponen antarmuka tertentu dalam perangkat lunak. W3C menjelaskan logo merek umumnya dikecualikan dari syarat kontras grafis karena tampilan merek bersifat esensial; meski demikian, versi berkontras cukup atau label tambahan disarankan bila logo berfungsi sebagai kontrol. Garis terlalu tipis juga dapat terlihat lebih pudar karena anti-aliasing. Ini panduan aksesibilitas yang berguna, bukan klaim bahwa seluruh warna logo wajib 3:1. [W3C: WCAG2ICT](https://www.w3.org/TR/wcag2ict-22/) · [W3C: Understanding non-text contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)

## Usulan tiga arah konsep

| Arah | Bentuk dan makna | Kekuatan | Risiko yang perlu diuji |
|---|---|---|---|
| **1. Jejak bersama** | Tiga jejak atau langkah sederhana yang saling menyambung membentuk satu alur maju; aksen kilau kecil menunjukkan bantuan AI. | Menghubungkan nama JejakTim dengan kolaborasi dan perjalanan kontribusi. Siluet dapat dibaca tanpa teks. | Terlalu banyak telapak atau detail jari bisa tampak seperti logo perjalanan/hewan; kilau bisa hilang pada ukuran kecil. |
| **2. Potongan kontribusi** | Tiga bentuk organik berbeda yang menyatu membentuk tanda centang atau jalur; masing-masing mewakili kontribusi anggota. | Menekankan bagian setiap orang dan hasil bersama, dengan warna yang bisa digunakan secara terkendali. | Dapat terlihat seperti puzzle generik atau simbol penilaian jika tanda centang terlalu dominan. |
| **3. Tiga orang dan jalur** | Tiga figur geometris ringkas mengelilingi satu jalur atau titik tujuan; aksen kecil melambangkan bantuan AI. | Kolaborasi mahasiswa mudah dipahami pada pandangan pertama. | Figur kecil rawan menyatu di launcher dan visualnya bisa terlalu umum seperti aplikasi sosial. |

## Rekomendasi

Mulai dari **Jejak bersama**: konsepnya paling dekat dengan nama, menggabungkan ide perjalanan dan kerja bersama, serta memberi ruang untuk simbol tunggal yang berpotensi khas. Ini penilaian desain awal, belum hasil pengujian atau jaminan keunikan. Gunakan dua atau tiga bentuk langkah yang disederhanakan, outline gelap yang konsisten, isian pastel sebagai aksen, dan ruang kosong yang jelas. Hindari wajah robot, bintang penilaian, skor, medali, atau figur AI yang tampak mengawasi. Jika aksen AI membuat simbol terlalu ramai, hilangkan dari ikon kecil; peran AI tetap dapat dijelaskan lewat nama dan materi produk.

## Rencana validasi sebelum memilih desain akhir

- Buat sketsa siluet dan versi satu warna, lalu lihat berdampingan dalam ukuran launcher nyata serta pada ukuran lebih kecil; periksa apakah bentuk masih terbaca tanpa mengandalkan kilau atau teks.
- Uji foreground dalam area aman Android pada beberapa bentuk mask, latar terang/gelap, dan versi monokrom bertema. Logo utama dapat tanpa kotak, sedangkan background adaptif adalah lapisan platform terpisah.
- Uji kontras bagian penting pada warna yang bersebelahan, ketebalan outline, dan keterbacaan skala abu-abu. Jika digunakan sebagai tombol, sediakan label yang jelas dan periksa kontras serta fokus kontrol sesuai konteks.
- Tanyakan beberapa mahasiswa apa yang mereka lihat dan apakah simbol terasa seperti kerja sama atau penilaian; bandingkan ketiga arah sebelum memilih.
- Periksa kemiripan logo dan merek yang relevan sebelum penggunaan publik. Riset ini belum melakukan pemeriksaan tersebut.
