# PRD Development — JejakTim AI

**Versi:** 1.0  
**Tanggal:** 17 November 2026  
**Produk:** Aplikasi Android untuk kolaborasi tugas kelompok mahasiswa  
**Target demonstrasi:** INDONERIS 2026  
**Bahasa produk:** Bahasa Indonesia  
**Status:** Spesifikasi implementasi MVP; gunakan setelah audit repository dan artefak desain.

---

## 0. Instruksi awal untuk Codex

Dokumen ini adalah spesifikasi produk dan pengembangan. Sebelum membuat atau mengubah source code, lakukan langkah berikut secara berurutan:

1. Periksa struktur repository, `AGENTS.md`, konfigurasi Flutter/Dart, Firebase, Cloud Functions, aset, dan perubahan git yang sudah ada. Pertahankan pekerjaan pengguna yang tidak terkait.
2. Pastikan repository yang sedang dibuka benar-benar proyek JejakTim AI. Jangan mengasumsikan repository kosong atau mengganti stack yang sudah berjalan tanpa bukti.
3. Gunakan screenshot referensi yang dilampirkan pengguna pada percakapan ini sebagai source of truth visual. Referensi tersebut menampilkan empat mockup layar aplikasi kolaborasi tim: beranda daftar grup, percakapan grup, galeri anggota/foto, dan kalender kegiatan. Screenshot referensi disertakan bersama PRD di `jejaktim-mobile-design-reference.png`; gunakan file tersebut dan jangan mencari atau menggunakan desain FigCraft sebagai referensi visual.
4. Terapkan bahasa visual screenshot pada layar JejakTim AI yang sesuai. Adaptasikan konten olahraga menjadi konteks mahasiswa dan proyek akademik; jangan menyalin brand Team|Reach, nama tim, foto sepak bola, teks, avatar, atau tanggal contoh. Jangan menambahkan fitur baru hanya karena tampak di gambar.
5. Pertahankan scope, role, alur bisnis dan fitur dalam PRD ini. Screenshot menjadi acuan tampilan; layar yang tidak tergambar langsung menggunakan komponen dan pola visual yang sama tanpa mengubah perilaku produk. Jika sebuah detail visual tidak dapat dipastikan dari gambar, tulis sebagai gap visual dan gunakan pola terdekat secara konsisten; jangan mengarang fitur atau mengubah scope.
6. Buat rencana implementasi bertahap yang memetakan setiap milestone PRD ke file, route, koleksi Firestore dan acceptance criteria. Mulai implementasi setelah audit repository dan pemetaan layar selesai.

Jika ada perbedaan antara screenshot dan PRD, ikuti screenshot untuk **warna, tipografi, komposisi, kartu, navigasi visual dan perlakuan permukaan**. Ikuti PRD untuk fitur, data, permission dan perilaku bisnis. Catat gap visual yang tidak bisa ditentukan dari screenshot tanpa mengubah scope.

### Acuan visual dari gambar yang dikirim pengguna

Screenshot menunjukkan presentasi empat layar mobile bertema kolaborasi tim. Ini adalah **referensi gaya visual**, bukan spesifikasi fitur JejakTim AI. Adaptasi yang diminta: tampilan bersih, modern, ramah mahasiswa dengan warna biru dominan; seluruh isi dan fungsi tetap mengikuti produk JejakTim AI.

- Kanvas presentasi contoh berwarna biru langit dengan garis diagonal tipis dan lingkaran dekoratif. Elemen ini adalah latar komposisi mockup; jangan otomatis menjadikannya wallpaper semua halaman aplikasi.
- Layar aplikasi memakai permukaan putih yang lapang, sudut sangat membulat, kontrol berbentuk kapsul/lingkaran, garis batas tipis, dan kartu dengan jarak yang jelas. Beberapa layar menggunakan panel ringkasan abu kebiruan yang lembut.
- Biru terang/royal adalah warna aksi utama: tombol bulat/CTA, grup terpilih, tab aktif dan tombol tambah menonjol. Ungu, hijau dan kuning dipakai sebagai aksen pembeda pada kartu atau status, bukan sebagai warna dominan yang bersaing.
- Tipografi sans-serif modern: judul gelap tebal, subjudul dan metadata lebih ringan, ukuran konten nyaman dibaca di ponsel. Gunakan font yang tersedia dan konsisten di Android; pilihan font final harus mengikuti ketersediaan aset proyek.
- Ikon outline sederhana di dalam kontrol lingkaran/pill. Foto atau thumbnail disusun dalam grid rapat dengan sudut membulat. Untuk JejakTim, gunakan avatar, ilustrasi akademik atau thumbnail bukti yang memang tersedia; jangan memakai foto sepak bola contoh.
- Navigasi bawah memakai ikon pada kontrol bulat/pill dengan indikator halaman aktif; tombol tambah berwarna biru dapat menjadi titik aksi utama apabila cocok dengan struktur route yang sudah ditetapkan.
- Screenshot tidak memberi nilai warna numerik, spesifikasi font, grid, spacing, animasi, state interaksi maupun seluruh halaman aplikasi. Jangan mengklaim angka tersebut terukur. Buat design tokens dari warna yang disampling/ditinjau terhadap gambar bila file sumber tersedia; dokumentasikan nilai pilihan sebagai hasil implementasi, bukan sebagai nilai eksplisit dari referensi.

Isi empat mockup diterjemahkan ke konteks produk yang sudah ditetapkan: pola beranda grup menginspirasi beranda proyek dan join-code; pola header/percakapan hanya menjadi referensi visual konten dan aktivitas, **bukan mandat menambahkan fitur chat**; galeri menjadi inspirasi susunan thumbnail bukti bila bukti visual tersedia; kalender menjadi inspirasi tampilan deadline dan jadwal yang memang masuk scope. Foto kegiatan, contoh tanggal, nama klub, angka anggota dan copy pada gambar adalah data dekoratif, bukan requirement produk.

### Batas fidelity dan gap visual

