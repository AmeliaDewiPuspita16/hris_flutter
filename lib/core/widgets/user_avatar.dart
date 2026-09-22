import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Avatar pengguna — foto profil kalau [photoUrl] tersedia, jatuh ke
/// lingkaran berisi [initials] kalau tidak (belum ada foto, atau foto gagal
/// dimuat).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    required this.fontSize,
    this.photoUrl,
    this.radius = 22,
    this.backgroundColor = const Color(0x2EFFFFFF),
    this.textColor = Colors.white,
    this.fontWeight = FontWeight.w700,
  });

  final String initials;
  final String? photoUrl;
  final double radius;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: url == null
          ? _InitialsText(
              initials: initials,
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            )
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialsText(
                  initials: initials,
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              ),
            ),
    );
  }
}

class _InitialsText extends StatelessWidget {
  const _InitialsText({
    required this.initials,
    required this.color,
    required this.fontSize,
    required this.fontWeight,
  });

  final String initials;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    );
  }
}
