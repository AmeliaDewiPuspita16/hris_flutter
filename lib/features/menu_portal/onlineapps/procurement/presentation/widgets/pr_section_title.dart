import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Judul bagian di layar detail ("ITEMS", "ATTACHMENTS", dst) — padanan
/// heading bergaris bawah di modal versi web.
class PrSectionTitle extends StatelessWidget {
  const PrSectionTitle({super.key, required this.title, required this.icon, this.trailing});

  /// Ditulis apa adanya, jadi kirim sudah dalam huruf kapital.
  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.6,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