- Source of truth untuk tampilan adalah screenshot pengguna; jangan membuka atau menggunakan dokumen MCP FigCraft untuk menentukan desain.
- Jangan mengubah scope MVP, menambahkan chat/media sharing, menambah role baru, atau menyalin identitas Team|Reach.
- Terapkan referensi ke layar yang sudah tercantum pada alur dan requirement PRD. Untuk bagian yang tidak tampak pada gambar (auth, form, review, AI, laporan, profil, error states), gunakan pola warna, tipografi, permukaan, tombol dan kartu yang konsisten. Detail tata letak yang tidak terverifikasi harus dicatat di `DESIGN_GAPS.md` atau catatan implementasi; jangan menyajikannya sebagai ketentuan dari screenshot.
- Pastikan layout adaptif pada lebar Android 360–412 logical px, safe area, system font scaling dan accessibility. Rentang ini adalah target engineering/QA, bukan ukuran yang terbaca dari screenshot.
- Pertahankan pekerjaan desain pengguna yang ada. Jangan menimpa, menghapus, atau memodifikasi file desain sumber saat mengimplementasikan Flutter.
---

## 1. Ringkasan produk

**JejakTim AI — “Kerja Bareng, Kontribusi Terlihat.”** membantu mahasiswa merencanakan tugas kelompok, menetapkan penanggung jawab dan tenggat, mencatat pembaruan, menyertakan bukti kerja, menjalankan peer review, melihat progres, menerima saran koordinasi dari AI, serta membuat laporan proses proyek.

Aplikasi Android berbahasa Indonesia ini mendukung **SDG 4 (Pendidikan Berkualitas)** melalui praktik kolaborasi, akuntabilitas proses, dukungan belajar sebaya, dan akses terhadap informasi kerja kelompok yang lebih jelas. JejakTim bukan sistem penilaian akademik dan tidak menggantikan dosen atau rubrik mata kuliah.

### Masalah pengguna

- Instruksi dan pembagian kerja tersebar di chat.
- Penanggung jawab, tenggat dan definisi selesai sering tidak jelas.
- Anggota sulit mengetahui kapan harus meminta atau memberi bantuan.
- Bukti dan riwayat pekerjaan tidak terhimpun saat refleksi atau laporan.
- Perbedaan kontribusi rawan ditangani dengan asumsi atau tuduhan.

### Prinsip produk

1. Setiap tugas punya deskripsi, pemilik, tenggat, status dan riwayat yang dapat dipahami.
2. Anggota dapat memperbarui tugasnya sendiri dan mengirim bukti berbentuk tautan.
3. Peer review memberi konfirmasi atau permintaan revisi yang spesifik dan sopan.
4. AI membantu memahami kondisi kerja dan menyarankan langkah kolaborasi; pengguna tetap mengambil keputusan.
5. Tampilkan data yang cukup untuk koordinasi, tanpa memberi ranking atau label moral kepada mahasiswa.
6. Keamanan akses dan privasi ditetapkan sejak backend, bukan hanya dari UI.

---

## 2. Scope MVP

### Termasuk

- Splash dan onboarding ringkas; pendaftaran email/password, login, reset kata sandi, logout.
- Profil mahasiswa dasar.
- Beranda daftar proyek, ringkasan progres, prioritas/tugas, empty state, notifikasi dalam aplikasi.
- Membuat proyek; meninjau dan mengonfirmasi detail; membuat kode undangan; bergabung dengan kode dan melihat preview sebelum bergabung.
- Detail proyek dengan ringkasan, tugas, anggota, aktivitas serta pengaturan proyek.
- Membuat/mengubah tugas, menetapkan satu atau lebih penanggung jawab sesuai aturan proyek, tenggat, status dan peer reviewer bila diperlukan oleh perilaku produk.
- Pembaruan progres dan catatan kendala.
- Mengirim bukti kerja melalui URL (misalnya tautan Drive/GitHub/Figma) dan catatan. MVP tidak mengunggah binary kecuali konfigurasi Storage telah disiapkan dengan aturan akses yang layak.
- Review oleh rekan: konfirmasi selesai atau minta revisi disertai alasan; riwayat review tersimpan.
- Dashboard proyek/tugas, AI Team Insight dalam bentuk rekomendasi terstruktur, laporan kontribusi/progres yang dapat dipreview dan dibagikan/diunduh.
- State loading, empty, validation, error, upload/link failure, insufficient data, offline, access denied dan retry.
- Firebase Auth + Firestore. Firebase Storage opsional untuk upload berkas setelah izin, biaya, retensi dan security rules ditentukan.
- TypeScript Cloud Functions untuk operasi yang memerlukan otoritas server (join project, kode undangan, agregasi/AI/report jika sesuai arsitektur aplikasi).

### Tidak termasuk pada MVP

Chat pribadi/grup, video meeting, integrasi WhatsApp, LMS, integrasi nilai akademik, pemberian nilai atau bobot kontribusi, leaderboard/ranking, deteksi “free rider”, skor kemalasan/produktivitas/kepribadian, AI yang menetapkan keputusan atau mengubah tugas tanpa konfirmasi, pembayaran, portal dosen, dan sinkronisasi background kompleks.

---

## 3. Referensi desain dan penerapannya ke JejakTim AI

### Arah desain

Gunakan screenshot yang dilampirkan pengguna sebagai acuan visual. Produk tetap aplikasi kolaborasi tugas kelompok mahasiswa berbahasa Indonesia, dengan nama/identitas JejakTim AI dan fungsi yang sudah ditetapkan dalam PRD. Adaptasikan pola visualnya; jangan menyalin konten atau menambah scope fitur dari contoh Team|Reach.

### Pemetaan pola visual ke screen yang sudah ada

| Pola dalam screenshot | Penerapan pada JejakTim AI | Batas scope/perilaku |
|---|---|---|
| Beranda dengan salam, headline, input kode grup dan tombol panah | Beranda proyek, salam personal, akses “Gabung dengan kode”, dan tombol menuju alur preview/join yang sudah ada | Join tetap melalui validasi backend dan preview; tidak ada join diam-diam |
| Kartu grup horizontal berwarna kuat dengan identitas, role dan avatar anggota | Kartu proyek aktif dengan nama, mata kuliah, progres/status dan avatar anggota bila datanya tersedia | Jangan tampilkan angka online atau statistik yang tidak dikumpulkan |
| Daftar grup lain berbentuk kartu putih | Daftar proyek lain/seluruh proyek dalam kartu ringkas | Gunakan filter/sort hanya bila sudah masuk requirement |
| Header grup dengan tombol kembali, nama, metadata anggota dan menu | Header detail proyek dengan nama, jumlah anggota yang benar, owner/member role, dan pengaturan sesuai permission | Jangan menampilkan keberadaan online jika tidak ada fitur presence |
| Percakapan dengan avatar, bubble, waktu, reaksi, grid gambar dan composer | Hanya jadikan inspirasi visual untuk timeline aktivitas/pembaruan tugas bila sesuai layar; tampilkan aktor, waktu, status dan bukti yang terkait | Fitur chat, reaction, voice note, dan pengiriman pesan tetap di luar MVP |
| Tab Photo / Calendar / Member dan grid foto | Gunakan pola tab/pill untuk navigasi ringkasan, tugas, anggota, aktivitas sesuai route produk; thumbnail bukti hanya jika evidence tersedia | Jangan menciptakan social photo gallery atau upload foto umum |
| Kalender bulanan dan kartu agenda berwarna | Tampilkan tenggat dan agenda tugas dengan kartu status yang mudah dibedakan; pertahankan alur tugas saat ini | Tidak menambahkan kalender eksternal atau event olahraga |
| Tombol tambah bulat biru mengambang | Titik masuk ke action sheet yang sudah ditentukan (buat proyek/gabung proyek/buat tugas sesuai konteks) | Aksi tetap memeriksa role, konteks halaman dan konfirmasi |

