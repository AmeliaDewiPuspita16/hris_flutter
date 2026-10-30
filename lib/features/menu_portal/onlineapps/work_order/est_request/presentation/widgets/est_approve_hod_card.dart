import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../../../../../../core/widgets/status_badge.dart';
import '../../domain/est_approval_item.dart';

/// Kartu satu request EST yang menunggu keputusan HOD.
///
/// Isi kartu: Name · Dept, Type, Location + tanggal, Description, dan
/// penanda foto kalau ada lampiran. Yang baru ada di footer: link "View
/// details" di kiri dan dua tombol berbentuk pill di kanan — Reject
/// (merah lembut) dan Approve (hijau penuh).
///
/// Mengetuk badan kartu memanggil [onTap] untuk membuka detail request +
/// lampiran foto (lihat `EstApprovalDetailSheet`) — HOD bisa baca dulu
/// sebelum memutuskan, atau langsung memutuskan lewat tombol di footer.
class EstApproveHodCard extends StatelessWidget {
  const EstApproveHodCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  final EstApprovalItem item;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
              StatusBadge.custom(
                label: item.type,
                color: AppColors.textMuted,
                background: AppColors.neutralBg,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
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
              const SizedBox(width: 8),
              Text(item.date, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(height: 1.4),
          ),
          if (item.imageUrl != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.image_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('Photo attached', style: AppTextStyles.caption),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'View details',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: AppColors.primaryText),
              const Spacer(),
              EstDecisionButton(
                label: 'Reject',
                icon: Icons.close,
                filled: false,
                onPressed: onReject,
              ),
              const SizedBox(width: 8),
              EstDecisionButton(
                label: 'Approve',
                icon: Icons.check,
                filled: true,
                onPressed: onApprove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tombol keputusan HOD berbentuk pill. [filled] true = Approve (hijau
/// penuh), false = Reject (latar merah lembut, teks merah).
class EstDecisionButton extends StatelessWidget {
  const EstDecisionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.filled,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : AppColors.rejected;
    final background = filled ? AppColors.primary : AppColors.rejectedBg;

    return SizedBox(
      height: 38,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: AppTextStyles.buttonText.copyWith(color: foreground, fontSize: 12),
        ),
        style: TextButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
