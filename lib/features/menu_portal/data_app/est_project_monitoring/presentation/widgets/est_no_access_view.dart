import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Tampilan untuk akun yang tidak berhak (API membalas 401/403). Tanpa
/// tombol coba lagi: mengulang tidak mengubah hasilnya.
class EstNoAccessView extends StatelessWidget {
  const EstNoAccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Anda tidak punya akses ke EST Project Monitoring',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