### Design tokens dan komponen

1. **Warna:** tetapkan peran semantic: primary blue untuk aksi utama/selected, soft sky blue untuk aksen latar, white untuk surface, pale blue-gray untuk panel, dark charcoal untuk teks, muted gray untuk metadata/border, serta green/amber/purple untuk status atau kategori. Ambil nilai hex dari sampling screenshot jika file resolusi asli tersedia. Jika tidak, pilih nilai implementasi yang punya kontras memadai dan dokumentasikan pilihan; jangan menyebutnya nilai asli dari gambar.
2. **Tipografi:** sans-serif yang jelas di Android; heading singkat dengan bobot tebal, body regular, metadata berukuran lebih kecil namun tetap terbaca. Hindari meniru ukuran pasti yang tidak diketahui.
3. **Bentuk:** surface/kartu dengan radius besar, input kapsul, tombol utama bulat/kapsul, tombol ikon melingkar, border tipis dan bayangan halus seperlunya.
4. **Layout:** konten satu kolom pada layar ponsel, margin yang lapang, kartu grup horizontal bila viewport memungkinkan, daftar kartu vertikal, tab sebagai pill, grid thumbnail dua kolom untuk area yang memang memerlukan thumbnail. Hindari overflow pada layar sempit dan saat font diperbesar.
5. **Komponen reusable:** `PrimaryActionButton`, `CircularIconButton`, `GroupOrProjectCard`, `MemberAvatarStack`, `CodeEntryField`, `SegmentedPillTabs`, `StatusCard`, `EvidenceThumbnail` (bila ada data), dan `BottomNavigation`. Nama ini usulan implementasi; sesuaikan dengan struktur repository.
6. **Gambar/ikon:** gunakan ilustrasi dan avatar yang tersedia/diizinkan. Placeholder harus jelas sebagai placeholder; jangan menggunakan logo, foto sepak bola atau nama dari contoh sebagai asset aplikasi.
7. **State:** desain active/selected, disabled, loading, error, empty, offline, revision dan success dengan bentuk/ikon/teks yang konsisten. Warna bukan satu-satunya penanda status.

### Aturan implementasi visual

- Cocokkan komposisi dan treatment terhadap screenshot pada layar yang relevan; jangan mencoba merekonstruksi mockup collage sebagai satu screen aplikasi.
- Adaptasikan konten menjadi proyek, mata kuliah, tugas, bukti, anggota, tenggat dan insight. Jangan menyalin teks bahasa Inggris, nama grup olahraga, data anggota palsu atau angka pada gambar.
- Tidak ada screen desain tambahan yang menjadi requirement hanya karena komponen terlihat dalam gambar. Fungsi yang sudah ditulis di PRD tetap menjadi scope.
- Auth, create/edit form, peer review, AI, laporan, profil dan state sistem tidak ditampilkan pada screenshot; terapkan bahasa visual yang sama dan catat keputusan layout yang belum dapat diverifikasi.
- Validasi secara visual pada perangkat/emulator dengan lebar 360, 390 dan 412 logical px, text scaling, safe area dan dark/light system setting yang relevan. Jangan memaksakan latar dekoratif biru bergaris pada semua screen.
- Bila screenshot asli tidak lagi tersedia bagi Codex pada saat implementasi, catat hal tersebut sebagai `DESIGN_GAPS.md`; gunakan deskripsi visual dan tabel pemetaan dalam PRD ini sebagai referensi yang tersisa, tanpa mengklaim bahwa detail yang tidak tertulis sudah terverifikasi.
---

## 4. Persona, role dan permission

### Persona

- **Ketua/creator proyek:** membuat kelompok, menetapkan detail dan anggota, menjaga pembagian tugas, memantau hambatan, memulai laporan.
- **Anggota mahasiswa:** menerima undangan, melihat tugas, mengerjakan dan memperbarui tugas sendiri, mengirim bukti, memberi peer review sesuai penugasan.

Tidak ada persona dosen/admin akademik pada MVP.

### Otorisasi

- **Owner/ketua proyek** adalah status keanggotaan proyek, bukan akses global. Boleh mengubah detail dan pengaturan proyek, mengelola anggota/invite, membuat atau mengedit tugas, mengarsipkan proyek dan membuat laporan.
- **Member** dapat membaca data proyek tempat ia menjadi anggota, memperbarui tugas yang ditugaskan kepadanya, menambah pembaruan/bukti, dan melakukan review jika ditetapkan sebagai reviewer.
- **Reviewer** adalah penugasan per tugas (anggota proyek), bukan role project-wide. Reviewer hanya dapat mereview submission tugas yang ditugaskan kepadanya; pengirim tidak boleh menyetujui submission miliknya sendiri.
- **Penerima laporan** adalah akses ke file hasil yang dibagikan secara sadar. Jangan memberi akses Firestore proyek kepada pihak luar hanya demi membagikan PDF.
- Semua permission ditegakkan server-side/Firestore Security Rules. Menyembunyikan tombol bukan kontrol keamanan.

---

## 5. Alur end-to-end utama

### A. Auth dan profil

Splash → onboarding pertama kali (skip/lanjut) → masuk atau daftar → validasi → Firebase Auth → buat/sinkron dokumen user → Beranda. Reset password mengirim email dan menampilkan konfirmasi generik demi mencegah enumerasi akun. Logout menghapus state lokal sensitif dan mengarahkan ke masuk.

### B. Membuat proyek

