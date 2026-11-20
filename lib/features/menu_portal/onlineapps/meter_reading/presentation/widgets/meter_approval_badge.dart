import 'package:material_ui/material_ui.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/meter_approval_status.dart';
import '../../domain/meter_reading_summary.dart';
import 'meter_reading_state_badge.dart';

/// Pil kecil status persetujuan: Pending / Approved / Rejected.
class MeterApprovalBadge extends StatelessWidget {
  const MeterApprovalBadge({super.key, required this.status});

  final MeterApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu badge yang paling berguna bagi petugas untuk sebuah record:
///
/// - Rejected selalu tampil (perlu tindakan),
/// - belum dicatat di periode aktif -> "Not recorded",
/// - selain itu status persetujuannya (Pending / Approved).
class MeterStatusBadge extends StatelessWidget {
  const MeterStatusBadge({super.key, required this.reading});

  final MeterReadingSummary reading;

  @override
  Widget build(BuildContext context) {
    if (reading.approval == MeterApprovalStatus.rejected) {
      return const MeterApprovalBadge(status: MeterApprovalStatus.rejected);
    }
    if (!reading.recordedInActivePeriod) {
      return MeterReadingStateBadge(state: reading.state);
    }
    return MeterApprovalBadge(status: reading.approval);
  }
}
