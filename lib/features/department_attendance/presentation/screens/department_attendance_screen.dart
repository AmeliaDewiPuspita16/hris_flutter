import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/department_attendance_demo_data.dart';
import '../../domain/department_attendance_entry.dart';
import '../../domain/department_attendance_status.dart';
import '../widgets/attendance_date_bar.dart';
import '../widgets/attendance_status_chips.dart';
import '../widgets/department_attendance_row.dart';
import 'employee_attendance_detail_screen.dart';

/// Layar utama Department Attendance Log (HOD/Admin, hanya-baca).
///
/// Pertanyaan yang dijawab: "hari ini siapa yang masuk, siapa yang bermasalah?"
/// — jadi layar langsung menampilkan hari ini per orang, dengan yang butuh
/// perhatian (belum check-in, terlambat) di atas. Ketuk satu karyawan untuk
/// detail bulannya; rekap bulanan menyusul sebagai layar terpisah.
///
/// SEMENTARA: data dari [DepartmentAttendanceDemoData] sampai API kehadiran
/// per departemen tersedia; pemanggilnya nanti diganti di [_loadEntries].
class DepartmentAttendanceScreen extends StatefulWidget {
  const DepartmentAttendanceScreen({
    super.key,
    this.departmentName = DepartmentAttendanceDemoData.departmentName,
    this.now,
  });

  final String departmentName;

  /// Untuk test: menyuntikkan tanggal "hari ini". Default [DateTime.now].
  final DateTime? now;

  @override
  State<DepartmentAttendanceScreen> createState() =>
      _DepartmentAttendanceScreenState();
}

class _DepartmentAttendanceScreenState
    extends State<DepartmentAttendanceScreen> {
  final _searchController = TextEditingController();

  late final DateTime _today = _dateOnly(widget.now ?? DateTime.now());
  late DateTime _date = _today;
  late List<DepartmentAttendanceEntry> _entries = _loadEntries(_date);

  DepartmentAttendanceStatus? _filter;
  String _query = '';

  bool get _isToday => _date == _today;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Batas riwayat yang bisa dibuka: setahun ke belakang.
  DateTime get _firstDate =>
      DateTime(_today.year - 1, _today.month, _today.day);

  List<DepartmentAttendanceEntry> _loadEntries(DateTime date) {
    return DepartmentAttendanceDemoData.forDate(date, today: _today);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goTo(DateTime date) {
    final target = _dateOnly(date);
    if (target.isAfter(_today) || target.isBefore(_firstDate)) return;
    setState(() {
      _date = target;
      _entries = _loadEntries(target);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _firstDate,
      lastDate: _today,
    );
    if (picked != null && mounted) _goTo(picked);
  }

  Map<DepartmentAttendanceStatus, int> get _counts {
    final counts = {for (final s in DepartmentAttendanceStatus.values) s: 0};
    for (final e in _entries) {
      counts[e.status] = counts[e.status]! + 1;
    }
    return counts;
  }

  /// Daftar setelah filter status + pencarian nama, dengan urutan: status
  /// bermasalah dulu, lalu nama.
  List<DepartmentAttendanceEntry> get _visible {
    final query = _query.trim().toLowerCase();
    final list = _entries.where((e) {
      final matchesStatus = _filter == null || e.status == _filter;
      final matchesQuery = query.isEmpty || e.name.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();

    list.sort((a, b) {
      final byStatus = a.status.index.compareTo(b.status.index);
      return byStatus != 0 ? byStatus : a.name.compareTo(b.name);
    });
    return list;
  }

  void _openDetail(DepartmentAttendanceEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeAttendanceDetailScreen(
          entry: entry,
          departmentName: widget.departmentName,
          today: _today,
          // Langsung buka di tanggal yang sedang dilihat di daftar.
          initialDate: _date,
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
        backgroundColor: AppColors.bg,
        body: ColoredBox(
          // Strip status bar memakai warna header, bukan warna halaman.
          color: AppColors.primary,
          child: SafeArea(
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
      ),
    );
  }

  Widget _buildHeader() {
    final subtitle = _entries.isEmpty
        ? widget.departmentName
        : '${widget.departmentName} · ${_entries.length} employees';

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
                  'Department Log',
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    final visible = _visible;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        AttendanceDateBar(
          date: _date,
          isToday: _isToday,
          onPrevious: () => _goTo(_date.subtract(const Duration(days: 1))),
          onNext: () => _goTo(_date.add(const Duration(days: 1))),
          onPickDate: _pickDate,
        ),
        const SizedBox(height: 10),
        AttendanceStatusChips(
          counts: _counts,
          selected: _filter,
          isToday: _isToday,
          onSelected: (status) => setState(() => _filter = status),
        ),
        const SizedBox(height: 10),
        _buildSearchField(),
        const SizedBox(height: 10),
        if (visible.isEmpty) _buildEmpty() else _buildList(visible),
      ],
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        style: const TextStyle(fontSize: 13, color: AppColors.text),
        decoration: InputDecoration(
          hintText: 'Search name',
          hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          prefixIcon:
              const Icon(Icons.search, size: 18, color: AppColors.textMuted),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<DepartmentAttendanceEntry> visible) {
    return AppCard(
      // Klip supaya riak InkWell baris pertama/terakhir ikut sudut kartu.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              DepartmentAttendanceRow(
                entry: visible[i],
                isToday: _isToday,
                onTap: () => _openDetail(visible[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    // Daftar kosong dari sumbernya = tidak ada jadwal (akhir pekan); kosong
    // setelah disaring = tidak ada yang cocok dengan filter/pencarian.
    final message = _entries.isEmpty
        ? 'Tidak ada jadwal kerja pada tanggal ini.'
        : 'Tidak ada karyawan yang cocok.';

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Center(child: Text(message, style: AppTextStyles.bodyMuted)),
    );
  }
}