Beranda / action sheet → isi nama, deskripsi, mata kuliah/konteks opsional, tanggal target opsional → review detail → konfirmasi → backend membuat proyek dan membership owner secara atomik → halaman sukses dengan kode/link undangan → detail proyek. Cegah duplikasi submission akibat double tap dengan idempotency atau disable button selama proses.

### C. Gabung proyek

Action sheet → masukkan kode → backend memvalidasi kode, expiry, batas anggota dan status proyek → tampilkan preview minimum (nama, ringkasan, ketua, jumlah anggota; jangan bocorkan detail privat) → konfirmasi bergabung → membership dibuat atomik → detail proyek. Kode tidak valid/kedaluwarsa/penuh/ditutup mendapat pesan yang dapat ditindaklanjuti.

### D. Siklus tugas dan peer review

Daftar tugas/detail → buat atau buka tugas → pilih assignee dan reviewer bila ada → status `todo` → assignee mulai (`in_progress`) → catat pembaruan/kendala → kirim evidence URL dan catatan (`submitted`) → reviewer memilih `approved` atau `revision_requested` dengan catatan → assignee memperbaiki dan submit ulang atau tugas selesai (`done`). Setiap perubahan penting menambah event aktivitas immutable. Reopen/ubah status harus memiliki alasan dan tidak boleh menghapus riwayat.

### E. AI Team Insight

Pilih proyek → jelaskan cakupan/periode bila layar mendukung → validasi jumlah/minimum data → hitung agregat deterministik dari tugas, deadline, update dan kendala → panggil backend AI bila konfigurasi tersedia → validasi respons terstruktur → tampilkan insight dengan bukti dan rekomendasi yang dapat dibuka → pengguna memilih tindakan secara manual. AI gagal/offline berarti fitur memberi state error/retry, bukan membuat fakta palsu.

### F. Dashboard, laporan dan profil

Dashboard menampilkan ringkasan proyek aktif dan hal yang perlu perhatian. Laporan memilih proyek/periode → checklist selesai dan kelengkapan → generate snapshot report → preview → share/export melalui mekanisme Android bila tersedia. Profil dapat diperbarui sesuai field dalam scope produk; preferensi notifikasi dan bantuan privasi dapat diakses dari navigasi produk.

---

## 6. Arsitektur teknis yang diusulkan

Gunakan versi stabil yang kompatibel dan kunci versi di lockfiles; jangan menulis versi paket yang belum diverifikasi.

### Android client

- Flutter + Dart, Material widgets hanya sebagai primitive yang diberi styling sesuai referensi screenshot.
- Riverpod untuk dependency injection dan state management; pisahkan UI, domain/use case, repository dan datasource.
- `go_router` untuk route, auth redirect, deep link invite yang aman dan back-stack konsisten.
- Firebase Auth, Cloud Firestore; Firebase Storage opsional untuk file upload; Firebase Messaging hanya bila push notification masuk scope demonstrasi dan konfigurasi tersedia.
- Firebase Emulator Suite untuk pengembangan lokal/integrasi jika dapat dijalankan di repository.
- Struktur feature-first yang disesuaikan kondisi repo, contohnya `features/auth`, `projects`, `tasks`, `insights`, `reports`, `profile`; `core/design_system`, `routing`, `firebase`, `errors`.
- Repository interface menjaga widget tidak bergantung langsung pada Firebase SDK.

### Backend

- TypeScript Cloud Functions (Node runtime yang didukung proyek) untuk operasi tepercaya: membuat/rotasi kode invite, join project, mengubah membership/role, review submission yang memerlukan validasi tambahan, AI insights, report snapshot, serta cleanup terjadwal bila dikonfigurasi.
- LLM dipanggil hanya dari backend menggunakan secret manager/parameter Firebase yang sesuai. Kunci API tidak boleh ada di Flutter, repository, assets, log, atau remote config yang dapat dibaca klien.
- LLM provider/model ditentukan setelah tersedia credential dan keputusan produk. Buat interface adapter agar implementasi tidak mengikat domain ke satu provider.
- Semua fungsi memverifikasi Firebase ID token, membership, role, ownership, payload, rate limit dan batas ukuran sebelum mengakses data.

### Konfigurasi dan environment

- Pisahkan project Firebase dev/staging/demo/prod bila akun dan izin memungkinkan.
- Konfigurasi client Firebase bukan secret, tetapi harus memakai project yang benar dan App Check jika siap.
- API key LLM hanya server-side. Gunakan `.env.example` tanpa nilai rahasia, Firebase Functions config/Secret Manager dan `.gitignore` yang sesuai.
- Jangan commit service-account JSON, private keys, token, password, signed URL permanen atau data peserta asli.
- Seed demo hanya untuk environment demo dan dapat dihapus/reset tanpa menghapus data pengguna nyata.

---

## 7. Model data Firestore

Gunakan ID dokumen acak dan server timestamps. Semua waktu tersimpan sebagai UTC `Timestamp`, UI menampilkan zona waktu perangkat. Data contoh bertipe konseptual; sesuaikan serialization dengan repository.

### `users/{uid}`

```text
uid: string
name: string
email: string                 // sinkron dari Auth; jangan pakai untuk pencarian publik
photoUrl: string | null
institution: string | null
major: string | null
createdAt: Timestamp
updatedAt: Timestamp
deletedAt: Timestamp | null
notificationPrefs: { inApp: boolean, push: boolean }
```

Simpan field minimum yang dibutuhkan. Jangan menyimpan NIM/NIK, nilai akademik atau data sensitif yang tidak dibutuhkan MVP.

### `projects/{projectId}`

```text
name: string
description: string
courseLabel: string | null
targetDate: Timestamp | null
ownerId: string
status: "active" | "completed" | "archived"
memberCount: number             // cache; hanya server yang mengubah
createdAt: Timestamp
updatedAt: Timestamp
completedAt: Timestamp | null
archivedAt: Timestamp | null
schemaVersion: number
```

### `projects/{projectId}/members/{uid}`

```text
uid: string
role: "owner" | "member"
memberStatus: "active" | "left" | "removed"
joinedAt: Timestamp
updatedAt: Timestamp
invitedBy: string | null
```

### `projects/{projectId}/invites/{inviteId}`

```text
codeHash: string               // hash server-side; plaintext code se entrega una vez
status: "active" | "revoked" | "expired" | "full"
createdBy: string
createdAt: Timestamp
expiresAt: Timestamp
maxUses: number | null
useCount: number
```

