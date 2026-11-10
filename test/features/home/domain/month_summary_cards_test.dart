import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/absensi/domain/attendance_day.dart';
import 'package:hris_mobile/features/absensi/domain/attendance_month.dart';
import 'package:hris_mobile/features/absensi/domain/attendance_summary.dart';
import 'package:hris_mobile/features/home/domain/month_summary_cards.dart';
import 'package:hris_mobile/features/home/domain/quota_balance.dart';
import 'package:hris_mobile/features/pengajuan/domain/leave_history_entry.dart';

void main() {
  final now = DateTime(2026, 11, 10);

  AttendanceDay day(
    int d,
    AttendanceDayStatus status, {
    String? shift = 'N',
    int overtimeMinutes = 0,
  }) =>
      AttendanceDay(
        date: DateTime(2026, 11, d),
        status: status,
        shiftCode: shift,
        overtimeMinutes: overtimeMinutes,
      );

  AttendanceMonth month({
    List<AttendanceDay>? days,
    int present = 7,
    int late = 1,
    double overtimeHrs = 6.5,
  }) =>
      AttendanceMonth(
        days: days ??
            [
              day(1, AttendanceDayStatus.liburHari, shift: null),
              day(2, AttendanceDayStatus.tepatWaktu, overtimeMinutes: 120),
              day(3, AttendanceDayStatus.terlambat),
              day(4, AttendanceDayStatus.lembur, overtimeMinutes: 270),
              day(5, AttendanceDayStatus.terjadwal),
              // Tanpa jadwal maupun realisasi: tidak dihitung hari kerja.
              day(6, AttendanceDayStatus.terjadwal, shift: null),
            ],
        summary: AttendanceSummary(
          present: present,
          late: late,
          overtimeHrs: overtimeHrs,
        ),
      );

  LeaveHistoryEntry leave(String start, String statusCode) =>
      LeaveHistoryEntry.fromApi(
        {'start_date': start, 'type': 'Annual Leave', 'status_code': statusCode},
        index: 0,
      )!;

  QuotaBalance card(List<QuotaBalance> cards, String label) =>
      cards.singleWhere((c) => c.label == label);

  test('Attendance: hadir dari server, dibanding hari kerja terjadwal', () {
    final cards = MonthSummaryCards.build(attendance: month(), now: now);
    final attendance = card(cards, 'Attendance');

    // Hari 2-5 terjadwal/realisasi; hari 1 libur, hari 6 tanpa jadwal.
    expect(attendance.total, 4);
    expect(attendance.formattedValue, '7');
    expect(attendance.caption, '/ 4 days');
    expect(attendance.isWide, isFalse);
  });

  test('Attendance tanpa jadwal shift tampil lebar tanpa pembanding', () {
    final cards = MonthSummaryCards.build(
      attendance: month(days: [day(2, AttendanceDayStatus.terjadwal, shift: null)]),
      now: now,
    );
    final attendance = card(cards, 'Attendance');

    expect(attendance.total, isNull);
    expect(attendance.caption, 'days present');
  });

  test('Late setengah lebar tanpa progress bar', () {
    final late = card(
      MonthSummaryCards.build(attendance: month(), now: now),
      'Late',
    );

    expect(late.isWide, isFalse);
    expect(late.progress, isNull);
    expect(late.caption, 'day');
  });

  test('Overtime: jam dari ringkasan, jumlah hari dari kalender', () {
    final overtime = card(
      MonthSummaryCards.build(attendance: month(), now: now),
      'Overtime',
    );

    expect(overtime.formattedValue, '6.5');
    expect(overtime.note, 'across 2 days');
    expect(overtime.isWide, isTrue);
  });

  test('Overtime kosong diberi keterangan', () {
    final overtime = card(
      MonthSummaryCards.build(
        attendance: month(
          days: [day(2, AttendanceDayStatus.tepatWaktu)],
          overtimeHrs: 0,
        ),
        now: now,
      ),
      'Overtime',
    );

    expect(overtime.note, 'no overtime yet');
  });

  test('Leave Requests: pending semua, approved hanya tahun ini', () {
    final leaveCard = card(
      MonthSummaryCards.build(
        leaveHistory: [
          leave('2026-11-20', 'OEZ_RELEASE'),
          leave('2026-03-02', 'CO'),
          leave('2026-07-14', 'CO'),
          leave('2025-12-29', 'CO'),
          leave('2026-08-01', 'DR'),
        ],
        now: now,
      ),
      'Leave Requests',
    );

    expect(leaveCard.formattedValue, '1');
    expect(leaveCard.note, '2 approved this year');
  });

  test('sumber yang gagal dimuat dilewati', () {
    expect(
      MonthSummaryCards.build(leaveHistory: const [], now: now)
          .map((c) => c.label),
      ['Leave Requests'],
    );
    expect(
      MonthSummaryCards.build(attendance: month(), now: now)
          .map((c) => c.label),
      ['Attendance', 'Late', 'Overtime'],
    );
    expect(MonthSummaryCards.build(now: now), isEmpty);
  });
}
