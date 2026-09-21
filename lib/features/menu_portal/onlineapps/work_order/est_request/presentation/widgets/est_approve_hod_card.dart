import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../domain/est_request_item.dart';

/// Kartu satu request EST yang menunggu keputusan HOD — bentuk tombolnya
/// (ikon bulat approve/reject) sama dengan `ApproveRequestCard` di IT
/// Request.
///
/// Sengaja hanya menampilkan detail request asli (Name/Dept, Type,
/// Location, Description, foto kalau ada) — TIDAK menampilkan Working
/// Method / Material and Tools. Form Add Request cuma punya 4 field (Type,
/// Location, Description, Photo), dan belum ada layar mana pun di
/// aplikasi ini yang mengisi rencana kerja itu, jadi field itu belum
/// punya sumber data yang benar. Kalau nanti ada layar tim EST untuk
/// menyusun rencana kerja, plan itu baru layak ditampilkan di sini.
class EstApproveHodCard extends StatelessWidget {
  const EstApproveHodCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final EstRequestItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
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
              Text(item.type.label, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 4),
          Row(
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
          const SizedBox(height: 6),
          Text(
            item.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(height: 1.4),
          ),
          if (item.imageFileName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.image_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(item.imageFileName!, style: AppTextStyles.caption),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _CircleAction(
                icon: Icons.check,
                color: AppColors.present,
                background: AppColors.presentBg,
                onTap: onApprove,
              ),
              const SizedBox(width: 8),
              _CircleAction(
                icon: Icons.close,
                color: AppColors.rejected,
                background: AppColors.rejectedBg,
                onTap: onReject,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}
