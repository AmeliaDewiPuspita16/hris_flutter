import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../../../../../../core/widgets/status_badge.dart';
import '../../domain/est_request_item.dart';

/// Satu baris di layar "EST Work Order" — mengemas kolom tabel web (Name,
/// Dept, Type Request, Location, Description, Date, Status) jadi satu kartu
/// ringkas. Teks status memakai label dari server.
class EstRequestRow extends StatelessWidget {
  const EstRequestRow({super.key, required this.item, this.onTap});

  final EstRequestItem item;

  /// Null = kartu tidak bisa diketuk (detail belum tersambung).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${item.requesterName} · ${item.department}',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(item: item),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatusBadge.custom(
                label: item.type,
                color: AppColors.textMuted,
                background: AppColors.neutralBg,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.place_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(height: 1.4),
          ),
          // Alasan penolakan hanya ada pada request yang ditolak HOD.
          if (item.status.isRejected && item.rejectReason != null) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: ${item.rejectReason}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.rejected,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(item.date, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// Badge status: teks dari label server, warna dari [EstRequestStatus].
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.item});

  final EstRequestItem item;

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: status.color,
        ),
      ),
    );
  }
}
