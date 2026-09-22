import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppStatus { present, pending, rejected, neutral, onProgress }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.label});

  final AppStatus status;

  /// Override label bawaan — dipakai HSE Work Request supaya badge-nya
  /// bisa bilang "On Waiting"/"On Progress"/dst persis seperti di web,
  /// bukan cuma "Menunggu" generik yang dipakai modul lain.
  final String? label;

  ({Color fg, Color bg, String label}) get _data {
    switch (status) {
      case AppStatus.present:
        return (fg: AppColors.present, bg: AppColors.presentBg, label: 'Disetujui');
      case AppStatus.pending:
        return (fg: AppColors.pending, bg: AppColors.pendingBg, label: 'Menunggu');
      case AppStatus.rejected:
        return (fg: AppColors.rejected, bg: AppColors.rejectedBg, label: 'Ditolak');
      case AppStatus.neutral:
        return (fg: AppColors.neutral, bg: AppColors.neutralBg, label: '-');
      case AppStatus.onProgress:
        return (fg: AppColors.inProgress, bg: AppColors.inProgressBg, label: 'Diproses');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final text = label ?? d.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: d.bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: d.fg)),
    );
  }
}
