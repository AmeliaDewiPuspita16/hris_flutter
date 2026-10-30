import 'package:flutter/material.dart';

/// Satu set warna lengkap untuk satu mode tampilan (terang / gelap).
///
/// Dipisah dari [AppColors] supaya `ThemeData` terang dan gelap bisa dibuat
/// sekaligus tanpa bergantung pada mode yang sedang aktif.
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.primaryText,
    required this.primaryMid,
    required this.primaryLight,
    required this.accent,
    required this.accentLight,
    required this.accentBg,
    required this.violet,
    required this.violetBg,
    required this.teal,
    required this.tealBg,
    required this.orange,
    required this.orangeBg,
    required this.pink,
    required this.pinkBg,
    required this.bannerAccent,
    required this.bg,
    required this.card,
    required this.border,
    required this.text,
    required this.textMid,
    required this.textSub,
    required this.textMuted,
    required this.present,
    required this.presentMid,
    required this.presentBg,
    required this.pending,
    required this.pendingBg,
    required this.rejected,
    required this.rejectedBg,
    required this.itRequest,
    required this.itRequestBg,
    required this.estRequest,
    required this.estRequestBg,
    required this.hseRequest,
    required this.hseRequestBg,
    required this.inProgress,
    required this.inProgressBg,
    required this.neutral,
    required this.neutralBg,
    required this.activeDot,
    required this.heroGreen,
    required this.heroGreenMid,
  });

  final Color primary;
  final Color primaryText;
  final Color primaryMid;
  final Color primaryLight;
  final Color accent;
  final Color accentLight;
  final Color accentBg;
  final Color violet;
  final Color violetBg;
  final Color teal;
  final Color tealBg;
  final Color orange;
  final Color orangeBg;
  final Color pink;
  final Color pinkBg;
  final Color bannerAccent;
  final Color bg;
  final Color card;
  final Color border;
  final Color text;
  final Color textMid;
  final Color textSub;
  final Color textMuted;
  final Color present;
  final Color presentMid;
  final Color presentBg;
  final Color pending;
  final Color pendingBg;
  final Color rejected;
  final Color rejectedBg;
  final Color itRequest;
  final Color itRequestBg;
  final Color estRequest;
  final Color estRequestBg;
  final Color hseRequest;
  final Color hseRequestBg;
  final Color inProgress;
  final Color inProgressBg;
  final Color neutral;
  final Color neutralBg;
  final Color activeDot;
  final Color heroGreen;
  final Color heroGreenMid;

  static const light = AppPalette(
    primary: Color(0xFF0E4A34),
    primaryText: Color(0xFF0E4A34),
    primaryMid: Color(0xFF2D6A4F),
    primaryLight: Color(0xFFE1F5EE),
    accent: Color(0xFFC9A24B),
    accentLight: Color(0xFFDFC078),
    accentBg: Color(0xFFFBF4E4),
    violet: Color(0xFF6B46C1),
    violetBg: Color(0xFFFAF5FF),
    teal: Color(0xFF2C7A7B),
    tealBg: Color(0xFFE6FFFA),
    orange: Color(0xFFF97316),
    orangeBg: Color(0xFFFFF1E6),
    pink: Color(0xFFD6457F),
    pinkBg: Color(0xFFFDEBF3),
    bannerAccent: Color(0xFFB7E4C7),
    bg: Color(0xFFF1F0EA),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE5E4DE),
    text: Color(0xFF1A1D1B),
    textMid: Color(0xFF5F5E5A),
    textSub: Color(0xFF76756B),
    textMuted: Color(0xFF888780),
    present: Color(0xFF3B6D11),
    presentMid: Color(0xFF5B8F2A),
    presentBg: Color(0xFFE1F5EE),
    pending: Color(0xFF712B13),
    pendingBg: Color(0xFFFAECE7),
    rejected: Color(0xFFD85A30),
    rejectedBg: Color(0xFFFCEAE3),
    itRequest: Color(0xFF2E5FA3),
    itRequestBg: Color(0xFFE7EFF9),
    estRequest: Color(0xFF8B5E34),
    estRequestBg: Color(0xFFF4EBE0),
    hseRequest: Color(0xFFB3261E),
    hseRequestBg: Color(0xFFFBEAE9),
    inProgress: Color(0xFF1D4ED8),
    inProgressBg: Color(0xFFE8EEFC),
    neutral: Color(0xFF888780),
    neutralBg: Color(0xFFEDEDE7),
    activeDot: Color(0xFF3DDC84),
    heroGreen: Color(0xFF0E4A34),
    heroGreenMid: Color(0xFF2D6A4F),
  );

  /// Palet gelap. Latar hijau-hitam (bukan abu netral) supaya tetap senada
  /// dengan identitas hijau portal; aksen diterangkan supaya terbaca di atas
  /// permukaan gelap.
  ///
  /// [primary] = hijau tua untuk latar; [primaryText] = hijau terang untuk
  /// teks/ikon. Keduanya sama di mode terang.
  static const dark = AppPalette(
    primary: Color(0xFF0F4A37),
    primaryText: Color(0xFF4CC38A),
    primaryMid: Color(0xFF14573F),
    primaryLight: Color(0xFF1D3A2F),
    accent: Color(0xFFE0B85A),
    accentLight: Color(0xFFEBCB85),
    accentBg: Color(0xFF352F20),
    violet: Color(0xFFB9A7F0),
    violetBg: Color(0xFF2E2748),
    teal: Color(0xFF6CC4C5),
    tealBg: Color(0xFF17403A),
    orange: Color(0xFFFB9A4B),
    orangeBg: Color(0xFF3A2A22),
    pink: Color(0xFFEE7FA8),
    pinkBg: Color(0xFF3F2230),
    bannerAccent: Color(0xFF7FC9A0),
    bg: Color(0xFF0F1512),
    card: Color(0xFF18211C),
    border: Color(0xFF2A3A32),
    text: Color(0xFFE8EFE9),
    textMid: Color(0xFFBDCBC2),
    textSub: Color(0xFFAAB9B0),
    textMuted: Color(0xFF98ABA0),
    present: Color(0xFF8BD35E),
    presentMid: Color(0xFF7AC24A),
    presentBg: Color(0xFF1D3A2F),
    pending: Color(0xFFF4B59C),
    pendingBg: Color(0xFF3A2A24),
    rejected: Color(0xFFF0836A),
    rejectedBg: Color(0xFF3F2622),
    itRequest: Color(0xFF7FAEEA),
    itRequestBg: Color(0xFF1F2E47),
    estRequest: Color(0xFFD2A877),
    estRequestBg: Color(0xFF3A2F22),
    hseRequest: Color(0xFFF08A83),
    hseRequestBg: Color(0xFF3F2523),
    inProgress: Color(0xFF7FA3F5),
    inProgressBg: Color(0xFF1F2A4A),
    neutral: Color(0xFF98ABA0),
    neutralBg: Color(0xFF222F28),
    activeDot: Color(0xFF3DDC84),
    heroGreen: Color(0xFF0B3D2E),
    heroGreenMid: Color(0xFF14573F),
  );
}

