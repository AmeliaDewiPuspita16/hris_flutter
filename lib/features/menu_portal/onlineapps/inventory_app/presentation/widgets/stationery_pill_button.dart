import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Tombol aksi berbentuk pill untuk modul Stationery (Edit, Cancel, Approve,
/// Reject). [filled] true = hijau penuh (Edit / Approve), false = latar merah
/// lembut dengan teks merah (Cancel / Reject). Gaya sama dengan
/// `EstDecisionButton`.
class StationeryPillButton extends StatelessWidget {
  const StationeryPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.filled,
    this.height = 36,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : AppColors.rejected;
    final background = filled ? AppColors.primary : AppColors.rejectedBg;

    return SizedBox(
      height: height,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(
          label,
          style: AppTextStyles.buttonText
              .copyWith(color: foreground, fontSize: 12),
        ),
        style: TextButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
