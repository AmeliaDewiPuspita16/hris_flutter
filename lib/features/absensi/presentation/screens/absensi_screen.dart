import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/absensi_repository.dart';
import '../bloc/absensi_bloc.dart';
import '../bloc/absensi_event.dart';
import '../bloc/absensi_state.dart';
import '../widgets/attendance_calendar.dart';
import '../widgets/attendance_summary_card.dart';
import '../widgets/day_detail_panel.dart';
import '../widgets/month_year_picker_sheet.dart';
import '../widgets/sync_footnote.dart';

/// Log Absensi — READ ONLY.
/// Absen tetap dilakukan lewat mesin fingerprint di kantor, sistem itu
/// sudah tersambung ke HRIS web. Layar ini cuma menampilkan hasil sync-nya,
/// jadi TIDAK ada tombol check-in/check-out di mobile.
class AbsensiScreen extends StatelessWidget {
  const AbsensiScreen({super.key, this.repository});

  /// Diisi test; di aplikasi dibuat langsung dari [ApiClient] lokal — lihat
  /// catatan di [AbsensiRepository] soal kenapa belum didaftarkan di
  /// main.dart (masih dummy, API HRIS belum tersedia).
  final AbsensiRepository? repository;

  @override
  Widget build(BuildContext context) {
    final absensi = repository ?? AbsensiRepository(apiClient: ApiClient());

    return BlocProvider(
      create: (_) => AbsensiBloc(repository: absensi)..add(const AbsensiStarted()),
      child: const _AbsensiView(),
    );
  }
}

class _AbsensiView extends StatelessWidget {
  const _AbsensiView();

  static const _bulanIndonesia = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static final _firstSelectableMonth = DateTime(2023, 1);
  static final _lastSelectableMonth = DateTime(DateTime.now().year + 1, 12);

  String _monthLabel(DateTime month) =>
      '${_bulanIndonesia[month.month - 1]} ${month.year}';

  void _shiftMonth(BuildContext context, DateTime current, int delta) {
    context.read<AbsensiBloc>().add(
          AbsensiMonthChanged(DateTime(current.year, current.month + delta)),
        );
  }

  Future<void> _pickMonth(BuildContext context, DateTime current) async {
    final picked = await showMonthYearPicker(
      context: context,
      initialMonth: current,
      firstMonth: _firstSelectableMonth,
      lastMonth: _lastSelectableMonth,
    );

    if (picked != null && context.mounted) {
      context.read<AbsensiBloc>().add(AbsensiMonthChanged(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: ColoredBox(
                color: AppColors.bg,
                child: BlocBuilder<AbsensiBloc, AbsensiState>(
                  builder: (context, state) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        AppCard(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: _buildCardContent(context, state),
                        ),
                        const SizedBox(height: 12),
                        const SyncFootnote(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header judul saja — terpisah dari card, sama seperti pola menu lain
  /// (mis. "Leave Request"): background putih di atas, body beige di
  /// bawahnya.
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Text('Log Absensi', style: AppTextStyles.h2),
    );
  }

  /// Isi card putih: nav bulan, ringkasan, kalender, panel detail. Judul
  /// TIDAK ikut di sini — sudah tampil di [_buildHeader] di luar card.
  Widget _buildCardContent(BuildContext context, AbsensiState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMonthNav(context, state.selectedMonth),
        const SizedBox(height: 14),
        _buildBody(context, state),
      ],
    );
  }

  Widget _buildMonthNav(BuildContext context, DateTime selectedMonth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => _shiftMonth(context, selectedMonth, -1),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.chevron_left, size: 20, color: AppColors.textMuted),
          ),
        ),
        InkWell(
          onTap: () => _pickMonth(context, selectedMonth),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _monthLabel(selectedMonth),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () => _shiftMonth(context, selectedMonth, 1),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AbsensiState state) {
    if (state.status == AbsensiStatus.loading && state.days.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == AbsensiStatus.failure && state.days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            state.errorMessage ?? 'Gagal memuat absensi.',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.summary != null) AttendanceSummaryCard(summary: state.summary!),
        const SizedBox(height: 16),
        AttendanceCalendar(
          month: state.selectedMonth,
          days: state.days,
          selectedDate: state.selectedDate,
          onDateSelected: (date) =>
              context.read<AbsensiBloc>().add(AbsensiDateSelected(date)),
        ),
        const SizedBox(height: 14),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 14),
        DayDetailPanel(day: state.selectedDay),
      ],
    );
  }
}