/// Akses warna aplikasi. Nilainya mengikuti mode aktif ([setDark]), jadi
/// semuanya getter — BUKAN `const`. Widget yang memakainya tidak boleh `const`.
class AppColors {
  AppColors._();

  static AppPalette _p = AppPalette.light;

  static bool get isDark => identical(_p, AppPalette.dark);

  /// Dipanggil oleh ThemeCubit sebelum UI dibangun ulang.
  static void setDark(bool value) =>
      _p = value ? AppPalette.dark : AppPalette.light;

  /// Hijau untuk LATAR (header, tombol, gradient). Di mode gelap dibuat tua
  /// seperti mockup supaya header tidak menyala.
  static Color get primary => _p.primary;

  /// Hijau untuk TEKS, ikon, garis, dan tint di atas permukaan. Di mode
  /// terang sama dengan [primary]; di mode gelap diterangkan agar terbaca.
  static Color get primaryText => _p.primaryText;
  static Color get primaryMid => _p.primaryMid;
  static Color get primaryLight => _p.primaryLight;
  static Color get accent => _p.accent;
  static Color get accentLight => _p.accentLight;
  static Color get accentBg => _p.accentBg;
  static Color get violet => _p.violet;
  static Color get violetBg => _p.violetBg;
  static Color get teal => _p.teal;
  static Color get tealBg => _p.tealBg;
  static Color get orange => _p.orange;
  static Color get orangeBg => _p.orangeBg;
  static Color get pink => _p.pink;
  static Color get pinkBg => _p.pinkBg;
  static Color get bannerAccent => _p.bannerAccent;
  static Color get bg => _p.bg;
  static Color get card => _p.card;
  static Color get border => _p.border;
  static Color get text => _p.text;
  static Color get textMid => _p.textMid;
  static Color get textSub => _p.textSub;
  static Color get textMuted => _p.textMuted;
  static Color get present => _p.present;
  static Color get presentMid => _p.presentMid;
  static Color get presentBg => _p.presentBg;
  static Color get pending => _p.pending;
  static Color get pendingBg => _p.pendingBg;
  static Color get rejected => _p.rejected;
  static Color get rejectedBg => _p.rejectedBg;
  static Color get itRequest => _p.itRequest;
  static Color get itRequestBg => _p.itRequestBg;
  static Color get estRequest => _p.estRequest;
  static Color get estRequestBg => _p.estRequestBg;
  static Color get hseRequest => _p.hseRequest;
  static Color get hseRequestBg => _p.hseRequestBg;
  static Color get inProgress => _p.inProgress;
  static Color get inProgressBg => _p.inProgressBg;
  static Color get neutral => _p.neutral;
  static Color get neutralBg => _p.neutralBg;
  static Color get activeDot => _p.activeDot;
  static Color get heroGreen => _p.heroGreen;
  static Color get heroGreenMid => _p.heroGreenMid;

