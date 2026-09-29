import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/header_title_row.dart';
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
///
/// Dibuka dari menu HRIS atau kartu jam kerja di Beranda (push), bukan lagi
/// tab bottom nav, jadi header punya tombol kembali ([showBack]).
class AbsensiScreen extends StatelessWidget {
  const AbsensiScreen({super.key, this.repository, this.showBack = true});

  /// Tampilkan tombol kembali di header.
  final bool showBack;

  /// Diisi test; di aplikasi dibuat langsung dari [ApiClient] lokal — lihat
  /// catatan di [AbsensiRepository] soal kenapa belum didaftarkan di
  /// main.dart (masih dummy, API HRIS belum tersedia).
  final AbsensiRepository? repository;

  @override
  Widget build(BuildContext context) {
    final absensi = repository ?? AbsensiRepository(apiClient: ApiClient());

    return BlocProvider(
      create: (_) => AbsensiBloc(repository: absensi)..add(const AbsensiStarted()),
      // Header hijau sampai ke balik status bar → ikon status bar terang.
      // Diset di sini karena layar ini dibuka lewat push, di luar
      // AnnotatedRegion milik BerandaScreen.
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        // Scaffold dibutuhkan sebagai ancestor Material (InkWell, dst.):
        // layar ini di-push sebagai route sendiri, tidak lagi berada di
        // dalam Scaffold milik BerandaScreen.
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: _AbsensiView(showBack: showBack),
        ),
      ),
    );
  }
}

class _AbsensiView extends StatelessWidget {
  const _AbsensiView({required this.showBack});

  final bool showBack;

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
    // Strip status bar = warna header (primary); badan halaman = AppColors.bg
    // seperti Home dan Leave Request.
    return ColoredBox(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: ColoredBox(
          color: AppColors.bg,
          child: BlocBuilder<AbsensiBloc, AbsensiState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, state.selectedMonth),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        AppCard(
                          padding: const EdgeInsets.all(16),
                          child: _buildBody(context, state),
                        ),
                        // Detail tanggal terpilih: card terpisah di bawah
                        // kalender.
                        if (state.days.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          AppCard(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: DayDetailPanel(day: state.selectedDay),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const SyncFootnote(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Header solid warna primary (sama dengan strip status bar di atasnya),
  /// sudut bawah membulat. Judul + navigasi bulan di dalam pil transparan.
  Widget _buildHeader(BuildContext context, DateTime selectedMonth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderTitleRow(title: 'Log Absensi', showBack: showBack),
          _buildMonthNav(context, selectedMonth),
        ],
      ),
    );
  }

  Widget _buildMonthNav(BuildContext context, DateTime selectedMonth) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => _shiftMonth(context, selectedMonth, -1),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(7),
              child: Icon(Icons.chevron_left, size: 20, color: Colors.white),
            ),
          ),
          InkWell(
            onTap: () => _pickMonth(context, selectedMonth),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _monthLabel(selectedMonth),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => _shiftMonth(context, selectedMonth, 1),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(7),
              child: Icon(Icons.chevron_right, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
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
      ],
    );
  }
}
