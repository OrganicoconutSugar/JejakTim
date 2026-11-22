# Acuan visual dan gap

Satu-satunya acuan komposisi: outputs/jejaktim-mobile-design-reference.png. File FigCraft tidak dibuka atau diubah.

Pilihan implementasi (bukan angka terukur dari screenshot): primary #0866FF, ink #24262B, muted #677080, panel #EEF1F8, sky #CEE8FF, lavender #EEE6FF, lime #EEF8CE, amber #FFF3D5. Surface putih, radius 24–32, kontrol pill/bulat, ikon outline Lucide 22–24, target sentuh minimal 48. Font sans-serif dibundel agar offline konsisten.

- Home: salam, headline, kode undangan, kartu proyek horizontal biru/ungu, daftar prioritas, bottom pill navigation.
- Detail: panel abu kebiruan, badge proyek, metadata, tab pill, deadline pastel.
- Aktivitas: timeline pembaruan, tidak ada chat/reaction/voice notes.
- Bukti: kartu tautan; tidak membuat galeri foto tanpa bukti visual nyata.
- Auth, logo, splash, onboarding, insight, report, form, profil tidak tergambar: dirancang dengan bahasa visual sama. Ilustrasi akademik memakai aset PNG yang telah tersedia; avatar anggota berupa inisial, bukan identitas foto palsu.
- Logo Titik Bertemu: tiga jalur organik berwarna biru, mint, dan coral bertemu di titik kuning, digambar ulang sebagai vektor dari konsep F pilihan pengguna. Splash mempertahankan animasi glow dan progress bootstrap; onboarding memiliki 3 langkah dengan ilustrasi tim/tugas/AI. Ikon launcher memakai lapisan adaptif Android dan versi monokrom pada Android 13+.
- Motion: 160ms feedback, 280ms cards, 420ms page; easeOutCubic; reduced motion menonaktifkan ambient dan mempersingkat transisi. Tidak ada loading persentase palsu.
