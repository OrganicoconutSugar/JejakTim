# JejakTim App (Flutter)

Aplikasi Flutter (Android & Web) untuk kolaborasi tugas kelompok mahasiswa dengan backend Supabase.

## Konfigurasi Supabase

1. Jalankan file SQL di folder [`../supabase/`](../supabase/) secara berurutan (`001` sampai `007`) melalui **Supabase Dashboard -> SQL Editor**.
2. Salin template konfigurasi:

```bash
cp supabase.config.example.json supabase.config.json
```

3. Isi `SUPABASE_URL`, `SUPABASE_ANON_KEY`, dan (opsional untuk AI Team Insight) `GEMINI_API_KEY` dengan kredensial milikmu.

### Mengaktifkan Gemini AI Team Insight

Ada dua cara (pilih salah satu):

- **Cara cepat (lokal & build APK):** Masukkan `"GEMINI_API_KEY": "AIza..."` di `supabase.config.json`, lalu jalankan/build dengan `--dart-define-from-file=supabase.config.json`.
- **Cara production (Supabase Edge Function):** Deploy `../supabase/functions/team-insight` lalu set secret di Supabase:

```bash
supabase secrets set GEMINI_API_KEY=AIza...
supabase functions deploy team-insight
```

Jika `GEMINI_API_KEY` belum diisi atau perangkat sedang offline, aplikasi otomatis menampilkan **Smart Rhythm Analyzer** lokal berbasis data tugas tanpa menampilkan error.

## Menjalankan Aplikasi

Pastikan Flutter SDK terpasang (`^3.7.2`):

```bash
flutter pub get
```

### Flutter Web

```bash
flutter run -d chrome --dart-define-from-file=supabase.config.json
```

Atau menggunakan web server lokal:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 --dart-define-from-file=supabase.config.json
```

### Android

```bash
flutter run --dart-define-from-file=supabase.config.json
```

## Pengujian & Analisis Statis

```bash
flutter analyze
flutter test
```
