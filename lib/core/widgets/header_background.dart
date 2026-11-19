import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const _headerRadius = BorderRadius.only(
  bottomLeft: Radius.circular(24),
  bottomRight: Radius.circular(24),
);

/// Header bergambar (gelombang + bulatan) untuk layar utama: Home dan halaman
/// depan HRIS.
///
/// Warnanya naik sampai ke balik status bar, jadi layar pemanggil tidak boleh
/// membungkusnya dengan SafeArea atas; jarak amannya ditambahkan di sini.
class HeaderBackground extends StatelessWidget {
  const HeaderBackground({
    super.key,
    required this.child,
    this.bottomPadding = 22,
  });

  final Widget child;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: topInset + 14 + 44 + 22),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, bottomPadding),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/header_bg.png'),
            fit: BoxFit.cover,
            // Bitmap dibuat untuk mode terang; di mode gelap diredupkan.
            colorFilter: AppColors.isDark
                ? ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.42),
                    BlendMode.srcATop,
                  )
                : null,
          ),
          borderRadius: _headerRadius,
        ),
        child: child,
      ),
    );
  }
}

/// Header halaman dalam menu HRIS (Leave Request, Overtime Request, Log
/// Absensi, dst.): warna primary penuh di belakang judul/kontrol, lalu
/// memudar ke warna latar halaman ([AppColors.bg]) tanpa tepi tegas.
///
/// Sama seperti [HeaderBackground], jarak status bar ditambahkan di sini,
/// jadi pemanggil tidak memakai SafeArea atas.
class HeaderGradient extends StatelessWidget {
  const HeaderGradient({
    super.key,
    required this.child,
    this.bottomPadding = 4,
    this.fadeHeight = 20,
  });

  final Widget child;

  /// Jarak antara isi header dan awal pemudaran.
  final double bottomPadding;

  /// Tinggi strip pemudaran primary → latar halaman.
  final double fadeHeight;

  /// primary → hijau muda → latar halaman. Lewat hijau muda supaya
  /// tengahnya tidak keabu-abuan seperti lerp langsung hijau tua → krem.
  static LinearGradient _fade(Color from, Color to) {
    final tint = AppColors.isDark
        ? Color.lerp(from, to, 0.5)!
        : Color.lerp(from, Colors.white, 0.65)!;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [from, tint, to],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.primary,
          padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, bottomPadding),
          child: child,
        ),
        Container(
          height: fadeHeight,
          decoration: BoxDecoration(
            gradient: _fade(AppColors.primary, AppColors.bg),
          ),
        ),
      ],
    );
  }
}
