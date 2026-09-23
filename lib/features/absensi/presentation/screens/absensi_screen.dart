import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/absensi_repository.dart';
import '../bloc/absensi_bloc.dart';
import '../bloc/absensi_event.dart';
import '../bloc/absensi_state.dart';
import '../widgets/attendance_row.dart';
import '../widgets/attendance_summary_card.dart';
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
    final picked = await showMonthPicker(
      context: context,
      initialDate: current,
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

    if (picked != null && context.mounted) {
      context.read<AbsensiBloc>().add(AbsensiMonthChanged(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.card,
      child: SafeArea(
        child: ColoredBox(
          color: AppColors.bg,
          child: BlocBuilder<AbsensiBloc, AbsensiState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, state.selectedMonth),
                  Expanded(child: _buildBody(state)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AbsensiState state) {
    if (state.status == AbsensiStatus.loading && state.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == AbsensiStatus.failure && state.entries.isEmpty) {
      return Center(
        child: Text(
          state.errorMessage ?? 'Gagal memuat absensi.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (state.summary != null) AttendanceSummaryCard(summary: state.summary!),
        const SizedBox(height: 16),
        ...state.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AttendanceRow(entry: e),
          ),
        ),
        const SizedBox(height: 4),
        const SyncFootnote(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, DateTime selectedMonth) {
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
                onTap: () => _shiftMonth(context, selectedMonth, -1),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_left,
                      size: 18, color: AppColors.textMuted),
                ),
              ),
              InkWell(
                onTap: () => _pickMonth(context, selectedMonth),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Text(
                    _monthLabel(selectedMonth).toUpperCase(),
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
                onTap: () => _shiftMonth(context, selectedMonth, 1),
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
