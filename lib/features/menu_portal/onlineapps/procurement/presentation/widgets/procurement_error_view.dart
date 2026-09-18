import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Pesan galat beserta tombol muat ulang.
///
/// Dipakai daftar maupun detail: keduanya gagal dengan cara yang sama dan
/// pemulihannya juga sama — coba lagi.
class ProcurementErrorView extends StatelessWidget {
  const ProcurementErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  /// Pesan dari server, sudah siap ditampilkan.
  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 32,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Coba lagi', style: AppTextStyles.buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
