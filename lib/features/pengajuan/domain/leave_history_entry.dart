import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';

/// satu baris riwayat pengajuan cuti/izin/lembur pada tab status.
class LeaveHistoryEntry {
  const LeaveHistoryEntry({
    required this.id,
    required this.type,
    required this.typeColor,
    required this.typeBackground,
    required this.date,
    required this.status,
    required this.note,
  });

  final String id;
  final String type;
  final Color typeColor;
  final Color typeBackground;
  final String date;
  final AppStatus status;
  final String note;
}