No crear endpoint de lectura pública de collection invites. Kode harus berentropi cukup, dibatasi percobaan, dapat dicabut dan idealnya memiliki masa berlaku.

### `projects/{projectId}/tasks/{taskId}`

```text
title: string
description: string
status: "todo" | "in_progress" | "submitted" | "revision_requested" | "done" | "cancelled"
assigneeIds: string[]
reviewerId: string | null
createdBy: string
priority: "low" | "normal" | "high"       // hanya bila diperlukan oleh requirement produk
startAt: Timestamp | null
dueAt: Timestamp | null
createdAt: Timestamp
updatedAt: Timestamp
completedAt: Timestamp | null
latestSubmissionId: string | null
version: number
```

### `projects/{projectId}/tasks/{taskId}/updates/{updateId}`

```text
authorId: string
kind: "progress" | "blocker" | "note"
message: string
createdAt: Timestamp
```

### `projects/{projectId}/tasks/{taskId}/submissions/{submissionId}`

```text
submittedBy: string
note: string | null
evidenceLinks: [{ label: string | null, url: string }]
attachmentPaths: string[]       // hanya jika Storage diaktifkan
status: "pending_review" | "approved" | "revision_requested" | "superseded"
submittedAt: Timestamp
reviewedAt: Timestamp | null
reviewedBy: string | null
```

Validasi URL ke skema `https`, panjang maksimum dan format; jangan meng-fetch URL pengguna dari server. Lampiran Storage harus private dan dibaca setelah authorization.

### `projects/{projectId}/tasks/{taskId}/reviews/{reviewId}`

```text
submissionId: string
reviewerId: string
decision: "approved" | "revision_requested"
comment: string
createdAt: Timestamp
```

Review adalah riwayat append-only. Validasi reviewer aktif, submission terbaru dan bukan submitter. Hindari edit/hapus review lama; koreksi dibuat sebagai event baru jika dibutuhkan.

### `projects/{projectId}/activity/{eventId}`

```text
type: string                    // allowlist: project/task/member/submission/review/report events
actorId: string
entityType: "project" | "task" | "member" | "submission" | "report"
entityId: string
summary: string                 // aman untuk timeline, tanpa secret/link signed
createdAt: Timestamp
metadata: map                   // allowlist dan tanpa data sensitif
```

Client tidak boleh menulis arbitrary activity yang mengatasnamakan pengguna lain. Event penting ditulis server atau divalidasi ketat.

### `projects/{projectId}/insights/{insightId}`

```text
requestedBy: string
periodStart: Timestamp
periodEnd: Timestamp
inputVersion: string            // hash/version dari agregat yang dianalisis
status: "ready" | "failed" | "stale"
summary: string
teamSignals: [{ type: string, observation: string, evidenceTaskIds: string[] }]
recommendations: [{ title: string, rationale: string, actionType: string, targetTaskIds: string[] }]
limitations: string[]
modelVersion: string | null
createdAt: Timestamp
expiresAt: Timestamp
```

Jangan simpan prompt mentah berisi data personal kecuali dibutuhkan, memiliki dasar yang jelas dan masa retensi. Jangan menyimpan private chain-of-thought.

### `projects/{projectId}/reports/{reportId}`

```text
generatedBy: string
periodStart: Timestamp
periodEnd: Timestamp
status: "ready" | "failed" | "expired"
contentSnapshot: map             // data laporan yang telah disanitasi
filePath: string | null          // private Storage path jika dipakai
createdAt: Timestamp
expiresAt: Timestamp
```

Dokumen `contentSnapshot` harus mencatat waktu generate dan scope; laporan tidak menjadi nilai akademik. Pastikan data anggota yang ditampilkan mengikuti kebutuhan, dan pengguna diberi preview sebelum dibagikan.

### Indeks dan batas data

Buat composite index hanya setelah query nyata diketahui. Paginate task/activity/member lists. Batasi panjang teks, jumlah assignee/reviewer/link, ukuran upload dan jumlah hasil. Hindari query collection lintas proyek yang dapat membocorkan data.

---

## 8. Security Rules dan validasi backend

Rules Firestore harus **deny by default**. Implementasikan rules lalu uji dengan Emulator atau mekanisme setara sebelum integrasi dianggap selesai.

- User membaca/menulis profil sendiri dengan field allowlist. Field `uid`, role global, tanggal pembuatan dan status penghapusan tidak dapat diubah bebas dari client.
- Proyek dapat dibaca hanya oleh active member. Pembuatan membership owner awal dilakukan secara konsisten melalui backend/atomic transaction.
- Client tidak dapat menambahkan dirinya ke membership. Join hanya melalui callable/HTTPS function yang memvalidasi invite di server.
- Perubahan owner, role, invite, memberCount dan status archive/completion sensitif hanya melalui owner dan backend yang tervalidasi.
- Anggota dapat membuat/mengedit tugas hanya jika role/aturan proyek membolehkan; assignment tidak boleh mengandung UID nonmember. Member hanya mengubah status/update/submission tugas yang ditugaskan kepadanya sesuai transisi legal.
- Review hanya oleh reviewer yang ditunjuk dan masih menjadi anggota aktif. Reviewer tidak boleh mereview submission sendiri. Status terminal hanya lewat transisi yang sah.
- Activity, insights dan reports tidak dapat dimanipulasi client untuk mengubah data sumber. Batasi create/read/update sesuai role dan status.
- Rules tidak bisa memvalidasi semua aturan lintas dokumen/kompleks; gunakan Cloud Functions untuk transaksi dan validasi otoritatif. Jangan mengandalkan `client-side validation`.
- Storage (bila aktif): private path `projects/{projectId}/tasks/{taskId}/{uid}/{fileId}`; rules memverifikasi auth, keanggotaan, assignee/reviewer sesuai kebutuhan, MIME allowlist, ukuran, dan path. Signed URL berumur pendek; jangan public-read.
- Aktifkan App Check bila tersedia, gunakan rate limiting untuk kode invite/AI, batas request, dan log tanpa token atau konten sensitif.
- Tangani penghapusan akun/proyek dan data terkait melalui backend terotorisasi, audit konsekuensi serta retensi sebelum penghapusan permanen.

### Transisi status yang diizinkan

```text
todo -> in_progress -> submitted -> done
                            |          ^
                            v          |
                    revision_requested -> submitted

cancelled hanya oleh aksi berizin; status terminal memerlukan konfirmasi.
```

Simpan riwayat submission/review; jangan mengeditnya menjadi seolah-olah tidak pernah terjadi.

---

