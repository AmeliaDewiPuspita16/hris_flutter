import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_error_view.dart';
import '../../data/it_request_repository.dart';
import '../../domain/it_request_detail.dart';
import '../../domain/it_request_item.dart';
import '../bloc/list/it_request_list_bloc.dart';
import '../bloc/list/it_request_list_event.dart';
import '../bloc/list/it_request_list_state.dart';
import '../screens/it_request_detail_screen.dart';
import 'list_request_row.dart';

/// Status yang relevan untuk tab "List Request" — IT masih bisa merespons
/// yang "On Waiting", dan menutup yang "On Progress" (lih. dokumentasi
/// `POST .../respond` dan `POST .../complete`). Nilainya sama dengan
/// parameter `?status=` di server. Status lain (wait_checked, done,
/// finished, dst) tidak muncul di sini karena sudah tidak butuh aksi tim IT
/// lagi — tetap kelihatan di tab "Form IT & Media".
const _kWaitingCode = 'waiting';
const _kProgressCode = 'progress';

/// Isi tab "List Request": dua counter On Waiting / On Progress yang juga
/// berfungsi sebagai filter (mengikuti dua "tab" berwarna di versi web),
/// lalu daftar permintaan SELURUH perusahaan sesuai filter yang aktif.
///
/// Tiap status punya [ItRequestListBloc] sendiri yang menyaring di sisi
/// server (`GET /api/portal/apps/it_request?status=waiting|progress`) —
/// angka counter diambil dari `meta.total` masing-masing, jadi sudah total
/// sebenarnya sejak halaman pertama tanpa perlu menarik semua halaman.
/// Daftarnya tetap lazy-load per scroll.
///
/// Filter Month/Year/Status seperti di web belum diimplementasikan di
/// iterasi ini — cuma dua counter utamanya dulu.
class ListRequestTab extends StatefulWidget {
  const ListRequestTab({super.key, this.repository});

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ItRequestRepository? repository;

  @override
  State<ListRequestTab> createState() => _ListRequestTabState();
}

class _ListRequestTabState extends State<ListRequestTab> {
  static const _loadMoreThreshold = 320.0;

  late final ItRequestRepository _repository;
  late final ItRequestListBloc _waitingBloc;
  late final ItRequestListBloc _progressBloc;
  String _filter = _kWaitingCode;

  ItRequestListBloc get _activeBloc =>
      _filter == _kWaitingCode ? _waitingBloc : _progressBloc;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<ItRequestRepository>();
    _waitingBloc =
        ItRequestListBloc(repository: _repository, status: _kWaitingCode)
          ..add(const ItRequestListStarted());
    _progressBloc =
        ItRequestListBloc(repository: _repository, status: _kProgressCode)
          ..add(const ItRequestListStarted());
  }

  @override
  void dispose() {
    _waitingBloc.close();
    _progressBloc.close();
    super.dispose();
  }

  /// Lewat notifikasi, bukan `ScrollController` sendiri: daftar ini harus
  /// memakai `PrimaryScrollController` supaya geraknya menyatu dengan
  /// header `PortalModulePage` di `ItRequestScreen`.
  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification.metrics.extentAfter > _loadMoreThreshold) return false;

    _activeBloc.add(const ItRequestListNextPageRequested());
    return false;
  }

  Future<void> _refresh() async {
    _waitingBloc.add(const ItRequestListRefreshed());
    _progressBloc.add(const ItRequestListRefreshed());
    await Future.wait([
      for (final bloc in [_waitingBloc, _progressBloc])
        bloc.stream.firstWhere((s) => s.status != ItRequestListStatus.loading),
    ]);
  }

  void _selectFilter(String filter) {
    if (filter == _filter) return;
    setState(() => _filter = filter);
    final controller = PrimaryScrollController.maybeOf(context);
    if (controller != null && controller.hasClients) controller.jumpTo(0);
  }

  void _openDetail(ItRequestItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItRequestDetailScreen(
          item: item,
          repository: _repository,
          // Dikirim ke dua bloc: yang lama mengeluarkan item dari daftarnya,
          // yang cocok dengan status barunya menyisipkannya (lih.
          // `_onLocalItemUpdated` di bloc).
          onItTeamActionDone: (ItRequestDetail updated) {
            _waitingBloc.add(ItRequestLocalItemUpdated(updated));
            _progressBloc.add(ItRequestLocalItemUpdated(updated));
          },
        ),
      ),
    );
  }

  /// Null selagi halaman pertama status itu belum termuat — tampilkan
  /// spinner kecil, bukan angka 0 yang belum benar.
  int? _countOf(ItRequestListState state) =>
      state.status == ItRequestListStatus.initial || state.isFirstLoad
          ? null
          : state.meta.total;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItRequestListBloc, ItRequestListState>(
      bloc: _waitingBloc,
      builder: (context, waitingState) =>
          BlocBuilder<ItRequestListBloc, ItRequestListState>(
        bloc: _progressBloc,
        builder: (context, progressState) => _buildBody(
          context,
          waitingState: waitingState,
          progressState: progressState,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required ItRequestListState waitingState,
    required ItRequestListState progressState,
  }) {
    final state = _filter == _kWaitingCode ? waitingState : progressState;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: _CounterChip(
                    label: 'On Waiting',
                    count: _countOf(waitingState),
                    color: AppColors.pending,
                    background: AppColors.pendingBg,
                    active: _filter == _kWaitingCode,
                    onTap: () => _selectFilter(_kWaitingCode),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CounterChip(
                    label: 'On Progress',
                    count: _countOf(progressState),
                    color: AppColors.inProgress,
                    background: AppColors.inProgressBg,
                    active: _filter == _kProgressCode,
                    onTap: () => _selectFilter(_kProgressCode),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ..._buildList(context, state),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildList(BuildContext context, ItRequestListState state) {
    if (state.status == ItRequestListStatus.initial || state.isFirstLoad) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state.status == ItRequestListStatus.failure && state.items.isEmpty) {
      return [
        AppErrorView(
          message: state.errorMessage ?? 'Failed to load the request list.',
          onRetry: () => _activeBloc.add(const ItRequestListRefreshed()),
        ),
      ];
    }

    final items = state.items;
    return [
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Center(
            child: Text('No data', style: AppTextStyles.bodyMuted),
          ),
        )
      else
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          ListRequestRow(item: items[i], onTap: () => _openDetail(items[i])),
        ],
      if (state.loadingMore)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
    ];
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.background,
    required this.active,
    required this.onTap,
  });

  final String label;

  /// Null berarti halaman pertama status ini belum termuat — tampilkan
  /// spinner kecil, bukan angka yang belum final.
  final int? count;

  final Color color;
  final Color background;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? color : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 22,
              child: count == null
                  ? Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: color),
                      ),
                    )
                  : Text(
                      '$count',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textMid)),
          ],
        ),
      ),
    );
  }
}
