import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// accent, ghost, danger, green.
enum AppButtonVariant { primary, secondary, accent, ghost, danger, green }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool enabled;

  ({Color bg, Color fg, Color? border}) _styleFor(AppButtonVariant v) {
    switch (v) {
      case AppButtonVariant.primary:
        return (bg: AppColors.primary, fg: Colors.white, border: null);
      case AppButtonVariant.secondary:
        return (bg: AppColors.primaryLight, fg: AppColors.primaryMid, border: AppColors.border);
      case AppButtonVariant.accent:
        return (bg: AppColors.accent, fg: Colors.white, border: null);
      case AppButtonVariant.ghost:
        return (bg: Colors.transparent, fg: AppColors.primaryMid, border: AppColors.primaryMid);
      case AppButtonVariant.danger:
        return (bg: AppColors.rejectedBg, fg: AppColors.rejected, border: AppColors.rejected);
      case AppButtonVariant.green:
        return (bg: AppColors.heroGreen, fg: Colors.white, border: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(variant);
    final isDisabled = !enabled || onPressed == null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: s.bg,
          disabledBackgroundColor: s.bg.withValues(alpha: 0.5),
          foregroundColor: s.fg,
          disabledForegroundColor: s.fg.withValues(alpha: 0.5),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: s.border != null ? BorderSide(color: s.border!, width: 1.5) : BorderSide.none,
          ),
        ),
        child: Text(label, style: AppTextStyles.buttonText.copyWith(color: s.fg)),
      ),
    );
  }
}
