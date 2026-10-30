import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Tombol simpan form proyek; menampilkan spinner dan "Menyimpan..." saat
/// [isLoading].
class EstFormSubmitButton extends StatelessWidget {
  const EstFormSubmitButton({
    super.key,
    required this.isEdit,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isEdit;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final orange = AppColors.solid(AppColors.orange);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: orange.withValues(alpha: 0.6),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                isEdit ? Icons.save_outlined : Icons.add_circle_outline,
                size: 20,
              ),
        label: Text(
          isLoading
              ? 'Menyimpan...'
              : isEdit
                  ? 'Simpan Perubahan'
                  : 'Buat Proyek',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
