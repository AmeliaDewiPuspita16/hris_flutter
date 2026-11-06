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
    required this.crossesMidnight,
    required this.durationHours,
    required this.reason,
    required this.status,
    required this.statusLabel,
  });

  /// Memetakan satu item `data` dari `GET .../hris/overtime/request`.
  factory OvertimeRequestEntry.fromJson(Map<String, dynamic> json) {
    return OvertimeRequestEntry(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      start: _parseTime(json['start_time']),
      end: _parseTime(json['end_time']),
      crossesMidnight: json['crosses_midnight'] == true,
      durationHours: (json['duration_hours'] as num?)?.toDouble(),
      reason: json['reason'] as String? ?? '',
      status: _statusFor(json['status_code']),
      statusLabel: json['status_label'] as String? ?? 'Unknown',
    );
  }

  final String id;
  final DateTime? date;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final bool crossesMidnight;

  /// Jam lembur yang diajukan. Sering lebih kecil dari selisih [start]-[end]
  /// karena tidak dihitung otomatis dari jam mulai dan selesai.
  final double? durationHours;
  final String reason;
  final AppStatus status;

  /// Teks badge (bahasa Inggris), mis. "Pending", "Approved".
  final String statusLabel;

  String get timeRange {
    final from = start;
    final to = end;
    if (from == null || to == null) return '-';

    final range = '${formatTimeOfDay(from)} – ${formatTimeOfDay(to)}';
    return crossesMidnight ? '$range (+1 day)' : range;
  }

  /// CO = sudah disetujui, OEZ_RELEASE = menunggu. Kode penolakan belum pernah
  /// teramati di HRIS, jadi kode lain tampil netral, bukan ditebak "Rejected".
  static AppStatus _statusFor(Object? code) => switch (code) {
        'CO' => AppStatus.present,
        'OEZ_RELEASE' => AppStatus.pending,
        _ => AppStatus.neutral,
      };

  static TimeOfDay? _parseTime(Object? value) {
    if (value is! String) return null;

    final parts = value.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    return hour == null || minute == null
        ? null
        : TimeOfDay(hour: hour, minute: minute);
  }
}
