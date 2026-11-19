import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/meter_reading_state.dart';

/// Bar aksi di dasar layar detail.
///
/// - [canRecord] true: tombol "Record New Data".
/// - sudah tercatat: keterangan "Already recorded this period".
/// - selain itu (mis. tidak berhak mencatat): tidak ada bar sama sekali.
class MeterRecordBar extends StatelessWidget {
  const MeterRecordBar({
    super.key,
    required this.state,
    required this.canRecord,
    required this.onRecord,
  });

  final MeterReadingState state;
  final bool canRecord;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final recorded = state == MeterReadingState.recorded;
    if (!canRecord && !recorded) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            height: 50,
            child: canRecord ? _button() : _recordedNote(),
          ),
        ),
      ),
    );
  }

  Widget _button() {
    return FilledButton.icon(
      onPressed: onRecord,
      icon: const Icon(Icons.edit_note_rounded, size: 22),
      label: const Text('Record New Data'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _recordedNote() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.textMid),
          const SizedBox(width: 8),
          Text(
            'Already recorded this period',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMid,
            ),
          ),
        ],
      ),
    );
  }
}
