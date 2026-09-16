import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// accent, ghost, danger, green.
///
/// [primaryGradient] sama dengan [primary] tapi berlatar gradasi hijau —
/// dipakai untuk satu aksi utama di sebuah layar.
enum AppButtonVariant {
  primary,
  primaryGradient,
  secondary,
  accent,
  ghost,
  danger,
  green,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool enabled;

  /// Mengganti label dengan indikator dan menonaktifkan tombol selama
  /// menunggu proses — misalnya saat login menunggu jawaban server.
  final bool isLoading;

  ({Color bg, Color fg, Color? border}) _styleFor(AppButtonVariant v) {
    switch (v) {
      case AppButtonVariant.primary:
      case AppButtonVariant.primaryGradient:
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

  /// Gradasi latar untuk varian yang memakainya, atau null untuk warna rata.
  Gradient? _gradientFor(AppButtonVariant v) =>
      v == AppButtonVariant.primaryGradient ? AppColors.primaryGradient : null;

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(variant);
    final isDisabled = !enabled || isLoading || onPressed == null;

    // Saat nonaktif, gradasinya dilepas supaya tombol memakai warna redup
    // yang sama dengan varian lain — keadaan mati harus terbaca sebagai mati.
    final gradient = isDisabled ? null : _gradientFor(variant);

    final button = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          // Gradasi digambar oleh pembungkus di bawah, jadi latar tombolnya
          // sendiri dibuat tembus pandang.
          backgroundColor: gradient != null ? Colors.transparent : s.bg,
          shadowColor: gradient != null ? Colors.transparent : null,
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
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    s.fg.withValues(alpha: 0.7),
                  ),
                ),
              )
            : Text(label, style: AppTextStyles.buttonText.copyWith(color: s.fg)),
      ),
    );

    if (gradient == null) return button;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: button,
    );
  }
}
