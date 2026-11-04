import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/stationery_request_status.dart';

/// Baris chip penyaring di atas daftar "Request Items": All / Pending /
/// Approved / Rejected, plus "My requests" untuk hanya menampilkan request
/// milik sendiri. Bergulir mendatar bila layar sempit.
///
/// Menyaring request yang SUDAH dimuat (sama seperti kolom search).
class StationeryFilterBar extends StatelessWidget {
  const StationeryFilterBar({
    super.key,
    required this.status,
    required this.onlyMine,
    required this.onStatusChanged,
    required this.onMineChanged,
  });

  /// Kode status yang dipilih, atau null untuk "All".
  final String? status;
  final bool onlyMine;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<bool> onMineChanged;

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
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Pending',
            selected: status == StationeryRequestStatus.codePending,
            onTap: () => onStatusChanged(StationeryRequestStatus.codePending),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Approved',
            selected: status == StationeryRequestStatus.codeApproved,
            onTap: () => onStatusChanged(StationeryRequestStatus.codeApproved),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Rejected',
            selected: status == StationeryRequestStatus.codeRejected,
            onTap: () => onStatusChanged(StationeryRequestStatus.codeRejected),
          ),
          const SizedBox(width: 14),
          _FilterChip(
            label: 'My requests',
            icon: Icons.person_outline_rounded,
            selected: onlyMine,
            onTap: () => onMineChanged(!onlyMine),
          ),
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
