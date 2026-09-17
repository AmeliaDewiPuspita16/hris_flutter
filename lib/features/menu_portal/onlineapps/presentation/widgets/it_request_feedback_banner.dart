import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../domain/it_request_item.dart';

/// Kartu untuk permintaan yang sudah selesai dikerjakan tim IT tapi belum
/// diberi feedback.
///
/// Sengaja dibuat lebih menonjol (aksen emas di tepi kiri + tombol aksi
/// langsung) — sama seperti pola [ActionNeededCard] di Notifications —
/// supaya jelas kalau ini yang harus diselesaikan dulu sebelum staff bisa
/// mengajukan permintaan baru.
class ItRequestFeedbackBanner extends StatelessWidget {
  const ItRequestFeedbackBanner({
    super.key,
    required this.item,
    required this.onGiveFeedback,
  });

  final ItRequestItem item;
  final VoidCallback onGiveFeedback;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: AppColors.accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 15, color: AppColors.accent),
                          const SizedBox(width: 6),
                          const Text(
                            'SUDAH SELESAI · BERI FEEDBACK',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.description,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Selesai dikerjakan · ${item.date}',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Beri feedback untuk permintaan ini sebelum '
                        'mengajukan permintaan baru.',
                        style: AppTextStyles.caption.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton(
                          onPressed: onGiveFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: Text(
                            'Beri Feedback',
                            style: AppTextStyles.buttonText.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}