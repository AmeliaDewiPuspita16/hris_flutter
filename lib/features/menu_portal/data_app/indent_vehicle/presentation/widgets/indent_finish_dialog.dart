import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/indent_assigned_item.dart';

/// Dialog konfirmasi driver menutup perjalanan. Pakai
/// [IndentFinishDialog.show]; hasilnya true kalau user menekan Finish.
class IndentFinishDialog extends StatelessWidget {
  const IndentFinishDialog({super.key, required this.item});

  final IndentAssignedItem item;

  static Future<bool> show(
    BuildContext context,
    IndentAssignedItem item,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => IndentFinishDialog(item: item),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = item.dayState();
    final notToday = state == IndentDayState.tomorrow ||
        state == IndentDayState.upcoming;

    return Dialog(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 24,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Finish trip?',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 6),
            Text(
              'The trip to ${item.destination} on ${item.date} will be marked '
              'as finished. ${item.name} can then rate this trip. This cannot '
              'be undone.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(height: 1.5),
            ),
            // Belum hari-H: tidak diblokir (aturan bisnisnya belum
            // diputuskan), tapi driver diingatkan supaya tidak salah tutup.
            if (notToday) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.pendingBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.pending,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This trip is scheduled for ${item.date}, not today. '
                        'Make sure this is the right trip.',
                        style: AppTextStyles.caption.copyWith(
                          height: 1.4,
                          color: AppColors.pending,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMid,
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.buttonText
                            .copyWith(color: AppColors.textMid),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Finish',
                        style: AppTextStyles.buttonText
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
