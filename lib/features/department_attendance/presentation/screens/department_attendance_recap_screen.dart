import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../absensi/presentation/widgets/month_year_picker_sheet.dart';
import '../../domain/department_attendance_entry.dart';
import '../../domain/department_attendance_recap.dart';
import '../../domain/department_attendance_recap_demo_data.dart';
import '../widgets/attendance_month_nav.dart';
import '../widgets/department_attendance_recap_table.dart';
import '../widgets/recap_sort_chips.dart';
import 'employee_attendance_detail_screen.dart';

/// Rekap kehadiran satu departemen dalam satu bulan (HOD/Admin, hanya-baca).
///
/// Menjawab "siapa yang paling sering telat atau tidak hadir bulan ini?":
/// satu baris per karyawan dengan jumlah Late, Absent, dan Leave, bisa
/// diurutkan. Ketuk baris untuk membuka detail bulan karyawan itu.
///
/// Kolom lembur belum ada karena data contoh belum punya data lembur;
/// tambahkan bersama [DepartmentAttendanceRecapRow] saat API menyediakannya.
///
/// SEMENTARA: data dari [DepartmentAttendanceRecapDemoData] sampai API rekap
/// tersedia; gantilah di [_load].
class DepartmentAttendanceRecapScreen extends StatefulWidget {
  const DepartmentAttendanceRecapScreen({
    super.key,
    required this.departmentName,
    required this.today,
    this.initialDate,
  });

  final String departmentName;

  /// Tanggal "hari ini" — bulan terakhir yang boleh dibuka.
  final DateTime today;

  /// Bulan dari tanggal ini yang dibuka lebih dulu, mis. tanggal yang sedang
  /// dilihat di daftar departemen. Default: bulan ini.
  final DateTime? initialDate;

  @override
  State<DepartmentAttendanceRecapScreen> createState() =>
      _DepartmentAttendanceRecapScreenState();
}

class _DepartmentAttendanceRecapScreenState
    extends State<DepartmentAttendanceRecapScreen> {
  late final DateTime _today = _dateOnly(widget.today);

  /// Batas riwayat yang bisa dibuka: setahun ke belakang sampai bulan ini.
  late final DateTime _firstMonth = DateTime(_today.year - 1, _today.month);
  late final DateTime _lastMonth = DateTime(_today.year, _today.month);

  late DateTime _month = _clampMonth(widget.initialDate ?? _today);
  late DepartmentAttendanceRecap _recap = _load(_month);

  RecapSort _sort = RecapSort.mostLate;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _clampMonth(DateTime d) {
    final month = DateTime(d.year, d.month);
    if (month.isBefore(_firstMonth)) return _firstMonth;
    if (month.isAfter(_lastMonth)) return _lastMonth;
    return month;
  }

  DepartmentAttendanceRecap _load(DateTime month) {
    return DepartmentAttendanceRecapDemoData.forMonth(month, today: _today);
  }

  bool get _isCurrentMonth => _month == _lastMonth;
  bool get _canGoPrevious => _month.isAfter(_firstMonth);
  bool get _canGoNext => _month.isBefore(_lastMonth);

  void _goToMonth(DateTime target) {
    final month = DateTime(target.year, target.month);
    if (month.isBefore(_firstMonth) || month.isAfter(_lastMonth)) return;
    setState(() {
      _month = month;
      _recap = _load(month);
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

  /// Baris tabel setelah diurutkan. Yang seri diurutkan menurut nama.
  List<DepartmentAttendanceRecapRow> get _rows {
    final list = [..._recap.rows];
    list.sort((a, b) {
      final byName = a.entry.name.compareTo(b.entry.name);
      final primary = switch (_sort) {
        RecapSort.mostLate => b.lateCount.compareTo(a.lateCount),
        RecapSort.mostAbsent => b.absentCount.compareTo(a.absentCount),
        RecapSort.name => 0,
      };
      return primary != 0 ? primary : byName;
    });
    return list;
  }

  /// Tanggal yang langsung terpilih di layar detail: hari ini untuk bulan
  /// berjalan; bulan lampau → hari kerja terakhir bulan itu.
  DateTime _detailDateFor(DateTime month) {
    if (month == _lastMonth) return _today;
    var d = DateTime(month.year, month.month + 1, 0);
    while (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
      d = d.subtract(const Duration(days: 1));
    }
    return d;
  }

  void _openEmployee(DepartmentAttendanceEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeAttendanceDetailScreen(
          entry: entry,
          departmentName: widget.departmentName,
          today: _today,
          initialDate: _detailDateFor(_month),
        ),
      ),
    );
  }

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
    final days = _recap.workingDays;
    final dayLabel = '$days working ${days == 1 ? 'day' : 'days'}'
        '${_isCurrentMonth ? ' so far' : ''}';

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
                  'Monthly Recap',
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.departmentName} · $dayLabel',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
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
    final rows = _rows;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AttendanceMonthNav(
            month: _month,
            onPrevious: _canGoPrevious
                ? () => _goToMonth(DateTime(_month.year, _month.month - 1))
                : null,
            onNext: _canGoNext
                ? () => _goToMonth(DateTime(_month.year, _month.month + 1))
                : null,
            onPick: _pickMonth,
          ),
        ),
        const SizedBox(height: 12),
        RecapSortChips(
          selected: _sort,
          onSelected: (sort) => setState(() => _sort = sort),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          _buildEmpty()
        else ...[
          DepartmentAttendanceRecapTable(rows: rows, onTapRow: _openEmployee),
          const SizedBox(height: 10),
          Text(
            "Tap a name to open that person's month",
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Center(
        child: Text(
          'Belum ada data kehadiran pada bulan ini.',
          style: AppTextStyles.bodyMuted,
        ),
      ),
    );
  }
}
