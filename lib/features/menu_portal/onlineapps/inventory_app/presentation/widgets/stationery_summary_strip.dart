import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/stationery_request_page.dart';
import '../../domain/stationery_request_status.dart';

/// Ringkasan di atas daftar "Request Items": All / Pending / Approved /
/// Rejected. Setiap kotak juga berfungsi sebagai penyaring cepat (ketuk lagi
/// untuk melepas), jadi pengguna tidak perlu filter terpisah untuk kasus yang
/// paling sering.
///
/// Angkanya datang dari `summary` server ([StationeryStatusCounts]) dan
/// berlaku untuk SELURUH data, bukan hanya halaman yang sudah dimuat. Bila
/// server belum mengirim salah satunya, kotak itu menampilkan "–".
class StationerySummaryStrip extends StatelessWidget {
  const StationerySummaryStrip({
    super.key,
    required this.counts,
    required this.total,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  /// Jumlah per status dari server.
  final StationeryStatusCounts counts;

  /// Total request di server (`meta.total`).
  final int total;

  /// Kode status yang sedang menyaring daftar, atau null untuk semua.
  final String? selectedStatus;

  /// Dipanggil dengan kode status yang dipilih, atau null untuk melepas.
  final ValueChanged<String?> onStatusSelected;

  static String _fmt(int? n) => n == null ? '–' : '$n';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'All',
            value: '$total',
            icon: Icons.layers_outlined,
            color: AppColors.primaryText,
            background: AppColors.primaryLight,
            selected: selectedStatus == null,
            onTap: () => onStatusSelected(null),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Pending',
            value: _fmt(counts.pending),
            icon: Icons.schedule_rounded,
            color: AppColors.accent,
            background: AppColors.accentBg,
            selected: selectedStatus == StationeryRequestStatus.codePending,
            onTap: () => _toggle(StationeryRequestStatus.codePending),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Approved',
            value: _fmt(counts.approved),
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.present,
            background: AppColors.presentBg,
            selected: selectedStatus == StationeryRequestStatus.codeApproved,
            onTap: () => _toggle(StationeryRequestStatus.codeApproved),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Rejected',
            value: _fmt(counts.rejected),
            icon: Icons.cancel_outlined,
            color: AppColors.rejected,
            background: AppColors.rejectedBg,
            selected: selectedStatus == StationeryRequestStatus.codeRejected,
            onTap: () => _toggle(StationeryRequestStatus.codeRejected),
          ),
        ),
      ],
    );
  }

  void _toggle(String code) =>
      onStatusSelected(selectedStatus == code ? null : code);
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? background : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? color.withAlpha(150) : AppColors.border,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.card : background,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(icon, size: 13, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: selected ? color : AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
