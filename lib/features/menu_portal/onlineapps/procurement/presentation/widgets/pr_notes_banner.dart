import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';

/// Banner untuk catatan yang mengubah arti seluruh PR — alasan penolakan
/// atau catatan revisi.
///
/// Ditaruh di atas segalanya karena tanpa membacanya, sisa layar bisa
/// disalahpahami sebagai PR yang masih berjalan normal.
class PrNotesBanner extends StatelessWidget {
  const PrNotesBanner({
    super.key,
    required this.title,
    required this.body,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String title;
  final String body;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
