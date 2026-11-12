import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/item_request_status.dart';

/// Baris chip penyaring di atas daftar "Request Items": All + satu chip per
/// status dari server (`options.statuses`), dan opsional "My requests".
/// Bergulir mendatar bila layar sempit.
///
/// Hanya menampilkan pilihan; penyaringannya dilakukan server lewat
/// `?status=`.
class ItemRequestFilterBar extends StatelessWidget {
  const ItemRequestFilterBar({
    super.key,
    required this.status,
    required this.onStatusChanged,
    this.statuses = defaultStatuses,
    this.onlyMine = false,
    this.onMineChanged,
  });

  /// Dipakai sebelum `options` selesai dimuat, atau bila gagal dimuat.
  static const defaultStatuses = <ItemRequestStatus>[
    ItemRequestStatus(
      code: ItemRequestStatus.codePending,
      label: 'Pending',
    ),
    ItemRequestStatus(
      code: ItemRequestStatus.codeApproved,
      label: 'Approved',
    ),
    ItemRequestStatus(
      code: ItemRequestStatus.codeRejected,
      label: 'Rejected',
    ),
  ];

  /// Pilihan status, urut seperti dari server.
  final List<ItemRequestStatus> statuses;

  /// Kode status yang dipilih, atau null untuk "All".
  final String? status;
  final ValueChanged<String?> onStatusChanged;

  /// Chip "My requests" tampil hanya bila [onMineChanged] diisi.
  final bool onlyMine;
  final ValueChanged<bool>? onMineChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
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
              // Warna mengikuti badge status di kartu.
              accent: s.color,
              accentBg: s.background,
            ),
          ],
          if (onMineChanged != null) ...[
            // Pemisah tipis: "My requests" adalah penyaring lain (milik
            // siapa), bukan salah satu status.
            Container(
              width: 1,
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.border,
            ),
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
    this.accent,
    this.accentBg,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Warna status (chip status saja), dipakai hanya saat chip dipilih.
  /// Null = hijau lembut bawaan (All, My requests).
  final Color? accent;
  final Color? accentBg;

  @override
  Widget build(BuildContext context) {
    // Terpilih = warna lembut (tonal), bukan warna pekat, supaya tidak
    // bersaing dengan tab di atasnya.
    final foreground =
        selected ? (accent ?? AppColors.primaryText) : AppColors.textMid;

    return Material(
      color: selected ? (accentBg ?? AppColors.primaryLight) : AppColors.card,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? (accent ?? AppColors.primaryMid) : AppColors.border,
        ),
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
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
