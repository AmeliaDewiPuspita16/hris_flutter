import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Panel hijau di atas: logo, nama portal, dan kalimat pengantar.
///
/// Sengaja tidak dibungkus SafeArea supaya warna hijaunya ikut mengisi
/// area status bar seperti di desain; jarak amannya ditambahkan manual.
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  /// Hijau header khusus MODE GELAP: lebih tua dan lebih "murni hijau"
  /// (bukan teal) daripada heroGreen, supaya header tidak menyala di atas
  /// latar gelap. Mode terang tetap memakai AppColors.primaryGradient.
  /// Sengaja lokal di sini agar kartu/hero di layar lain tidak ikut berubah.
  static const _darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A3223), Color(0xFF06241A)],
  );

  /// Foto header_login.png memuat tagline "At The Forefront, From The
  /// Seafront" di ~32% terbawahnya. Foto ditaruh di ATAS dengan skala
  /// normal (selebar header), lalu dipudarkan ke hijau di antara dua batas
  /// ini (pecahan dari tinggi foto) supaya tulisan itu tidak terlihat.
  ///
  /// Mau foto terlihat lebih ke bawah: naikkan [_photoFadeStart].
  /// Ujung tulisan mulai di sekitar 0.66, jadi [_photoFadeEnd] jangan
  /// melewati angka itu.
  static const double _photoFadeStart = 0.48;
  static const double _photoFadeEnd = 0.64;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final isDark = AppColors.isDark;

    // Kepekatan foto: samar di mode gelap, sedikit lebih jelas di terang.
    final photoAlpha = isDark ? 0.12 : 0.16;

    return ClipPath(
      clipper: _WaveBottomClipper(),
      child: Stack(
        children: [
          // Latar: gradien + foto. Positioned.fill supaya otomatis menutupi
          // seluruh kotak header (termasuk padding) tanpa ikut menentukan
          // tingginya — tinggi tetap ditentukan oleh isi di atasnya.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark ? _darkGradient : AppColors.primaryGradient,
              ),
              // Align: foto menempel di atas dengan tinggi mengikuti rasio
              // aslinya (tidak diperbesar). ShaderMask ada di dalam Align
              // supaya batas pudarnya dihitung dari tinggi FOTO, bukan
              // tinggi header.
              child: Align(
                alignment: Alignment.topCenter,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // Kepekatan foto digabung ke sini: tetap di photoAlpha
                    // sampai _photoFadeStart, lalu memudar sampai 0 di
                    // bagian tagline.
                    colors: [
                      Colors.black.withValues(alpha: photoAlpha),
                      Colors.black.withValues(alpha: photoAlpha),
                      Colors.transparent,
                    ],
                    stops: const [0, _photoFadeStart, _photoFadeEnd],
                  ).createShader(bounds),
                  child: Image.asset(
                    'assets/images/header_login.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, topInset + 20, 24, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/logo_white.png',
                  height: 48,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 20),
                Text(
                  'Sign in with your corporate email. '
                  'Your view is tied by your position.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Membentuk tepi bawah header jadi gelombang landai, bukan sekadar sudut
/// membulat — meniru siluet pada desain acuan.
class _WaveBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 36);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.52,
      size.height - 18,
    );
    path.quadraticBezierTo(
      size.width * 0.78,
      size.height - 40,
      size.width,
      size.height - 12,
    );

    path
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
