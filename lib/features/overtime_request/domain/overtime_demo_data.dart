import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';
import 'overtime_day.dart';
import 'overtime_request_entry.dart';

/// Data dummy untuk membangun tampilan Overtime Request lebih dulu.
/// Dibuat relatif ke bulan ini supaya selalu ada isi di Summary.
///
/// Ganti dengan repository + bloc saat endpoint tersambung:
/// - [days]     → `GET /api/portal/apps/hris/overtime` (realisasi)
/// - [requests] → endpoint pengajuan lembur (belum ada)
class OvertimeDemoData {
  OvertimeDemoData._();

  static const _shift = 'N (08:00–17:00)';

  static List<OvertimeDay> days() {
    final now = DateTime.now();

    OvertimeDay day(int d, int inH, int inM, int outH, int outM, int minutes) {
      return OvertimeDay(
        date: DateTime(now.year, now.month, d),
        minutes: minutes,
        checkIn: DateTime(now.year, now.month, d, inH, inM),
        checkOut: DateTime(now.year, now.month, d, outH, outM),
        shift: _shift,
      );
    }

    return [
      day(3, 7, 52, 18, 30, 90),
      day(5, 8, 0, 18, 0, 60),
      day(10, 8, 5, 19, 0, 120),
    ];
  }

  static List<OvertimeRequestEntry> requests() {
    final now = DateTime.now();

    return [
      OvertimeRequestEntry(
        id: 'OT-1',
        date: DateTime(now.year, now.month, 10),
        start: const TimeOfDay(hour: 17, minute: 0),
        end: const TimeOfDay(hour: 19, minute: 0),
        reason: 'Finishing the monthly report',
        status: AppStatus.pending,
        statusLabel: 'Pending',
      ),
      OvertimeRequestEntry(
        id: 'OT-2',
        date: DateTime(now.year, now.month, 3),
        start: const TimeOfDay(hour: 17, minute: 0),
        end: const TimeOfDay(hour: 18, minute: 30),
        reason: 'Server maintenance support',
        status: AppStatus.present,
        statusLabel: 'Approved',
      ),
      OvertimeRequestEntry(
        id: 'OT-3',
        date: DateTime(now.year, now.month - 1, 24),
        start: const TimeOfDay(hour: 17, minute: 0),
        end: const TimeOfDay(hour: 21, minute: 0),
        reason: 'Stock opname',
        status: AppStatus.rejected,
        statusLabel: 'Rejected',
      ),
    ];
  }
}
