import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/attendance_entry.dart';

/// Log Absensi — READ ONLY.
/// Absen tetap dilakukan lewat mesin fingerprint di kantor, sistem itu
/// sudah tersambung ke HRIS web. Layar ini cuma menampilkan hasil sync-nya,
/// jadi TIDAK ada tombol check-in/check-out di mobile.
class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({super.key});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  static const _bulanIndonesia = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static final _firstSelectableMonth = DateTime(2023, 1);
  static final _lastSelectableMonth = DateTime(DateTime.now().year + 1, 12);

  // dummy — nanti diganti state bulan aktif dari query ke backend.
  DateTime _selectedMonth = DateTime(2026, 9);

  static const _entries = AttendanceEntry.dummySeptember2026;

  // dummy ringkasan bulan ini (nanti dihitung dari _entries / response API).
  static const _totalPresent = 20;
  static const _totalLate = 1;
  static const _totalOvertimeHrs = 18;

  String get _monthLabel =>
      '${_bulanIndonesia[_selectedMonth.month - 1]} ${_selectedMonth.year}';

  void _shiftMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    // dummy — di sini nanti refetch _entries buat bulan barunya.
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: _firstSelectableMonth,
      lastDate: _lastSelectableMonth,
      monthPickerDialogSettings: const MonthPickerDialogSettings(
        dialogSettings: PickerDialogSettings(
          dialogRoundedCornersRadius: 16,
          dialogBackgroundColor: AppColors.card,
        ),
        headerSettings: PickerHeaderSettings(
          headerBackgroundColor: AppColors.primary,
          headerIconsColor: Colors.white,
          headerCurrentPageTextStyle: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          headerSelectedIntervalTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        dateButtonsSettings: PickerDateButtonsSettings(
          selectedMonthBackgroundColor: AppColors.primary,
          selectedMonthTextColor: Colors.white,
          unselectedMonthsTextColor: AppColors.text,
          currentMonthTextColor: AppColors.primary,
        ),
        actionBarSettings: PickerActionBarSettings(
          confirmWidget: Text('Pilih', style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          )),
          cancelWidget: Text('Batal', style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          )),
        ),
      ),
    );

    if (picked != null) {
      setState(() => _selectedMonth = picked);
      // dummy — di sini nanti refetch _entries buat bulan barunya.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Strip status bar memakai warna header (putih), bukan warna halaman —
    // kalau tidak, ada garis beda warna tepat di atas header.
    return ColoredBox(
      color: AppColors.card,
      child: SafeArea(
        child: ColoredBox(
          color: AppColors.bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _SummaryCard(
                      present: _totalPresent,
                      late: _totalLate,
                      overtimeHrs: _totalOvertimeHrs,
                    ),
                    const SizedBox(height: 16),
                    ..._entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AttendanceRow(entry: e),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _SyncFootnote(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('Log Absensi', style: AppTextStyles.h2),
          ),
          Row(
            children: [
              InkWell(
                onTap: () => _shiftMonth(-1),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_left,
                      size: 18, color: AppColors.textMuted),
                ),
              ),
              InkWell(
                onTap: () => _pickMonth(context),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Text(
                    _monthLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () => _shiftMonth(1),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_right,
                      size: 18, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.present,
    required this.late,
    required this.overtimeHrs,
  });

  final int present;
  final int late;
  final int overtimeHrs;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
                value: '$present', label: 'Hadir', color: AppColors.text),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatColumn(
                value: '$late', label: 'Terlambat', color: AppColors.rejected),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatColumn(
                value: '$overtimeHrs',
                label: 'Jam Lembur',
                color: AppColors.text),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn(
      {required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.border);
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.entry});

  final AttendanceEntry entry;

  ({Color fg, Color bg, String label})? get _badge {
    switch (entry.status) {
      case AttendanceStatus.tepatWaktu:
        return (
          fg: AppColors.present,
          bg: AppColors.presentBg,
          label: 'TEPAT WAKTU'
        );
      case AttendanceStatus.lembur:
        return (
          fg: AppColors.present,
          bg: AppColors.presentBg,
          label: 'LBR 4,5J'
        );
      case AttendanceStatus.terlambat:
        return (
          fg: AppColors.rejected,
          bg: AppColors.rejectedBg,
          label: 'TELAT 14M'
        );
      case AttendanceStatus.liburHari:
        return (fg: AppColors.neutral, bg: AppColors.neutralBg, label: 'LIBUR');
      case AttendanceStatus.berlangsung:
        // hari berjalan, belum ada hasil final — tanpa badge.
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final isOngoing = entry.status == AttendanceStatus.berlangsung;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Text(entry.day,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text)),
                const SizedBox(height: 1),
                Text(entry.weekday,
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.primaryText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isOngoing ? AppColors.pending : AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(entry.secondaryText,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badge.bg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge.label,
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: badge.fg,
                      letterSpacing: 0.2)),
            ),
        ],
      ),
    );
  }
}

class _SyncFootnote extends StatelessWidget {
  const _SyncFootnote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 13, color: AppColors.textMuted),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Data tercatat otomatis dari mesin fingerprint kantor dan tersinkron dari HRIS web. Absensi tidak dilakukan lewat aplikasi ini.',
              style: TextStyle(
                  fontSize: 10.5, color: AppColors.textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
