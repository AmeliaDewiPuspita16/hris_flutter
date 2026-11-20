import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/meter_approval_status.dart';
import '../../domain/meter_reading.dart';
import '../../domain/meter_record_action.dart';

/// Bar aksi di dasar layar detail. Tombol dan teksnya mengikuti `action` dari
/// server — tidak ada logika izin sendiri:
///
/// - `record` / `edit` / `new_reading` (dan user boleh menulis): tombol aksi.
/// - tidak ada aksi: keterangan singkat mengapa (tidak ada periode aktif,
///   sudah approved, atau sudah dicatat).
/// - user tanpa hak tulis: tidak ada bar sama sekali.
class MeterRecordBar extends StatelessWidget {
  const MeterRecordBar({
    super.key,
    required this.reading,
    required this.onAction,
  });

  final MeterReading reading;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final content = _content();
    if (content == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(height: 50, child: content),
        ),
      ),
    );
  }

  Widget? _content() {
    if (reading.canRecord) return _button();
    if (!reading.canWrite) return null;
    if (!reading.hasActivePeriod) {
      return _note(Icons.event_busy_outlined, 'No active reading period');
    }
    if (reading.approval == MeterApprovalStatus.approved) {
      return _note(Icons.verified_outlined, 'Approved · view only');
    }
    if (reading.recordedInActivePeriod) {
      return _note(Icons.check_circle_outline_rounded, 'Already recorded this period');
    }
    return null;
  }

  Widget _button() {
    final icon = reading.action == MeterRecordAction.newReading
        ? Icons.add_circle_outline_rounded
        : Icons.edit_note_rounded;

    return FilledButton.icon(
      onPressed: onAction,
      icon: Icon(icon, size: 22),
      label: Text(reading.action.buttonLabel),
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

  Widget _note(IconData icon, String text) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.textMid),
          const SizedBox(width: 8),
          Text(
            text,
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
