import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Panel hijau di atas: logo, nama portal, dan kalimat pengantar.
///
/// Sengaja tidak dibungkus SafeArea supaya warna hijaunya ikut mengisi
/// area status bar seperti di desain; jarak amannya ditambahkan manual.
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return ClipPath(
      clipper: _WaveBottomClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(24, topInset + 20, 24, 56),
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          // Dilukis lewat decoration (bukan widget Image di Stack) supaya
          // otomatis menutupi seluruh kotak header termasuk padding —
          // Stack sempat ikut menyusut sebesar kontennya saja kalau
          // gambarnya ditaruh sebagai children biasa.
          image: DecorationImage(
            image: AssetImage('assets/images/header_login.png'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            opacity: 0.16,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColorFiltered(
              // Aset aslinya hijau tua — nyaris tak kelihatan di atas
              // header hijau, jadi diputihkan lewat srcIn (aman karena
              // latar PNG-nya transparan, beda dari bg_login.png yang
              // opaque).
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assets/images/bie.png',
                height: 48,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
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
