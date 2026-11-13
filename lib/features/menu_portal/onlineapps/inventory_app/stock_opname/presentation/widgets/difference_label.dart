import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../domain/opname_formatters.dart';

/// Badge showing the counted vs. system difference (with a colored
/// background): green "+8 bags" (surplus), red "-8 bags" (shortage),
/// grey "Matches system" (equal), light grey "Not counted".
class DifferenceLabel extends StatelessWidget {
  final double? difference;
  final String unit;

  const DifferenceLabel({super.key, required this.difference, required this.unit});

  @override
  Widget build(BuildContext context) {
    final d = difference;
    final Color fg;
    final Color bg;
    final IconData icon;
    final String text;

    if (d == null) {
      fg = AppColors.textMuted;
      bg = AppColors.bg;
      icon = Icons.hourglass_empty_rounded;
      text = 'Not counted';
    } else if (d > 0) {
      fg = AppColors.present;
      bg = AppColors.presentBg;
      icon = Icons.arrow_upward_rounded;
      text = '+${formatQty(d)} $unit';
    } else if (d < 0) {
      fg = AppColors.rejected;
      bg = AppColors.rejectedBg;
      icon = Icons.arrow_downward_rounded;
      text = '-${formatQty(-d)} $unit';
    } else {
      fg = AppColors.primaryText;
      bg = AppColors.primaryLight;
      icon = Icons.check_rounded;
      text = 'Matches system';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}
