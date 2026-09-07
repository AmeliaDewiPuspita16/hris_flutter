# HRIS Mobile — Flutter (konversi dari React/Tailwind Figma Make)

Konversi tahap 1: alur **Login → OTP → Aktivasi Biometrik → Beranda**.

## Struktur folder (clean architecture, per-feature)

```
lib/
├── main.dart                          # entry point + theme
├── core/
│   ├── theme/
│   │   ├── app_colors.dart            # padanan `const C` di App.tsx
│   │   └── app_text_styles.dart
│   └── widgets/                       # padanan komponen shared React (Card, Button, Input, dst)
│       ├── app_card.dart
│       ├── app_button.dart
│       ├── app_text_field.dart
│       └── back_header.dart
└── features/
    ├── auth/
    │   └── presentation/screens/
    │       ├── login_screen.dart
    │       ├── otp_screen.dart
    │       └── biometric_setup_screen.dart
    ├── home/
    │   └── presentation/screens/
    │       └── beranda_screen.dart
    └── shared/
        └── domain/
            └── role.dart               # padanan `type Role`
```

Prinsip pembagian: setiap fitur (`auth`, `home`, dst) punya folder sendiri berisi
`presentation/` (UI). Nanti kalau ditambah state management (Riverpod/Bloc) atau
API call, tinggal tambah folder `domain/` (model + interface) dan `data/`
(repository + API client) di masing-masing fitur — jadi tidak numpuk di 1 file
seperti App.tsx aslinya (1600+ baris).

## Cara menjalankan

Project ini baru berisi `lib/` + `pubspec.yaml` (belum ada folder platform
`android/`, `ios/`, `web/`, dst — itu bisa dibuat otomatis oleh Flutter CLI).

```bash
cd hris_flutter
flutter create .        # generate folder android/ios/web tanpa menimpa lib/ & pubspec.yaml
flutter pub get
flutter run
```

Login demo: isi email & password apa saja (asal ada "@") → lanjut ke OTP.
Kode OTP demo: **123456**.

## Yang sudah dikonversi

- Login (email/password, validasi sederhana, tombol Google SSO — belum fungsional)
- OTP (6 kotak input, auto-focus pindah, countdown resend, verifikasi kode `123456`)
- Aktivasi Biometrik (animasi tap-to-scan sederhana)
- Beranda / dashboard (header gradient, hero card status pengajuan, saldo cuti,
  grid layanan, banner khusus role `hod`/`admin`, aktivitas terbaru, bottom nav)

## Yang BELUM dikonversi (menyusul di tahap berikutnya)

Pengajuan (3 tab), Absensi, Profil, Persetujuan (HOD), Kelola Tim (Admin),
Payslip, Jadwal, Notifications.

## Catatan desain

- Warna & style disalin 1:1 dari `const C` dan style inline di `App.tsx` asli.
- Font "Inter" dirujuk di `pubspec.yaml`/tema tapi **belum di-bundle** sebagai
  asset — saat ini akan fallback ke font sistem. Kalau mau font Inter persis,
  tambahkan file `.ttf` ke `assets/fonts/` dan daftarkan di `pubspec.yaml`.
- Emoji dipakai sebagai pengganti sementara untuk ikon custom SVG React
  (📋💰📅🗓️👤✅👥) — bisa diganti ikon vektor (Material/Lucide) kalau perlu
  konsistensi lintas platform.
