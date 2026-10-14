import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';
import 'overtime_request_entry.dart';

/// Data dummy pengajuan lembur untuk tab Submit/Status.
///
/// Realisasi lembur (tab Summary) sudah dari API lewat `OvertimeRepository`.
/// [requests] diganti repository + bloc setelah endpoint pengajuan lembur
/// tersedia (belum ada).
class OvertimeDemoData {
  OvertimeDemoData._();

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
