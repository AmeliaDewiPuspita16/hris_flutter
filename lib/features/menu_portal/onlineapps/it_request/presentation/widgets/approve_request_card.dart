import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/approve_request_item.dart';

/// Kartu satu permintaan yang menunggu keputusan tim IT — dengan tombol 
/// approve/reject sebagai ikon bulat.
class ApproveRequestCard extends StatelessWidget {
  const ApproveRequestCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final ApproveRequestItem item;
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
                  item.requesterName,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text(item.department, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.description, style: AppTextStyles.bodyMuted.copyWith(height: 1.4)),
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