## 9. API / Cloud Functions

Pilih callable atau HTTPS JSON endpoint sesuai kebutuhan; dokumentasikan kontrak input/output dan error code. Contoh konseptual berikut bukan nama wajib jika konvensi repository sudah ada.

| Endpoint | Akses | Tanggung jawab |
|---|---|---|
| `createProject` | Auth | Validasi input, buat project + owner membership dalam transaction, idempotent |
| `createInvite` / `rotateInvite` | Owner | Membuat kode ber-hash, batas pakai dan expiry |
| `previewInvite` | Auth | Validasi kode dan kembalikan metadata minimum |
| `joinProject` | Auth | Validasi invite, kapasitas dan status; membership transactionally |
| `submitTask` | Assignee | Validasi status, evidence links/attachments, buat submission dan event |
| `reviewSubmission` | Reviewer yang ditetapkan | Validasi submission terbaru, decision dan comment; tulis review/event dan status |
| `generateTeamInsight` | Member aktif | Bentuk agregat minimal, cek kelayakan/rate limit, panggil AI, validasi schema dan simpan result |
| `generateProjectReport` | Member aktif; owner jika menutup proyek | Bentuk snapshot periode, simpan status, hasil private/export |
| `deleteAccount` | Pemilik akun | Validasi ulang identitas, de-identify/delete sesuai lifecycle dan retensi |

Standarkan kegagalan misalnya `UNAUTHENTICATED`, `PERMISSION_DENIED`, `NOT_FOUND`, `INVALID_ARGUMENT`, `FAILED_PRECONDITION`, `RESOURCE_EXHAUSTED`, `DEADLINE_EXCEEDED`, `UNAVAILABLE`, `INTERNAL`. UI menerjemahkan kode ke pesan Indonesia tanpa membeberkan stack trace.

Semua mutasi yang dapat diulang harus aman terhadap retry. Operasi penting memakai transaction, idempotency key/request ID atau deduplikasi yang sesuai.

---

## 10. Structured AI Team Insight

AI adalah asisten koordinasi kelompok. Data input berasal dari agregat minimal server-side: status dan tenggat tugas, waktu pembaruan terakhir, jumlah task per status, kendala yang sengaja dicatat, dan review yang relevan. Jangan kirim email, profil pribadi, chat, dokumen bukti privat atau data yang tidak diperlukan ke LLM.

### Bentuk respons tervalidasi

```json
{
  "summary": "string",
  "teamSignals": [
    {
      "type": "deadline_risk | blocked_task | review_waiting | workload_visibility | positive_progress",
      "observation": "string",
      "evidenceTaskIds": ["taskId"]
    }
  ],
  "recommendations": [
    {
      "title": "string",
      "rationale": "string",
      "actionType": "open_task | discuss_with_team | update_deadline | request_help | review_submission",
      "targetTaskIds": ["taskId"]
    }
  ],
  "limitations": ["string"]
}
```

Validasi server memakai JSON Schema/Zod sejenis: enum allowlist, panjang teks, jumlah item, task ID harus milik proyek yang sama, dan tidak boleh menerima field ekstra berbahaya. Escape/render sebagai teks biasa untuk mencegah injection/XSS. Kalau output tidak valid, tampilkan unavailable dan log metadata teknis tanpa prompt sensitif.

### Batas AI dan trust

- Dilarang menghasilkan skor kemalasan, nilai, ranking anggota, label “anggota tidak berkontribusi”, penilaian kepribadian atau klaim niat.
- Dilarang menyamakan tugas terlambat dengan kemalasan. Sampaikan observasi berbasis tugas dan data, misalnya “Tugas X melewati tenggat; tim dapat meninjau prioritas atau meminta pembaruan.”
- Jangan bandingkan anggota dengan skor. Tampilkan distribusi tugas hanya untuk koordinasi, dengan konteks dan tanpa interpretasi moral.
- Saran tidak otomatis mengubah status, assignee, deadline atau membership. User melakukan konfirmasi manual.
- Tampilkan kapan insight dibuat, rentang data, tugas yang menjadi bukti, serta keterbatasan data. Jangan menampilkan hasil saat data tidak cukup.
- Berikan pilihan retry dan jalur kerja manual bila AI tidak tersedia. Cache hasil dengan `inputVersion`; tandai stale setelah data berubah.

---

## 11. Navigasi dan route

Turunkan path final dari audit `go_router` yang sudah ada; pola konseptual:

```text
/splash
/onboarding/:step
/auth/login
/auth/register
/auth/forgot-password
/home
/notifications
/projects/new
/projects/join
/projects/invite/:code/preview
/projects/:projectId
/projects/:projectId/tasks
/projects/:projectId/members
/projects/:projectId/activity
/projects/:projectId/settings
/tasks
/tasks/:taskId
/tasks/:taskId/edit
/tasks/:taskId/update
/tasks/:taskId/evidence
/tasks/:taskId/review
/insights
/insights/:projectId
/reports/:projectId
/reports/:projectId/preview
/profile
/profile/edit
/profile/notifications
/profile/privacy
/search
```

Pemetaan route harus sesuai kebutuhan screen produk; hindari membuat route screen baru untuk modal/action sheet jika pemetaan route menetapkan modal. Auth guard harus mempertahankan deep link yang aman setelah login. Logout, akun nonaktif, akses dicabut dan invite kedaluwarsa harus membawa pengguna ke state yang tepat.

Bottom navigation Beranda, Tugas, aksi Tambah, AI Insight dan Profil mengikuti navigasi produk yang sudah ditetapkan. Pastikan item tengah sesuai aksi kontekstual dan state selected mengikuti halaman aktif. Detail proyek menggunakan subnavigasi/tab sesuai pola visual screenshot dan perilaku yang ditetapkan PRD.

---

## 12. Data states, offline, aksesibilitas dan privasi

### Loading / empty / errors

Implementasikan state aplikasi yang diperlukan: skeleton home, offline home, akses proyek ditolak, daftar tugas tanpa hasil, bukti gagal, review kosong, AI unavailable/insufficient data, report generating/failed, auth validation dan action success. Pertahankan isi yang sudah ada saat refresh bila aman; sediakan retry yang tidak menggandakan mutasi.

Pesan error harus memberi alasan yang bisa dipahami dan tindakan berikutnya. Contoh:

