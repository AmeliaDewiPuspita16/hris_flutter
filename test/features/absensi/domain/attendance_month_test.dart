import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/absensi/domain/attendance_day.dart';
import 'package:hris_mobile/features/absensi/domain/attendance_month.dart';

/// Oktober 2026: tanggal 30 Jumat, 31 Sabtu.
void main() {
  final october = DateTime(2026, 10);

  Map<String, dynamic> record(
    String date, {
    required String shift,
    String checkIn = '08:59:00',
    String? checkOut = '18:07:00',
  }) =>
      {
        'date': date,
        'status': 'present',
        'shift': shift,
        'checkin': '${date}T$checkIn',
        'checkout': checkOut == null ? null : '${date}T$checkOut',
      };

  AttendanceMonth build(
    List<Map<String, dynamic>> days, {
    Map<String, dynamic>? overtime,
  }) =>
      AttendanceMonth.fromJson(
        {
          'days': days,
          'summary': {'present_days': days.length, 'late_days': 0},
        },
        month: october,
        overtime: overtime,
      );

  AttendanceDay dayOf(AttendanceMonth month, int d) =>
      month.days.firstWhere((x) => x.date.day == d);

  group('shift N di akhir pekan', () {
    test('Sabtu dengan shift N dihitung lembur, bukan terlambat', () {
      final month = build([
        record('2026-10-31', shift: 'N (08:00-17:00)'),
      ]);
      final day = dayOf(month, 31);

      expect(day.status, AttendanceDayStatus.lembur);
      expect(day.badgeLabel, isNull);
      // 08:59 – 18:07 = 9 jam 8 menit.
      expect(day.overtimeMinutes, 9 * 60 + 8);
      expect(month.summary.late, 0);
      expect(month.summary.overtimeHrs, closeTo(548 / 60, 0.001));
    });

    test('Minggu dengan shift N juga lembur', () {
      final month = build([
        record('2026-10-25', shift: 'N (08:00-17:00)', checkIn: '07:50:00'),
      ]);

      expect(dayOf(month, 25).status, AttendanceDayStatus.lembur);
    });

    test('lama lembur dari endpoint overtime diutamakan, tidak dihitung dua kali',
        () {
      final month = build(
        [record('2026-10-31', shift: 'N (08:00-17:00)')],
        overtime: {
          'days': [
            {'date': '2026-10-31', 'overtime_minutes': 240},
          ],
          'summary': {'total_overtime_hours': 4},
        },
      );

      expect(dayOf(month, 31).overtimeMinutes, 240);
      expect(month.summary.overtimeHrs, 4);
    });

    test('Jumat dengan shift N tetap dihitung terlambat', () {
      final month = build([
        record('2026-10-30', shift: 'N (08:00-17:00)'),
      ]);
      final day = dayOf(month, 30);

      expect(day.status, AttendanceDayStatus.terlambat);
      expect(day.badgeLabel, 'Late 59m');
      expect(month.summary.late, 1);
    });

    test('shift selain N di Sabtu tetap memakai aturan terlambat', () {
      final month = build([
        record('2026-10-31', shift: 'A (07:00-15:00)', checkIn: '07:30:00'),
      ]);

      expect(dayOf(month, 31).status, AttendanceDayStatus.terlambat);
      expect(month.summary.late, 1);
    });
  });
}
