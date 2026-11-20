import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../shared/presentation/widgets/portal_category_page.dart';
import '../../data/meter_reading_repository.dart';
import '../../domain/meter_reading_state.dart';
import '../../domain/meter_reading_summary.dart';
import '../../domain/meter_type.dart';
import '../bloc/list/meter_reading_list_bloc.dart';
import '../bloc/list/meter_reading_list_event.dart';
import '../bloc/list/meter_reading_list_state.dart';
import 'meter_reading_detail_screen.dart';
import '../widgets/meter_load_more_retry.dart';
import '../widgets/meter_period_banner.dart';
import '../widgets/meter_progress_summary.dart';
import '../widgets/meter_reading_card.dart';
import '../widgets/meter_reading_empty_view.dart';
import '../widgets/meter_state_filter_bar.dart';
import '../widgets/meter_type_filter.dart';

/// Halaman Meter Reading — daftar meter yang harus dicatat petugas.
///
/// Versi mobile dari tabel di web, dirancang ulang untuk kerja lapangan:
/// kartu per meter dengan angka terakhir sebagai fokus, filter status
/// pencatatan (terutama "Not recorded"), jenis meter lewat bottom sheet, dan
/// pencarian (perusahaan, lokasi, nomor seri, catatan). Filter, pencarian, dan paginasi dikerjakan sisi server.
class MeterReadingScreen extends StatelessWidget {
  const MeterReadingScreen({
    super.key,
    this.repository,
    this.initialStateCode,
  });

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final MeterReadingRepository? repository;

  /// `MeterReadingState.code` yang langsung aktif saat halaman dibuka, mis.
  /// `pending`. Null = chip "All".
  final String? initialStateCode;

  @override
  Widget build(BuildContext context) {
    final meterReading = repository ?? context.read<MeterReadingRepository>();

    return BlocProvider(
      create: (_) => MeterReadingListBloc(
        repository: meterReading,
        initialStateCode: initialStateCode,
      )..add(const MeterReadingListStarted()),
      child: _MeterReadingView(repository: meterReading),
    );
  }
}

class _MeterReadingView extends StatefulWidget {
  const _MeterReadingView({required this.repository});

  /// Diteruskan ke layar detail saat sebuah kartu dibuka — detail punya
  /// bloc-nya sendiri, bukan berbagi dengan daftar.
  final MeterReadingRepository repository;

  @override
  State<_MeterReadingView> createState() => _MeterReadingViewState();
}

class _MeterReadingViewState extends State<_MeterReadingView> {
  /// Jeda sebelum ketikan dikirim ke server.
  static const _searchDebounce = Duration(milliseconds: 400);

