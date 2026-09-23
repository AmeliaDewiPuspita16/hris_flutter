import 'package:flutter/material.dart';

import 'duration_type.dart';
import 'leave_type.dart';

/// Data pengajuan yang sudah diisi user di tab Ajukan, siap dikirim ke
/// `PengajuanRepository.submitLeaveRequest`.
///
/// Field yang terisi berbeda-beda tergantung [leaveType] — lihat
/// `_AjukanTabState._buildDynamicFields`. Validasi kelengkapan field masih
/// dikerjakan tombol submit di form (belum ada di sini); begitu endpoint
/// sungguhan tersedia, validasi server jadi sumber kebenaran terakhir.
class LeaveRequestDraft {
  const LeaveRequestDraft({
    required this.leaveType,
    this.izinCategory,
    this.durationType = DurationType.full,
    this.startDate,
    this.endDate,
    this.date,
    this.startTime,
    this.endTime,
    this.reason,
    this.attachmentFileName,
  });

  final LeaveType leaveType;
  final LeaveCategory? izinCategory;
  final DurationType durationType;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? reason;
  final String? attachmentFileName;
}
