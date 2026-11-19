import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../../../../core/widgets/detail_field_tile.dart';
import '../../data/meter_reading_repository.dart';
import '../../domain/meter_reading.dart';
import '../../domain/meter_reading_summary.dart';
import '../bloc/detail/meter_reading_detail_bloc.dart';
import '../bloc/detail/meter_reading_detail_event.dart';
import '../bloc/detail/meter_reading_detail_state.dart';
import '../widgets/installed_meter_tile.dart';
import '../widgets/meter_detail_hero.dart';
import '../widgets/meter_photo_grid.dart';
import '../widgets/meter_record_bar.dart';
import '../widgets/meter_section_title.dart';
import 'record_meter_reading_screen.dart';

/// Detail satu meter: angka terakhir, informasi kontrak, meter terpasang,
/// dan foto — plus aksi "Record New Data".
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

  /// True bila dibuka dari jalan pintas "Record reading" di kartu: begitu
  /// rincian termuat dan periodenya memang bisa dicatat, form langsung
  /// dibuka. Meter terpasang baru diketahui dari rincian, jadi form tidak
  /// bisa dibuka lebih awal.
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

  /// Membuka form Record New Data. Mengembalikan rincian TERBARU bila petugas
  /// berhasil menyimpan, atau null bila form dibatalkan.
  Future<MeterReading?> _openRecordForm(MeterReading detail) {
    return Navigator.of(context).push<MeterReading>(
      MaterialPageRoute(
        builder: (_) => RecordMeterReadingScreen(
          reading: detail,
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<void> _onRecord(BuildContext context, MeterReading detail) async {
    final updated = await _openRecordForm(detail);
    if (updated == null || !context.mounted) return;

    context.read<MeterReadingDetailBloc>().add(MeterReadingDetailUpdated(updated));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Reading recorded.')));
  }

  String _periodLabel(MeterReadingSummary reading) =>
      '${DateFormatter.shortDate(reading.period.start)} – '
      '${DateFormatter.shortDate(reading.period.end)}';

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
                    state: detail.state,
                    canRecord: detail.canRecord,
                    onRecord: () => _onRecord(context, detail),
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
          MeterDetailHero(reading: reading, detail: detail),
          const SizedBox(height: 22),
          if (detail == null)
            const ShimmerDetailSections(rowsPerSection: [4, 2, 1])
          else
            ..._sections(detail),
        ],
      ),
    );
  }

  List<Widget> _sections(MeterReading detail) {
    final recordedAt = detail.recordedAt;
    final rows = <({String label, String value})>[
      (label: 'Period', value: _periodLabel(detail)),
      (label: 'Contract No.', value: detail.contractNumber),
      (label: 'Category', value: detail.category.label),
      if (detail.tenantRepresentative != null)
        (label: 'Tenant Representative', value: detail.tenantRepresentative!),
      if (detail.biieRepresentative != null)
        (label: 'BIIE Representative', value: detail.biieRepresentative!),
      if (detail.recordedBy != null)
        (
          label: 'Last recorded',
          value: recordedAt == null
              ? detail.recordedBy!
              : '${detail.recordedBy} · ${DateFormatter.dateTimeID(recordedAt.toLocal())}',
        ),
    ].where((row) => row.value.trim().isNotEmpty).toList();

    return [
      const MeterSectionTitle(title: 'CONTRACT', icon: Icons.description_outlined),
      AppCard(
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
      ),
      const SizedBox(height: 22),
      MeterSectionTitle(
        title: 'INSTALLED METERS',
        icon: Icons.speed_rounded,
        trailing: MeterCountChip(
          label: '${detail.meters.length} ${detail.meters.length == 1 ? 'meter' : 'meters'}',
        ),
      ),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: detail.meters.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Center(
                  child: Text('No meters installed.', style: AppTextStyles.bodyMuted),
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < detail.meters.length; i++)
                    InstalledMeterTile(
                      meter: detail.meters[i],
                      showDivider: i < detail.meters.length - 1,
                    ),
                ],
              ),
      ),
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