  /// Sisa ruang gulir yang memicu pemuatan halaman berikutnya.
  static const _loadMoreThreshold = 320.0;

  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Lewat notifikasi, bukan `ScrollController` sendiri: daftar ini harus
  /// memakai `PrimaryScrollController` supaya geraknya menyatu dengan
  /// header `PortalModulePage`.
  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification.metrics.extentAfter > _loadMoreThreshold) return false;

    context.read<MeterReadingListBloc>().add(
          const MeterReadingListNextPageRequested(),
        );
    return false;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (!mounted) return;
      context.read<MeterReadingListBloc>().add(MeterReadingListSearched(value));
    });
  }

  Future<void> _pickType(MeterReadingListState state) async {
    final picked = await showMeterTypeSheet(
      context,
      selectedCode: state.typeCode,
    );
    if (picked == null || !mounted) return;

    context
        .read<MeterReadingListBloc>()
        .add(MeterReadingListTypeSelected(picked.code));
  }

  void _resetFilters() {
    _debounce?.cancel();
    _searchController.clear();
    context.read<MeterReadingListBloc>().add(const MeterReadingListFiltersCleared());
  }

  /// Membuka detail, lalu mengambil ulang daftar begitu user kembali:
  /// mencatat pembacaan mengubah status baris dan angka di chip, dan daftar
  /// tidak perlu menebak-nebak perubahannya.
  ///
  /// [startRecording] true bila datang dari jalan pintas "Record reading" —
  /// detail langsung membuka form begitu rinciannya termuat.
  Future<void> _openDetail(
    MeterReadingSummary reading, {
    bool startRecording = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MeterReadingDetailScreen(
          summary: reading,
          repository: widget.repository,
          startRecording: startRecording,
        ),
      ),
    );
    if (!mounted) return;

    context.read<MeterReadingListBloc>().add(const MeterReadingListRefreshed());
  }

  Future<void> _refresh() async {
    final bloc = context.read<MeterReadingListBloc>()
      ..add(const MeterReadingListRefreshed());

    await bloc.stream.firstWhere(
      (state) => state.status != MeterReadingListStatus.loading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PortalModulePage(
      title: 'Meter Reading',
      subtitle: 'Record utility meter readings and manage their billing.',
      illustrationAsset: PortalCategoryPage.meterIllustration,
      body: BlocBuilder<MeterReadingListBloc, MeterReadingListState>(
        builder: (context, state) {
          // `summary` server menghitung seluruh meter periode ini dan tidak
          // ikut menyempit oleh filter jenis / pencarian; angka chip hanya
          // ditampilkan saat daftar memang tidak disaring oleh keduanya.
          final countsMatchList =
              state.typeCode == null && state.query.trim().isEmpty;
          final type = state.typeCode == null
              ? null
              : MeterType.fromCode(state.typeCode);
          final showResultCount = state.hasActiveFilter &&
              state.status == MeterReadingListStatus.success;
          final showPeriod =
              state.status == MeterReadingListStatus.success ||
                  state.items.isNotEmpty;

          return Column(
            children: [
              MeterProgressSummary(counts: state.counts),
              if (showPeriod)
                MeterPeriodBanner(
                  activePeriod: state.activePeriod,
                  canWrite: state.canWrite,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _searchController,
                        hint: 'Search company, location, or S/N',
                        icon: Icons.search,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: 10),
                    MeterTypeButton(
                      active: state.typeCode != null,
                      onTap: () => _pickType(state),
                    ),
                  ],
                ),
              ),
              MeterStateFilterBar(
                counts: state.counts,
                selected: state.stateCode,
                showCounts: countsMatchList,
                onChanged: (code) => context
                    .read<MeterReadingListBloc>()
                    .add(MeterReadingListStateSelected(code)),
              ),
              if (type != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: MeterActiveTypeChip(
                      type: type,
                      onClear: () => context
                          .read<MeterReadingListBloc>()
                          .add(const MeterReadingListTypeSelected(null)),
                    ),
                  ),
                ),
              if (showResultCount)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${state.meta.total} ${state.meta.total == 1 ? 'meter' : 'meters'} found',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MeterReadingListState state) {
    // `initial` sebentar saja: bloc baru menerima event Started.
    if (state.isFirstLoad || state.status == MeterReadingListStatus.initial) {
      return ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          ShimmerList(
            itemCount: 5,
            itemBuilder: (context) => const MeterReadingCardSkeleton(),
          ),
        ],
      );
    }

    // Galat hanya mengambil alih layar saat belum ada apa pun yang tampil.
    if (state.status == MeterReadingListStatus.failure && state.items.isEmpty) {
      return AppErrorView(
        message: state.errorMessage ?? 'Failed to load meter readings.',
        onRetry: () => context
            .read<MeterReadingListBloc>()
            .add(const MeterReadingListRefreshed()),
      );
    }

    if (state.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            MeterReadingEmptyView(
              hasActiveFilter: state.hasActiveFilter,
              allRecorded: state.stateCode == MeterReadingState.pending.code &&
                  state.query.trim().isEmpty &&
                  state.typeCode == null,
              onReset: _resetFilters,
            ),
          ],
        ),
      );
    }

    // Satu baris tambahan di bawah: skeleton saat memuat halaman berikutnya,
    // atau tombol "Retry" bila gagal.
    final hasFooter = state.loadingMore || state.loadMoreError != null;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          itemCount: state.items.length + (hasFooter ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            if (i >= state.items.length) {
              if (state.loadingMore) return const MeterReadingCardSkeleton();

              return MeterLoadMoreRetry(
                message: state.loadMoreError ?? 'Could not load more.',
                onRetry: () => context
                    .read<MeterReadingListBloc>()
                    .add(const MeterReadingListNextPageRetried()),
              );
            }

            final reading = state.items[i];
            return MeterReadingCard(
              reading: reading,
              onTap: () => _openDetail(reading),
              onRecord: () => _openDetail(reading, startRecording: true),
            );
          },
        ),
      ),
    );
  }
}
