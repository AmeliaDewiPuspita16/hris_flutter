import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../../../../core/widgets/detail_field_tile.dart';
import '../../data/meter_reading_repository.dart';
import '../../domain/meter_reading.dart';
import '../../domain/meter_reading_summary.dart';
import '../../domain/meter_value_format.dart';
import '../bloc/detail/meter_reading_detail_bloc.dart';
import '../bloc/detail/meter_reading_detail_event.dart';
import '../bloc/detail/meter_reading_detail_state.dart';
import '../widgets/meter_detail_hero.dart';
import '../widgets/meter_photo_grid.dart';
import '../widgets/meter_record_bar.dart';
import '../widgets/meter_section_title.dart';
import 'record_meter_reading_screen.dart';

/// Hasil form catat / edit / bacaan baru: rincian TERBARU (id-nya bisa sudah
/// baru setelah `new_reading`) dan pesan sukses dari server.
typedef MeterSaveResult = ({MeterReading reading, String? message});

/// Detail satu record (satu meter pada satu periode): angka terakhir,
/// informasi meter, bacaan periode ini, dan foto bukti — plus satu aksi
/// (Record New Data / Edit Record / New Reading) sesuai `action` dari server.
///
/// Kepala layar langsung tergambar dari [summary] (yang dibawa dari daftar)
/// selagi rincian lengkap diambil.
class MeterReadingDetailScreen extends StatelessWidget {
  const MeterReadingDetailScreen({
    super.key,
    required this.summary,
    this.repository,
    this.startRecording = false,
  });

  final MeterReadingSummary summary;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final MeterReadingRepository? repository;

  /// True bila dibuka dari jalan pintas di kartu: begitu rincian termuat dan
  /// user memang boleh mencatat, form langsung dibuka. `can_write` dan
  /// `next_previous_value` baru diketahui dari rincian, jadi form tidak bisa
  /// dibuka lebih awal.
  final bool startRecording;

  @override
  Widget build(BuildContext context) {
    final meterReading = repository ?? context.read<MeterReadingRepository>();

    return BlocProvider(
      create: (_) => MeterReadingDetailBloc(repository: meterReading)
        ..add(MeterReadingDetailRequested(summary.id)),
      child: _View(
        summary: summary,
        repository: meterReading,
        startRecording: startRecording,
      ),
    );
  }
}

class _View extends StatefulWidget {
  const _View({
    required this.summary,
    required this.repository,
    required this.startRecording,
  });

  final MeterReadingSummary summary;
  final MeterReadingRepository repository;
  final bool startRecording;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  /// Form dibuka otomatis paling banyak sekali — bukan setiap kali
  /// rinciannya diperbarui.
  bool _autoRecordHandled = false;

  /// Membuka form. Mengembalikan hasil simpan bila berhasil, atau null bila
  /// form dibatalkan.
  Future<MeterSaveResult?> _openRecordForm(MeterReading detail) {
    return Navigator.of(context).push<MeterSaveResult>(
      MaterialPageRoute(
        builder: (_) => RecordMeterReadingScreen(
          reading: detail,
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<void> _onRecord(BuildContext context, MeterReading detail) async {
    final result = await _openRecordForm(detail);
    if (result == null || !context.mounted) return;

    // Setelah `new_reading`, result.reading.id adalah id baris BARU. Detail
    // dipasang apa adanya, jadi aksi berikutnya otomatis memakai id itu.
    context
        .read<MeterReadingDetailBloc>()
        .add(MeterReadingDetailUpdated(result.reading));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(result.message ?? 'Reading saved.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MeterReadingDetailBloc, MeterReadingDetailState>(
      listenWhen: (previous, current) =>
          !_autoRecordHandled &&
          widget.startRecording &&
          previous.detail == null &&
          current.detail != null,
      listener: (context, state) {
        _autoRecordHandled = true;
        final detail = state.detail!;
        if (detail.canRecord) _onRecord(context, detail);
      },
      child: BlocBuilder<MeterReadingDetailBloc, MeterReadingDetailState>(
        builder: (context, state) {
          final detail = state.detail;
          final reading = detail ?? widget.summary;

          return Scaffold(
            backgroundColor: AppColors.bg,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  BackHeader(
                    title: widget.summary.company,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  Expanded(child: _buildBody(context, state, reading, detail)),
                ],
              ),
            ),
            bottomNavigationBar: detail == null
                ? null
                : MeterRecordBar(
                    reading: detail,
                    onAction: () => _onRecord(context, detail),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    MeterReadingDetailState state,
    MeterReadingSummary reading,
    MeterReading? detail,
  ) {
    if (state.status == MeterReadingDetailStatus.failure) {
      return AppErrorView(
        message: state.errorMessage ?? 'Failed to load meter reading.',
        onRetry: () => context
            .read<MeterReadingDetailBloc>()
            .add(MeterReadingDetailRequested(widget.summary.id)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MeterDetailHero(reading: reading),
          const SizedBox(height: 22),
          if (detail == null)
            const ShimmerDetailSections(rowsPerSection: [4, 5, 1])
          else
            ..._sections(detail),
        ],
      ),
    );
  }

  String? _withUnit(MeterReadingSummary reading, num? value) {
    if (value == null) return null;
    final unit = reading.type.unit;
    return '${formatMeterValue(value)}${unit.isEmpty ? '' : ' $unit'}';
  }

  Widget _card(List<({String label, String value})> rows) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            DetailFieldTile(
              label: rows[i].label,
              value: rows[i].value,
              showDivider: i < rows.length - 1,
            ),
        ],
      ),
    );
  }

  List<Widget> _sections(MeterReading detail) {
    final recordedAt = detail.recordedAt;
    final recordedBy = detail.recordedBy;

    final meterRows = <({String label, String value})>[
      (label: 'Serial No.', value: detail.serialNumber),
      (label: 'Category', value: detail.categoryLabel ?? ''),
      (label: 'Meter Type', value: detail.meterTypeLabel ?? ''),
      (label: 'Period', value: detail.period.label),
    ].where((row) => row.value.trim().isNotEmpty).toList();

    final readingRows = <({String label, String value})>[
      (label: 'Previous Value', value: _withUnit(detail, detail.previousValue) ?? ''),
      (label: 'Current Value', value: _withUnit(detail, detail.currentValue) ?? ''),
      (label: 'Usage', value: _withUnit(detail, detail.consumption) ?? ''),
      (label: 'Status', value: detail.approval.label),
      (label: 'Notes', value: detail.notes ?? ''),
      if (recordedBy != null)
        (
          label: 'Last recorded',
          value: recordedAt == null
              ? recordedBy
              : '$recordedBy · ${DateFormatter.dateTimeID(recordedAt.toLocal())}',
        ),
    ].where((row) => row.value.trim().isNotEmpty).toList();

    return [
      const MeterSectionTitle(title: 'METER', icon: Icons.speed_rounded),
      _card(meterRows),
      const SizedBox(height: 22),
      const MeterSectionTitle(title: 'READING', icon: Icons.edit_note_rounded),
      _card(readingRows),
      const SizedBox(height: 22),
      const MeterSectionTitle(title: 'PHOTO', icon: Icons.photo_camera_outlined),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: MeterPhotoGrid(photos: detail.photoUrls),
        ),
      ),
    ];
  }
}
