import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Bantuan format & gaya untuk layar detail proyek executive.

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agt',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String estFmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// Tanggal + jam, mis. "3 Mei 2026, 09:05".
String estFmtDateTime(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day} ${_months[d.month - 1]} ${d.year}, '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

String estFmtHours(double h) {
  if (h >= 1000) return '${(h / 1000).toStringAsFixed(1)}k';
  return h % 1 == 0 ? '${h.toInt()}' : h.toStringAsFixed(1);
}

/// Warna progres jam. Status normal memakai [AppColors.primaryText] karena
/// dipakai sebagai warna isi/teks di atas kartu.
Color estProgressColor(String status) => switch (status) {
      'over_budget' => AppColors.rejected,
      'at_risk' => AppColors.orange,
      _ => AppColors.primaryText,
    };

/// Apakah status memakai warna peringatan (bukan hijau normal).
bool estIsAlertStatus(String status) =>
    status == 'over_budget' || status == 'at_risk';

(Color bg, Color fg, String label) estStatusStyle(String status) =>
    switch (status) {
      'over_budget' => (
          AppColors.rejectedBg,
          AppColors.rejected,
          'Over Budget'
        ),
      'at_risk' => (AppColors.orangeBg, AppColors.orange, 'At Risk'),
      'completed' => (AppColors.presentBg, AppColors.primaryText, 'Selesai'),
      'pending_close' => (
          AppColors.orangeBg,
          AppColors.orange,
          'Pending Approval',
        ),
      _ => (AppColors.presentBg, AppColors.primaryText, 'On Track'),
    };

/// Dekorasi kartu putih berbayang yang dipakai kartu-kartu detail.
BoxDecoration estCardDecoration({double radius = 16, double blur = 8}) {
  return BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: blur,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
