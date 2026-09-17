import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/it_request_item.dart';

/// Satu baris riwayat permintaan IT/Media milik staff: deskripsi, tanggal,
/// dan badge status — dipakai untuk item yang TIDAK sedang menunggu
/// feedback (item yang menunggu feedback pakai [ItRequestFeedbackBanner]).
class ItRequestCard extends StatelessWidget {
  const ItRequestCard({super.key, required this.item});

  final ItRequestItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.description,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: item.status.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status.label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: item.status.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.date, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}