- Kode tidak cocok: periksa kembali atau minta kode baru ke ketua.
- Upload tautan gagal: periksa URL dan koneksi, lalu coba lagi.
- Perlu review: hubungi reviewer yang ditugaskan bila tenggat dekat.
- Offline: tampilkan data cache hanya sebagai data terakhir tersinkron, dengan penanda waktu; nonaktifkan aksi yang butuh server.
- Konflik versi: muat perubahan terbaru dan minta pengguna mengulang edit yang terdampak.

Jangan menampilkan data cache proyek setelah membership dicabut tanpa menandai akses tidak lagi tersedia. Offline write queue hanya untuk aksi yang aman dan harus mencegah state yang tampak sukses sebelum server menerima mutasi.

### Aksesibilitas

- Target sentuh minimal 44 × 44 logical px, semantik label untuk screen reader, fokus dan urutan navigasi masuk akal.
- Status tidak hanya dibedakan oleh warna; sertakan label/ikon dan teks.
- Dukung text scaling, kontras, keyboard/switch navigation yang relevan dan layout tanpa overflow.
- Hormati reduced motion dan system safe area.
- Validasi form ditautkan dengan field terkait, diumumkan pembaca layar, serta disertai arahan koreksi.
- Pastikan PDF/export (jika ada) memakai teks terbaca dan struktur sederhana.

### Privacy dan data lifecycle

- Kumpulkan hanya data yang diperlukan untuk fitur; jangan akses kontak, lokasi atau media tanpa kebutuhan dan izin runtime yang jelas.
- Evidence URL dapat berisi dokumen privat. Tampilkan peringatan agar pengguna memberi akses hanya kepada kelompok; jangan scrape konten tautan.
- Semua file privat; retensi, expiry dan penghapusan attachment/report dijelaskan dalam bantuan privasi.
- Sediakan ekspor atau hapus akun sesuai kemampuan backend; sebelum hapus proyek/akun, jelaskan akibat ke tim dan laporan.
- Log operasional minimalkan PII; jangan log password, token, signed URL, prompt mentah, evidence atau teks kendala.
- Tampilkan disclosure sederhana sebelum AI analysis mengenai jenis data agregat yang dikirim ke penyedia AI dan tujuan pemrosesan.
- Tetapkan retensi insight dan laporan demo (misalnya expiry yang dapat dikonfigurasi) sebelum rilis; jangan menganggap kebijakan final tanpa persetujuan produk.

---

## 13. Testing dan quality gates

Jangan menganggap build berhasil sebagai bukti fitur berjalan. Uji lapisan berikut sesuai milestone; jangan memasukkan credential asli ke test fixture.

### Unit

- Model serialization, status transitions, validators, permission policy, aggregation insight, report formatting, error mapping dan route guard.
- Uji AI response schema: valid, malformed, extra fields, unknown task IDs, overlong text, empty/insufficient data.

### Widget dan UX

- Auth forms, validation/loading/error, home empty/active/offline, project create/join, task state changes, evidence, peer review, insight, report preview dan profile.
- Golden/screenshot compare atau review manual terhadap referensi screenshot pada 360/390/412 lebar; perubahan platform/font harus dicatat.
- Semantics, tap target, text scaling, keyboard, safe area dan reduced motion.

### Integrasi/backend/security

- Firebase Emulator: sign-up/profile, project transaction, invite/join invalid/expired/full, membership isolation, task assignment, submission, review ownership, activity append-only, report permission, account deletion.
- Security rules: user nonmember tidak dapat membaca; member tidak bisa mengubah role/invite; hanya assignee mengirim bukti; hanya reviewer mereview; user lintas proyek tidak dapat membaca Storage.
- Fungsi backend: auth required, payload invalid, idempotent retry, rate limit, AI timeout/schema failure, transaksi bersamaan.
- Uji offline/reconnect dan permission revoked.

### Release verification

- Jalankan formatter, analyzer/linter dan test yang relevan pada environment repo; jangan menyatakan lulus bila tidak dijalankan.
- Android build debug/release sesuai konfigurasi, instal di emulator/perangkat dan jalankan demo alur utama.
- Periksa tidak ada secret dalam git diff, APK resource, log, konfigurasi client atau artefak publik.

---

## 14. Demo INDONERIS

Siapkan alur demo konsisten sekitar 3–5 menit dengan data sintetis:

1. Login akun demo yang instruksinya disimpan terpisah secara aman, atau gunakan alur daftar jika koneksi dan verifikasi siap.
2. Buat proyek atau join lewat kode demo.
3. Buat tugas, tugaskan anggota, perbarui status dan tambahkan evidence URL dummy yang aman.
4. Kirim review, minta revisi, submit ulang, lalu setujui.
5. Buka dashboard dan AI Team Insight; tunjukkan sumber observasi, keterbatasan dan saran yang dapat ditindaklanjuti, tanpa skor individu.
6. Preview laporan dan gunakan share/export yang benar-benar berfungsi pada perangkat.

Sediakan project demo yang bisa direset dan fallback bila jaringan/LLM gagal. Jika LLM belum siap, tampilkan state unavailable yang ditetapkan untuk aplikasi; jangan membuat hasil AI statis seolah-olah hasil real tanpa label “contoh”. Jangan sertakan identitas mahasiswa asli atau API secret dalam APK/dokumen demo.

---

## 15. Build APK dan distribusi internal

- Konfirmasi package/application ID, signing config dan environment Firebase sebelum release.
- Build debug APK untuk QA dan APK/AAB release sesuai kebutuhan lomba/distribusi. Jangan memasukkan signing key ke repository; signing release hanya setelah key disediakan dengan jalur aman.
- Catat commit, Flutter version, flavor, tanggal build, checksum dan environment konfigurasi pada release notes.
- Instal dan verifikasi di perangkat Android: login, create/join, tugas, bukti, review, insight state, report, back navigation, deep link dan offline/error state.
- Simpan APK yang dapat diunduh pada lokasi output yang ditentukan pengguna/repository. Jangan menyebut aplikasi production-ready hanya karena file APK tersedia.

---

## 16. Milestone bertahap dan acceptance criteria

### M0 — Audit dan fondasi

- Repository, git changes, Flutter/Firebase setup dan referensi visual screenshot diaudit.
- Pemetaan screenshot ke layar aplikasi, design tokens implementasi dan gap visual ditulis.
- App build awal jalan di Android tanpa menghapus perubahan yang sudah ada.

**Lulus jika:** ada mapping pola screenshot → screen/route, catatan desain yang tidak dapat diverifikasi, rencana data/security, dan perintah build awal berhasil atau hambatannya tercatat konkret.