  /// Warna teks/ikon jenis (cuti, izin, dst.) yang terlalu gelap untuk latar
  /// gelap: naikkan lightness-nya, hue tetap.
  static Color onDark(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(hsl.lightness < 0.68 ? 0.68 : hsl.lightness)
        .withSaturation((hsl.saturation * 0.9).clamp(0.0, 1.0))
        .toColor();
  }

  /// Latar tint untuk [c] di atas kartu gelap (pengganti latar pastel).
  static Color tintOnCard(Color c) =>
      Color.alphaBlend(c.withValues(alpha: 0.18), card);

  /// Status "lembur" — alias ke [teal]/[tealBg].
  static Color get overtime => teal;
  static Color get overtimeBg => tealBg;

  /// Gradient hijau utama.
  static LinearGradient get primaryGradient => LinearGradient(
        begin: const Alignment(-0.6, -1),
        end: const Alignment(0.6, 1),
        // Mode gelap memakai hijau hero (lebih pekat) seperti mockup.
        colors: isDark ? [heroGreen, heroGreenMid] : [primary, primaryMid],
      );

  /// Latar badge angka merah (pengganti [rejected] yang terlalu pucat di
  /// mode gelap untuk teks putih).
  static Color get badge => isDark ? const Color(0xFFD9452F) : rejected;

  /// Latar halaman menu portal: polos di mode terang; di mode gelap ada
  /// semburat hijau di kiri atas yang memudar ke warna latar (seperti mockup).
  static BoxDecoration get portalBackdrop => BoxDecoration(
        color: bg,
        gradient: isDark
            ? RadialGradient(
                center: const Alignment(-0.6, -1),
                radius: 1.1,
                colors: [const Color(0xFF16352A), bg],
                stops: const [0, 0.55],
              )
            : null,
      );

  /// Gradient hijau hero card.
  static LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [heroGreen, heroGreenMid],
      );

  /// Gradasi latar halaman: tint hijau di atas memudar jadi warna latar.
  static LinearGradient get pageGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primaryLight, bg],
        stops: const [0, 0.55],
      );
}
