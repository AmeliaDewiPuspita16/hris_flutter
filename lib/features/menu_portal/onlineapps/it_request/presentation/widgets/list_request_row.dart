import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/list_request_item.dart';

/// Satu baris di tab "List Request" — requester, deskripsi, badge status,
/// dan tanggal. Ini daftar SEMUA permintaan (bukan cuma milik sendiri),
/// makanya nama requester ikut ditampilkan.
class ListRequestRow extends StatelessWidget {
  const ListRequestRow({super.key, required this.item, this.onTap});

  final ListRequestItem item;
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
          Text(item.description, style: AppTextStyles.caption.copyWith(height: 1.4)),
          const SizedBox(height: 6),
          Text(item.date, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}