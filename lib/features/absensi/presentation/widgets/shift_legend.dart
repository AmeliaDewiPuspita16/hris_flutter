import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/attendance_day.dart';

/// Baris kecil "A 07-16   B 14-22   C 22-07" — menjelaskan arti kode shift
/// yang muncul di pojok setiap tanggal kalender. Kode diambil otomatis dari
/// [days] (urut alfabet, tanpa duplikat); kalau bulan itu cuma punya 1
/// shift, widget ini tidak menampilkan apa pun.
class ShiftLegend extends StatelessWidget {
  const ShiftLegend({super.key, required this.days});

  final List<AttendanceDay> days;

  Map<String, String> _collectShifts() {
    final map = <String, String>{};
    for (final day in days) {
      final code = day.shiftCode;
      final range = day.shiftTimeRange;
      if (code != null && range != null) map[code] = range;
    }
    final sortedKeys = map.keys.toList()..sort();
    return {for (final k in sortedKeys) k: map[k]!};
  }

  /// "07:00–16:00" -> "07-16", biar ringkas di satu baris.
  String _shortRange(String range) {
    final parts = range.split('–');
    if (parts.length != 2) return range;
    String hourOnly(String hm) => hm.split(':').first;
    return '${hourOnly(parts[0])}-${hourOnly(parts[1])}';
  }

  @override
  Widget build(BuildContext context) {
    final shifts = _collectShifts();
    if (shifts.length < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 14,
        runSpacing: 4,
        children: [
          for (final entry in shifts.entries)
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                children: [
                  TextSpan(
                    text: entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  TextSpan(text: ' ${_shortRange(entry.value)}'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
