import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../absensi/domain/attendance_day.dart';
import '../../../absensi/domain/attendance_month.dart';
import '../../../absensi/presentation/widgets/attendance_calendar.dart';
import '../../../absensi/presentation/widgets/attendance_summary_card.dart';
import '../../../absensi/presentation/widgets/day_detail_panel.dart';
import '../../../absensi/presentation/widgets/month_year_picker_sheet.dart';
import '../../domain/department_attendance_entry.dart';
import '../../domain/employee_attendance_demo_data.dart';
import '../widgets/attendance_month_nav.dart';
import '../widgets/employee_profile_card.dart';

/// Detail kehadiran satu karyawan dalam satu bulan (HOD/Admin, hanya-baca).
///
/// Dibuka dari baris di [DepartmentAttendanceScreen]. Isinya memakai ulang
/// komponen Log Absensi (kartu ringkasan, kalender, panel tanggal, pemilih
/// bulan), tapi kerangka layarnya sendiri: header seperti Department Log,
/// pemilih bulan di dalam kartu kalender, dan tanpa catatan sinkron.
///
/// SEMENTARA: data dari [EmployeeAttendanceDemoData] sampai API kehadiran per
/// karyawan tersedia; gantilah di [_load].
class EmployeeAttendanceDetailScreen extends StatefulWidget {
  const EmployeeAttendanceDetailScreen({
    super.key,
    required this.entry,
    required this.departmentName,
    required this.today,
    this.initialDate,
  });

  final DepartmentAttendanceEntry entry;
  final String departmentName;

  /// Tanggal "hari ini" — bulan terakhir yang boleh dibuka.
  final DateTime today;

  /// Tanggal yang langsung terpilih saat layar dibuka, mis. tanggal yang
  /// sedang dilihat di daftar departemen. Default: mengikuti aturan bulan.
  final DateTime? initialDate;

  @override
  State<EmployeeAttendanceDetailScreen> createState() =>
      _EmployeeAttendanceDetailScreenState();
}

class _EmployeeAttendanceDetailScreenState
    extends State<EmployeeAttendanceDetailScreen> {
  late final DateTime _today = _dateOnly(widget.today);

  /// Batas riwayat yang bisa dibuka: setahun ke belakang sampai bulan ini.
  late final DateTime _firstMonth = DateTime(_today.year - 1, _today.month);
  late final DateTime _lastMonth = DateTime(_today.year, _today.month);

  late DateTime _month = _monthOf(widget.initialDate ?? _today);
  late AttendanceMonth _data = _load(_month);
  late DateTime? _selectedDate = widget.initialDate == null
      ? _defaultSelectedDate()
      : _dateOnly(widget.initialDate!);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);

  AttendanceMonth _load(DateTime month) {
    return EmployeeAttendanceDemoData.month(
      employeeId: widget.entry.id,
      month: month,
      today: _today,
    );
  }

  /// Sama dengan aturan Log Absensi: hari ini bila bulan berjalan; kalau
  /// bukan, tanggal terakhir yang sudah punya realisasi; kalau belum ada,
  /// tanggal 1.
  DateTime _defaultSelectedDate() {
    if (_month == _monthOf(_today)) return _today;
    for (final day in _data.days.reversed) {
      if (day.status != AttendanceDayStatus.terjadwal) return day.date;
    }
    return _data.days.first.date;
  }

  void _goToMonth(DateTime target) {
    final month = _monthOf(target);
    if (month.isBefore(_firstMonth) || month.isAfter(_lastMonth)) return;
    setState(() {
      _month = month;
      _data = _load(month);
      _selectedDate = _defaultSelectedDate();
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showMonthYearPicker(
      context: context,
      initialMonth: _month,
      firstMonth: _firstMonth,
      lastMonth: _lastMonth,
    );
    if (picked != null && mounted) _goToMonth(picked);
  }

  AttendanceDay? get _selectedDay {
    final selected = _selectedDate;
    if (selected == null) return null;
    for (final day in _data.days) {
      if (day.isSameDay(selected)) return day;
    }
    return null;
  }

  bool get _canGoPrevious => _month.isAfter(_firstMonth);
  bool get _canGoNext => _month.isBefore(_lastMonth);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Header hijau naik sampai ke balik status bar, jadi ikonnya terang.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: AppColors.bg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.arrow_back, size: 22, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Detail',
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.departmentName,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        EmployeeProfileCard(entry: widget.entry),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AttendanceMonthNav(
                month: _month,
                onPrevious: _canGoPrevious
                    ? () => _goToMonth(DateTime(_month.year, _month.month - 1))
                    : null,
                onNext: _canGoNext
                    ? () => _goToMonth(DateTime(_month.year, _month.month + 1))
                    : null,
                onPick: _pickMonth,
              ),
              const SizedBox(height: 12),
              AttendanceSummaryCard(summary: _data.summary),
              const SizedBox(height: 16),
              AttendanceCalendar(
                month: _month,
                days: _data.days,
                selectedDate: _selectedDate,
                onDateSelected: (date) =>
                    setState(() => _selectedDate = _dateOnly(date)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: DayDetailPanel(day: _selectedDay),
          ),
        ),
      ],
    );
  }
}
