import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/stationery_request_status.dart';

/// Baris chip penyaring di atas daftar "Request Items": All + satu chip per
/// status dari server (`options.statuses`), dan opsional "My requests".
/// Bergulir mendatar bila layar sempit.
///
/// Hanya menampilkan pilihan; penyaringannya dilakukan server lewat
/// `?status=`.
class StationeryFilterBar extends StatelessWidget {
  const StationeryFilterBar({
    super.key,
    required this.status,
    required this.onStatusChanged,
    this.statuses = defaultStatuses,
    this.onlyMine = false,
    this.onMineChanged,
  });

  /// Dipakai sebelum `options` selesai dimuat, atau bila gagal dimuat.
  static const defaultStatuses = <StationeryRequestStatus>[
    StationeryRequestStatus(
      code: StationeryRequestStatus.codePending,
      label: 'Pending',
    ),
    StationeryRequestStatus(
      code: StationeryRequestStatus.codeApproved,
      label: 'Approved',
    ),
    StationeryRequestStatus(
      code: StationeryRequestStatus.codeRejected,
      label: 'Rejected',
    ),
  ];

  /// Pilihan status, urut seperti dari server.
  final List<StationeryRequestStatus> statuses;

  /// Kode status yang dipilih, atau null untuk "All".
  final String? status;
  final ValueChanged<String?> onStatusChanged;

  /// Chip "My requests" tampil hanya bila [onMineChanged] diisi.
  final bool onlyMine;
  final ValueChanged<bool>? onMineChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: 'All',
            selected: status == null,
            onTap: () => onStatusChanged(null),
          ),
          for (final s in statuses) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: s.label,
              selected: status == s.code,
              onTap: () => onStatusChanged(s.code),
            ),
          ],
          if (onMineChanged != null) ...[
            const SizedBox(width: 14),
            _FilterChip(
              label: 'My requests',
              icon: Icons.person_outline_rounded,
              selected: onlyMine,
              onTap: () => onMineChanged!(!onlyMine),
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textMid;

    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
