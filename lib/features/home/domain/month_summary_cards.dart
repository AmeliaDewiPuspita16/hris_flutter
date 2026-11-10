import '../../../core/widgets/status_badge.dart';
import '../../absensi/domain/attendance_day.dart';
import '../../absensi/domain/attendance_month.dart';
import '../../pengajuan/domain/leave_history_entry.dart';
import 'quota_balance.dart';

/// Kartu ringkasan "This month" di Beranda, disusun dari data HRIS yang
/// sudah ada (sumber yang sama dengan Log Absensi dan tab Status Pengajuan).
///
/// Menggantikan kartu saldo demo (Annual Leave, Medical Check, ...) selama
/// HRIS belum punya endpoint saldo cuti — lihat `LeaveBalance`.
class MonthSummaryCards {
  const MonthSummaryCards._();

  /// [attendance] null = absensi bulan ini gagal dimuat, kartu Attendance,
  /// Late, dan Overtime dilewati. [leaveHistory] null = riwayat cuti gagal
  /// dimuat, kartu Leave Requests dilewati.
  static List<QuotaBalance> build({
    AttendanceMonth? attendance,
    List<LeaveHistoryEntry>? leaveHistory,
    required DateTime now,
  }) {
    return [
      if (attendance != null) ..._attendanceCards(attendance),
      if (leaveHistory != null) _leaveCard(leaveHistory, now),
    ];
  }

  static List<QuotaBalance> _attendanceCards(AttendanceMonth month) {
    final present = month.summary.present;
    final scheduled = scheduledWorkDays(month.days);
    final overtimeDays = month.days.where((d) => d.hasOvertime).length;

    return [
      QuotaBalance(
        label: 'Attendance',
        value: present.toDouble(),
        // Tanpa jadwal shift (mis. endpoint shift gagal), jumlah hari kerja
        // tidak diketahui: kartu tetap tampil, hanya tanpa pembanding.
        total: scheduled > 0 ? scheduled.toDouble() : null,
        caption: scheduled > 0 ? '/ $scheduled days' : 'days present',
        fractionDigits: 0,
      ),
      QuotaBalance(
        label: 'Late',
        value: month.summary.late.toDouble(),
        // Setengah lebar di samping Attendance, tanpa progress bar: bar yang
        // "terisi" untuk keterlambatan malah terbaca seperti pencapaian.
        total: present.toDouble(),
        showProgress: false,
        caption: month.summary.late == 1 ? 'day' : 'days',
        fractionDigits: 0,
      ),
      QuotaBalance(
        label: 'Overtime',
        value: month.summary.overtimeHrs,
        caption: 'hrs',
        note: overtimeDays == 0
            ? 'no overtime yet'
            : 'across $overtimeDays ${overtimeDays == 1 ? 'day' : 'days'}',
      ),
    ];
  }

  /// Hari kerja terjadwal sebulan penuh: tanggal yang shift-nya diketahui
  /// atau sudah ada realisasinya, selain hari libur/off.
  static int scheduledWorkDays(List<AttendanceDay> days) => days
      .where((d) =>
          d.status != AttendanceDayStatus.liburHari &&
          (d.shiftCode != null || !d.isScheduledOnly))
      .length;

  static QuotaBalance _leaveCard(List<LeaveHistoryEntry> history, DateTime now) {
    final pending =
        history.where((e) => e.status == AppStatus.pending).length;
    final approvedThisYear = history
        .where((e) =>
            e.status == AppStatus.present && e.requestDate.year == now.year)
        .length;

    return QuotaBalance(
      label: 'Leave Requests',
      value: pending.toDouble(),
      caption: 'pending',
      note: '$approvedThisYear approved this year',
      fractionDigits: 0,
    );
  }
}
