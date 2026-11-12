import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/item_request_entry.dart';

/// Dialog konfirmasi tombol "Cancel" pada request milik sendiri. Hasilnya
/// true kalau user menekan "Cancel request", false kalau memilih "Keep" atau
/// dialog ditutup. Gayanya sama dengan `EstDeleteDialog`.
class ItemRequestCancelDialog extends StatelessWidget {
  const ItemRequestCancelDialog({super.key, required this.item});

  final ItemRequestEntry item;

  static Future<bool> show(
    BuildContext context,
    ItemRequestEntry item,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ItemRequestCancelDialog(item: item),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
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
              decoration: BoxDecoration(
                color: AppColors.rejectedBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.remove_circle_outline,
                size: 24,
                color: AppColors.rejected,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Cancel request?',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 6),
            Text(
              '${item.code} (${item.itemName}, ${item.quantityLabel}) will be '
              'cancelled and cannot be restored.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(height: 1.5),
            ),
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
                        side: BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Keep',
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
                        backgroundColor: AppColors.solid(AppColors.rejected),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel request',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
