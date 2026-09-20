import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../domain/est_request_item.dart';
import '../../domain/est_request_type.dart';

/// Satu baris di layar "EST Work Order" — mengemas kolom tabel web (Name,
/// Dept, Type Request, Location, Description, Date, Status) jadi satu kartu
/// ringkas.
class EstRequestRow extends StatelessWidget {
  const EstRequestRow({super.key, required this.item, this.onTap});

  final EstRequestItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: item.status.isTappable ? onTap : null,
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
              _TypeTag(type: item.type),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 13, color: AppColors.textMuted),
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
          const SizedBox(height: 6),
          Text(item.date, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// Badge status — untuk [EstRequestStatus.maintenancePlan] ditambah ikon
/// mata supaya jelas bisa diketuk.
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status.isTappable) ...[
            Icon(Icons.visibility_outlined, size: 11, color: status.color),
            const SizedBox(width: 4),
          ],
          Text(
            status.label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTag extends StatelessWidget {
  const _TypeTag({required this.type});

  final EstRequestType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.label,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textMid,
        ),
      ),
    );
  }
}
