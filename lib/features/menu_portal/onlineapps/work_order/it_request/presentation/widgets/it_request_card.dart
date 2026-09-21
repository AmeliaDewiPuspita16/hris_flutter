import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/utils/date_formatter.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../domain/it_request_item.dart';
import '../../domain/it_request_type.dart';
import 'it_request_rating_stars.dart';

/// Satu baris riwayat permintaan IT/Media milik staff: jenis + kategori,
/// deskripsi, badge status, tanggal, dan rating (kalau sudah dinilai) —
/// dipakai untuk item yang TIDAK sedang menunggu rating (item yang
/// menunggu rating pakai [ItRequestFeedbackBanner]).
class ItRequestCard extends StatelessWidget {
  const ItRequestCard({super.key, required this.item, this.onTap});

  final ItRequestItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isMedia = item.type == ItRequestType.media;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isMedia ? Icons.palette_outlined : Icons.dns_outlined,
                size: 14,
                color: isMedia ? AppColors.violet : AppColors.teal,
              ),
              const SizedBox(width: 5),
              Expanded(
                flex: 3,
                child: Text(
                  '${item.type.label} · ${item.category.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: isMedia ? AppColors.violet : AppColors.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Flexible, bukan lebar tetap: label status dari server tidak
              // dibatasi panjangnya, dan tanpa ini label panjang bisa
              // meluber di layar sempit alih-alih terpotong rapi.
              Flexible(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.status.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: item.status.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, height: 1.35),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(DateFormatter.shortDate(item.createdAt), style: AppTextStyles.caption),
              ),
              if (item.rating != null) ItRequestRatingStars(rating: item.rating!, size: 13),
            ],
          ),
        ],
      ),
    );
  }
}
