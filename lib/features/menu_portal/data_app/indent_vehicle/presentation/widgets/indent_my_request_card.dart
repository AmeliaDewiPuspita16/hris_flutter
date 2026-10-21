import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/indent_my_request_item.dart';
import '../../domain/indent_progress_status.dart';

/// Kartu satu request di tab "My Request". Hanya-baca: tujuan, waktu,
/// keperluan, kendaraan & driver, status, lalu rating + komentar bila
/// sudah ada. Tanpa nama peminta (semuanya milik sendiri).
class IndentMyRequestCard extends StatelessWidget {
  const IndentMyRequestCard({super.key, required this.item, this.onTap});

  final IndentMyRequestItem item;
  final VoidCallback? onTap;

  String get _driverText {
    final driver = item.driver;
    if (driver != null) return driver;
    // Server memakai "Tanpa Driver" untuk id_driver 0/null, baik untuk
    // request tanpa driver maupun yang belum ditunjuk; selama masih
    // menunggu, "belum ditetapkan" lebih jujur.
    return item.status == IndentProgressStatus.onWaiting
        ? 'Not assigned yet'
        : 'No driver';
  }

  @override
  Widget build(BuildContext context) {
    final status = item.status;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: tujuan + badge status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.destination,
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Baris 2: tanggal + jam
          _InfoLine(
            icon: Icons.event_outlined,
            text: '${item.date}  ·  ${item.timeRange}',
          ),
          const SizedBox(height: 8),

          // Baris 3: keperluan
          Text(
            item.remark,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Baris 4: kendaraan & driver
          Row(
            children: [
              Expanded(
                child: _InfoLine(
                  icon: Icons.directions_car_outlined,
                  text: item.vehicle ?? '-',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoLine(
                  icon: Icons.person_outline,
                  text: _driverText,
                ),
              ),
            ],
          ),

          // Baris 5: rating + komentar, atau pengingat feedback
          if (item.rating != null) ...[
            const SizedBox(height: 10),
            _Stars(rating: item.rating!),
            if (item.feedback != null) ...[
              const SizedBox(height: 4),
              Text(
                '"${item.feedback}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ] else if (item.awaitsFeedback) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star_outline_rounded,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  'Waiting for your feedback',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],

          // Baris 6: jejak waktu
          if (item.createdAt != null || _showFinished) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (item.createdAt != null) 'Requested ${item.createdAt}',
                if (_showFinished) 'Finished ${item.finishedAt}',
              ].join('  ·  '),
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool get _showFinished =>
      item.status == IndentProgressStatus.done && item.finishedAt != null;
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 15,
            color: AppColors.accent,
          ),
      ],
    );
  }
}
