# JejakTim AI — rencana implementasi

## Audit 17 November 2026
Folder benar: PRD JejakTim, screenshot referensi, lima ilustrasi PNG. Tidak ada repository Git khusus folder ini, AGENTS.md fisik, source Flutter, Firebase, atau backend sebelumnya. Folder mewarisi repository di home pengguna; tidak melakukan staging/commit di repository induk tersebut. Artefak desain dipertahankan. Flutter lokal 3.29.3 / Dart 3.7.2 tersedia; perlu eksekusi di luar sandbox untuk akses CPU. Android SDK tersedia. Firebase/project ID, LLM dan release signing belum disediakan.

## Milestone dan pemetaan
| Tahap | File / route | Koleksi | Acceptance / verifikasi |
|---|---|---|---|
| M0 | app/, DESIGN_GAPS.md, firebase.json | deny by default | bootstrap, analyze/build |
| M1 | core/design_system, routing; features/auth, profile; /splash, /onboarding, /auth/*, /profile | users | splash glow, loading, onboarding sekali, validasi, auth guard, logout |
| M2 | features/projects, data/repository; /home, /projects/* | projects, members, invites, activity | create/review, preview/join atomik, isolasi member |
| M3 | features/tasks; /tasks/* | tasks, updates, submissions, reviews | status legal, bukti HTTPS, non-self review, riwayat |
| M4 | features/insights; /insights, /notifications | insights | agregat aktual, insufficient/unavailable, tanpa AI palsu |
| M5 | features/reports; /reports/* | reports | snapshot periode, preview, PDF/share, tests, APK |

Implementasi dan pemeriksaan dilakukan berurutan. Demo lokal dipisahkan eksplisit dari Firebase, memakai data sintetis, tanpa klaim sinkron antarperangkat. Firebase diaktifkan lewat konfigurasi build; tidak membuat project cloud/deploy tanpa identitas project. LLM adapter belum memanggil provider sebelum konfigurasi tersedia.

## Asumsi sementara (perlu keputusan pemilik produk sebelum rilis)
- Application ID QA: id.jejaktim.jejaktim (bukan keputusan signing/rilis).
- Bukti URL HTTPS saja, tanpa Storage, push, chat, atau tracking.
- PDF lokal memakai snapshot terotorisasi; share selalu dari preview.
- Invite 7 hari, maksimal 30 anggota, dapat dirotasi; konfigurasi demo, bukan kebijakan final.
- Retensi snapshot/insight 30 hari hanya default pengembangan; kebijakan final belum disetujui.
- Tema terang sesuai referensi; preferensi sistem reduce motion dihormati.
