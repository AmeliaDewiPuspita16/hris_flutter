import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Tombol aksi modul Stationery (Edit, Cancel, Approve, Reject): persegi
/// membulat (radius 10, sama dengan tombol Save/Update di form), dipasang
/// [Expanded] berdampingan supaya footer kartu terisi penuh.
///
/// [filled] true = hijau penuh (aksi utama: Approve / Edit).
/// [filled] false = outline merah di atas latar putih (aksi menolak /
/// membatalkan: Reject / Cancel) — tidak lagi berlatar merah muda pucat.
class StationeryActionButton extends StatelessWidget {
  const StationeryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.filled,
    this.height = 40,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    final textStyle = AppTextStyles.buttonText.copyWith(fontSize: 13);

    return SizedBox(
      height: height,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 17),
              label: Text(label, style: textStyle.copyWith(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: shape,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 17),
              label: Text(
                label,
                style: textStyle.copyWith(color: AppColors.rejected),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rejected,
                backgroundColor: AppColors.card,
                side: BorderSide(color: AppColors.rejected.withAlpha(120)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: shape,
              ),
            ),
    );
  }
}
