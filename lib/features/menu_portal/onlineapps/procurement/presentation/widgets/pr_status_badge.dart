import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/pr_status.dart';

/// Badge status PR. Dipakai di kartu daftar dan di kepala layar detail,
/// makanya dipisah dari keduanya.
class PrStatusBadge extends StatelessWidget {
  const PrStatusBadge({super.key, required this.status, this.onDark = false});

  final PrStatus status;

  /// Versi untuk di atas hero hijau: latar putih transparan, teks putih.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: onDark ? Colors.white24 : status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: onDark ? Colors.white : status.color,
        ),
      ),
    );
  }
}
