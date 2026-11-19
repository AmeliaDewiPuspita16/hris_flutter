import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../domain/opname_formatters.dart';
import 'opname_text_styles.dart';

/// Badge showing the counted vs. system difference. Each state has its own
/// colour so they can be told apart at a glance:
///
///  - GREEN  "Matches system" (equal): all good.
///  - BLUE   "+8 bags" (surplus): more than the system says.
///  - RED    "-8 bags" (shortage): less than the system says.
///  - GREY   "Not counted".
class DifferenceLabel extends StatelessWidget {
  final double? difference;
  final String unit;

  const DifferenceLabel({super.key, required this.difference, required this.unit});

  /// Blue for surplus. The portal palette has no blue, so it lives here, with
  /// a lighter shade in dark mode.
  static Color get _surplusFg =>
      AppColors.isDark ? const Color(0xFF7DB4FF) : const Color(0xFF1D5FBF);
  static Color get _surplusBg => AppColors.isDark
      ? const Color(0xFF7DB4FF).withValues(alpha: 0.16)
      : const Color(0xFFE6F0FF);

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
      fg = _surplusFg;
      bg = _surplusBg;
      icon = Icons.arrow_upward_rounded;
      text = '+${formatQty(d)} $unit';
    } else if (d < 0) {
      fg = AppColors.rejected;
      bg = AppColors.rejectedBg;
      icon = Icons.arrow_downward_rounded;
      text = '-${formatQty(-d)} $unit';
    } else {
      fg = OpnameTextStyles.success;
      bg = AppColors.presentBg;
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
