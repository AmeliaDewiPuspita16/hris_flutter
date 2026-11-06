import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'overtime_format.dart';

/// Isi form tab Submit, siap dikirim ke `POST .../hris/overtime/request`.
class OvertimeSubmission {
  const OvertimeSubmission({
    required this.date,
    required this.start,
    required this.end,
    required this.durationHours,
    required this.reason,
  });

  final DateTime date;
  final TimeOfDay start;
  final TimeOfDay end;
  final double durationHours;
  final String reason;

  Map<String, dynamic> toJson() => {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'start_time': formatTimeOfDay(start),
        'end_time': formatTimeOfDay(end),
        'duration_hours': durationHours,
        'reason': reason,
      };
}
