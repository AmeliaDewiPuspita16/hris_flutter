import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Hijau
  static const primary = Color(0xFF0E4A34); // hijau tua
  static const primaryMid = Color(0xFF2D6A4F); // hijau sedang, untuk gradient
  static const primaryLight = Color(0xFFE1F5EE); // tint hijau muda

  // Accent — emas
  static const accent = Color(0xFFC9A24B);
  static const accentLight = Color(0xFFDFC078);
  static const accentBg = Color(0xFFFBF4E4); // tint emas

  // Aksen tambahan untuk kartu saldo & ikon layanan
  static const violet = Color(0xFF6B46C1);
  static const violetBg = Color(0xFFFAF5FF);
  static const teal = Color(0xFF2C7A7B);
  static const tealBg = Color(0xFFE6FFFA);

  static const orange = Color(0xFFF97316);
  static const orangeBg = Color(0xFFFFF1E6);

  static const bannerAccent = Color(0xFFB7E4C7);

  // Warna netral (abu/putih)
  /// Latar seluruh halaman. Beige hangat — kartu putih di atasnya lebih
  /// menonjol dibanding di atas putih keabuan.
  static const bg = Color(0xFFF1F0EA);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E4DE);

  static const text = Color(0xFF1A1D1B); // textPrimaryColor
  static const textMid = Color(0xFF5F5E5A); // textSecondaryColor
  static const textSub = Color(0xFF76756B); // antara textMid & textMuted
  static const textMuted = Color(0xFF888780); // textMutedColor

  // Status
  static const present = Color(0xFF3B6D11); // successColor
  static const presentMid = Color(0xFF5B8F2A);
  static const presentBg = Color(0xFFE1F5EE); // moduleBgTeal

  static const pending = Color(0xFF712B13); // moduleIconCoral
  static const pendingBg = Color(0xFFFAECE7); // moduleBgCoral

  static const rejected = Color(0xFFD85A30); // dangerDotColor
  static const rejectedBg = Color(0xFFFCEAE3); // tint dari rejected

  /// Status "lembur" (Log Absensi — titik & border kalender, badge
  /// "Lbr 4,5j"). Alias ke [teal]/[tealBg] yang sudah ada dan memang generik
  /// (bukan warna dengan makna status lain), jadi tidak perlu hex baru.
  /// Ganti ke warna lain di sini saja kalau nanti ingin dibedakan.
  static const overtime = teal;
  static const overtimeBg = tealBg;

  // Kategori notifikasi IT & EST Request — sengaja dipisah dari palet
  // approval/payroll/attendance/leave/announcement supaya ketiga jenis
  // approval di banner Beranda (Leave/IT/EST) tetap gampang dibedakan
  // begitu masuk daftar Notifications.
  static const itRequest = Color(0xFF2E5FA3); // biru, khusus tag "IT request"
  static const itRequestBg = Color(0xFFE7EFF9);

  static const estRequest = Color(0xFF8B5E34); // cokelat tanah, khusus tag "EST request"
  static const estRequestBg = Color(0xFFF4EBE0);

  static const hseRequest = Color(0xFFB3261E); // merah bata, khusus tag "HSE request"
  static const hseRequestBg = Color(0xFFFBEAE9);

  // Status "On Progress" — dipakai HSE Work Request yang punya 4 status
  // (On Waiting/On Progress/Done/Reject), beda dari present/pending/rejected
  // yang sudah ada karena ketiganya representasi "selesai/menunggu/ditolak",
  // sedangkan ini representasi "sedang berjalan".
  static const inProgress = Color(0xFF1D4ED8);
  static const inProgressBg = Color(0xFFE8EEFC);

  static const neutral = Color(0xFF888780); // inactiveNavColor
  static const neutralBg = Color(0xFFEDEDE7);

  /// Titik status "sedang aktif" (mis. sudah clock in) — sengaja lebih
  /// terang/saturasi dibanding [present] supaya tetap menyala di atas latar
  /// hijau tua ClockStatusCard.
  static const activeDot = Color(0xFF3DDC84);

  // Hero tetap hijau (sama dengan primary)
  static const heroGreen = Color(0xFF0E4A34);
  static const heroGreenMid = Color(0xFF2D6A4F);

  /// Gradient hijau utama — selaras dengan heroGradient
  static const primaryGradient = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [primary, primaryMid],
  );

  /// Gradient hijau hero card
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [heroGreen, heroGreenMid],
  );

  /// Gradasi latar halaman: tint hijau muda di atas memudar jadi beige.
  ///
  /// Dibuat tuntas di pertengahan layar supaya bagian bawah tetap netral —
  /// bagian atas jadi menyambung dengan panel hijau di kepala halaman
  /// alih-alih terpotong tegas.
  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryLight, bg],
    stops: [0, 0.55],
  );
}
