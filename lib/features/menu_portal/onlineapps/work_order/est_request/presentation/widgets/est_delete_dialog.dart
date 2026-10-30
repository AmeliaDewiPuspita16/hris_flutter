import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/est_request_item.dart';

/// Dialog konfirmasi hapus Work Order. Pakai [EstDeleteDialog.show]; hasilnya
/// true kalau user menekan Delete, false kalau Cancel atau dialog ditutup.
class EstDeleteDialog extends StatelessWidget {
  const EstDeleteDialog({super.key, required this.item});

  final EstRequestItem item;

  static Future<bool> show(BuildContext context, EstRequestItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EstDeleteDialog(item: item),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      // Hilangkan tint hijau bawaan Material 3.
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
                color: AppColors.hseRequestBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                size: 24,
                color: AppColors.hseRequest,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Delete request?',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 6),
            Text(
              'The ${item.type} request at ${item.location} will be deleted '
              'together with its photo and cannot be restored.',
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
                        backgroundColor: AppColors.solid(AppColors.hseRequest),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Delete',
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
