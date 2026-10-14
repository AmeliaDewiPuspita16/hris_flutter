import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';
import 'overtime_format.dart';

/// Satu PENGAJUAN lembur milik user (beda dari `OvertimeDay`, yang adalah
/// realisasi lembur dari absensi).
class OvertimeRequestEntry {
  const OvertimeRequestEntry({
    required this.id,
    required this.date,
    required this.start,
    required this.end,
    required this.reason,
    required this.status,
    required this.statusLabel,
  });

  final String id;
  final DateTime date;
  final TimeOfDay start;
  final TimeOfDay end;
  final String reason;
  final AppStatus status;

  /// Teks badge (bahasa Inggris), mis. "Pending", "Approved", "Rejected".
  final String statusLabel;

  int get minutes => overtimeMinutesBetween(start, end);

  String get timeRange => '${formatTimeOfDay(start)} – ${formatTimeOfDay(end)}';
}
