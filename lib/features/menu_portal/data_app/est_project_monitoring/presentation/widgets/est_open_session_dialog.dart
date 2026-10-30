import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/executive_dashboard.dart';

/// Konfirmasi "Buka Sesi Hari Ini?". Hasil true = pengguna menekan Buka Sesi.
class EstOpenSessionDialog {
  const EstOpenSessionDialog._();

  static Future<bool> show(
    BuildContext context,
    ExecutiveProjectModel project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Buka Sesi Hari Ini?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.text,
          ),
        ),
        content: Text(
          'Sesi proyek "${project.name}" akan dibuka. DW dapat mulai absen masuk.',
          style: TextStyle(color: AppColors.textSub, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Buka Sesi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
