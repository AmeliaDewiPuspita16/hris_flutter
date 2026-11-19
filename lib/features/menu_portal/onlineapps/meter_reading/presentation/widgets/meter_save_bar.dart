import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Bilah simpan di dasar form. Menampilkan kemajuan pengisian
/// ("2 of 3 meters filled") di atas tombol bila [total] diberikan.
class MeterSaveBar extends StatelessWidget {
  const MeterSaveBar({
    super.key,
    required this.submitting,
    required this.onSave,
    this.filled,
    this.total,
  });

  final bool submitting;
  final VoidCallback onSave;

  /// Jumlah meter yang angkanya sudah diisi, dan jumlah seluruhnya.
  final int? filled;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final showProgress = filled != null && total != null && total! > 0;
    final complete = showProgress && filled == total;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProgress) ...[
                Row(
                  children: [
                    Icon(
                      complete ? Icons.check_circle_rounded : Icons.pending_outlined,
                      size: 16,
                      color: complete ? AppColors.present : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$filled of $total meters filled',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: complete ? AppColors.present : AppColors.textMid,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  onPressed: submitting ? null : onSave,
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.save_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Save Data'),
                          ],
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
