import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Panel hijau di atas: logo, nama portal, dan kalimat pengantar.
///
/// Sengaja tidak dibungkus SafeArea supaya warna hijaunya ikut mengisi
/// area status bar seperti di desain; jarak amannya ditambahkan manual.
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  /// Hijau header khusus mode gelap: lebih tua dan lebih "murni hijau"
  /// (bukan teal) daripada heroGreen, supaya header tidak menyala di atas
  /// latar gelap. Sengaja lokal di sini agar kartu/hero di layar lain yang
  /// memakai AppColors.primaryGradient tidak ikut berubah.
  static const _darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A3223), Color(0xFF06241A)],
  );

  /// Bagian foto yang ditampilkan, dihitung dari ATAS. Foto header_login.png
  /// memuat tagline "At The Forefront, From The Seafront" di ~32% terbawah,
  /// jadi hanya bagian atasnya yang dipakai supaya tulisan itu tidak
  /// menimpa teks pengantar. Naikkan kalau ingin lebih banyak laut, tapi
  /// di atas ±0.66 ujung tulisan mulai terlihat.
  static const double _visiblePhotoFraction = 0.62;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final isDark = AppColors.isDark;

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
              child: ClipRect(
                // Foto digambar setinggi 1 / _visiblePhotoFraction kali kotak
                // header, menempel di ATAS; kelebihannya (bagian bawah foto,
                // tempat tulisan) terpotong oleh ClipRect.
                child: FractionallySizedBox(
                  alignment: Alignment.topCenter,
                  heightFactor: 1 / _visiblePhotoFraction,
                  child: Image.asset(
                    'assets/images/header_login.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topRight,
                    // Foto udara dibuat lebih samar di mode gelap.
                    opacity: AlwaysStoppedAnimation<double>(
                      isDark ? 0.12 : 0.16,
                    ),
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