### M1 — Design system, routing, auth dan profil

- Tokens/components mengikuti screenshot pengguna dan tetap konsisten di seluruh layar.
- Splash/onboarding/login/register/forgot password/edit profile berfungsi.
- Firebase Auth dan user profile sinkron; auth guard dan logout benar.

**Lulus jika:** validasi dan error memiliki state; profil hanya bisa diubah pemilik; seluruh route auth yang termasuk MVP dapat dicapai.

### M2 — Project lifecycle

- Home active/empty, action sheet, create/review/success, join/code preview, project summary, tabs, members, activity, project management.
- Invite dan join backend transaction; rules mencegah akses nonmember.

**Lulus jika:** dua akun demo dapat membuat proyek, bergabung dengan kode, melihat data yang sama dan tidak dapat membaca proyek lain.

### M3 — Task, evidence dan peer review

- Task list/create/edit/assignee/detail, updates/blocker, submit evidence link, reviewer approval/revision, history/activity.

**Lulus jika:** alur todo → in progress → submission → revision → resubmission → done tersimpan dan tervalidasi server, tidak ada self-review, riwayat tidak terhapus.

### M4 — Dashboard, AI Team Insight, notifikasi

- Dashboard agregat dan state notifikasi mengikuti kebutuhan produk.
- Backend insight dengan structured output tervalidasi, evidence references, sufficient-data, unavailable dan retry.

**Lulus jika:** AI tidak mengeluarkan skor/label moral, tindakan rekomendasi tidak berjalan otomatis, model gagal tidak merusak fitur task.

### M5 — Report dan release demo

- Checklist selesai, laporan snapshot, preview, export/share, profile/privacy/help final.
- E2E security, QA visual, APK install dan rehearsal demo.

**Lulus jika:** hasil laporan cocok data, output dapat dibuka/dibagikan di Android, alur demo dapat dipulihkan dan tidak terdapat credential di artefak.

Urutan dapat disesuaikan dengan repository, namun perubahan milestone harus menjelaskan dependency dan acceptance criteria yang tetap terjaga.

---

## 17. Acceptance criteria MVP keseluruhan

- Mahasiswa dapat register/login/reset password/logout dan profil tetap konsisten setelah login ulang.
- Ketua dapat membuat proyek dan mengundang anggota dengan kode aman; anggota dapat preview dan join.
- User yang bukan anggota tidak dapat membaca proyek, tugas, activity, insight, report atau Storage project tersebut.
- Anggota dapat membuat/melihat tugas sesuai permission, memperbarui progres, mencatat kendala dan melampirkan tautan bukti.
- Reviewer yang ditugaskan dapat menyetujui atau meminta revisi dengan komentar; perubahan tercatat dan assignee dapat submit ulang.
- Beranda dan dashboard menampilkan data Firestore aktual, bukan angka hardcoded; empty/loading/offline/error tampil sesuai kondisi.
- AI insight menggunakan data minimal yang relevan, schema valid, menunjuk tugas sumber, menjelaskan keterbatasan dan tidak menilai individu.
- Laporan memberi preview sebelum share/export dan menunjukkan periode serta waktu generate.
- Semua screen yang dirujuk dan digunakan konsisten dengan referensi screenshot pengguna; gap visual yang tidak dapat dipastikan tercatat tanpa mengubah scope diam-diam.
- Navigasi, accessibility dasar, error handling, security rules dan build Android diverifikasi pada perangkat/emulator.
- APK demo tersedia dan alur kritis dapat dipresentasikan menggunakan data sintetis.

---

## 18. Definition of Done

Satu fitur dianggap selesai bila:

1. Kebutuhan dan referensi screenshot terkait telah diidentifikasi.
2. UI, route dan state aktif/error/empty/loading telah diimplementasikan dan menggunakan design tokens.
3. Validasi domain dan permission dilakukan pada client serta server sesuai risiko.
4. Firestore/Storage rules dan index/query telah diperbarui bila diperlukan.
5. Unit/widget/integration/security test yang relevan ditambahkan dan dijalankan; hasil dilaporkan jujur.
6. Loading, retry, offline, akses ditolak, double submit dan konflik data dipertimbangkan.
7. Tidak ada secret, data asli demo atau log sensitif.
8. Acceptance criteria fitur terpenuhi dan perubahan dijelaskan dalam ringkasan PR/commit.

MVP selesai ketika seluruh acceptance criteria bagian 17 lulus dan APK demo terverifikasi pada Android.

---

## 19. Perintah dan langkah awal implementasi

Codex harus menyesuaikan perintah dengan repository setelah audit. Mulai dengan pemeriksaan non-destruktif:

```bash
pwd
git status --short
rg --files -g 'AGENTS.md' -g 'pubspec.yaml' -g 'firebase.json' -g 'firestore.rules' -g 'storage.rules' -g 'functions/package.json' -g 'README*'
```

Bila repository Flutter sudah ada:

```bash
flutter --version
flutter pub get
flutter analyze
flutter test
```

Jalankan perintah yang memang sesuai proyek dan laporkan hasil; jangan menimpa file konfigurasi Firebase atau membuat project Firebase baru sebelum memahami setup yang ada. Jika repository belum memiliki kerangka Flutter, buat proposal struktur dan bootstrap minimal setelah memastikan direktori serta perubahan yang ada aman dipertahankan. Jangan membangun semua milestone sekaligus; selesaikan dan verifikasi milestone berurutan.

---

## 20. Keputusan terbuka yang harus dicatat, bukan ditebak

- Nama/package ID Android dan project Firebase dev/demo yang akan dipakai.
- LLM provider/model, batas biaya, wilayah pemrosesan, retensi data dan persetujuan penggunaan AI.
- Apakah MVP menerima file upload nyata atau hanya evidence links; bila upload, batas ukuran/MIME/retensi.
- Metode report export (PDF lokal/server) dan kebijakan berbagi.
- Apakah push notification termasuk demonstrasi; jika tidak, gunakan in-app notification.
- Batas anggota, masa berlaku kode invite, aturan leave/remove dan penghapusan/arsip proyek.
- Field profil opsional dan data yang boleh tampil di laporan.
- Kebijakan privasi final dan mekanisme account deletion.
- Setiap detail visual atau interaksi yang tidak tampak pada screenshot referensi.

Untuk setiap keputusan, dokumentasikan asumsi sementara dengan owner dan dampaknya. Jangan menaruh kunci/credential contoh pada dokumen ini.
