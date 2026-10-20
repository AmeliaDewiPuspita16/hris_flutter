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
/// `POST .../respond` dan `POST .../complete`). Status lain (wait_checked,
/// done, finished, dst) tidak muncul di sini karena sudah tidak butuh aksi
/// tim IT lagi — tetap kelihatan di tab "Form IT & Media".
const _kWaitingCode = 'waiting';
const _kProgressCode = 'progress';

/// Isi tab "List Request": dua counter On Waiting / On Progress yang juga
/// berfungsi sebagai filter (mengikuti dua "tab" berwarna di versi web),
/// lalu daftar permintaan SELURUH perusahaan sesuai filter yang aktif —
/// sama sumber datanya (`GET /api/portal/apps/it_request`, lewat
/// [ItRequestListBloc] yang sama) dengan tab "Form IT & Media", cuma
/// disaring beda.
/// Isi tab "List Request", mengikuti web: daftar SEMUA permintaan langsung
/// terbuka, dengan dua tombol On Waiting / On Progress di atasnya yang
/// berfungsi sebagai filter.
///
/// Menekan salah satu tombol memfilter daftar ke status itu; menekannya lagi
/// (atau tombol yang aktif) mengembalikan daftar ke semua request.
///
/// Filter Month/Year/Status seperti di web belum diimplementasikan di
/// iterasi ini.
///
/// SEMENTARA: [ListRequestDemoData] statis, belum tersambung ke API.
class ListRequestTab extends StatefulWidget {
  const ListRequestTab({super.key});
/// iterasi ini — cuma dua counter utamanya dulu.
///
/// `loadAllPages: true` dipasang di sini (beda dari tab sebelah) supaya
/// bloc menarik SEMUA halaman sekali di awal — tanpa ini, counter cuma
/// menghitung item yang sudah termuat dan terus bertambah tiap kali user
/// scroll, bukan menunjukkan total sebenarnya (server tidak punya endpoint
/// hitung/filter per status).
class ListRequestTab extends StatelessWidget {
  const ListRequestTab({super.key, this.repository});

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ItRequestRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ItRequestListBloc(
        repository: repository ?? context.read<ItRequestRepository>(),
        loadAllPages: true,
      )..add(const ItRequestListStarted()),
      child: const _ListRequestView(),
    );
  }
}

class _ListRequestView extends StatefulWidget {
  const _ListRequestView();

  @override
  State<_ListRequestView> createState() => _ListRequestViewState();
}

class _ListRequestTabState extends State<ListRequestTab> {
  final List<ListRequestItem> _items = ListRequestDemoData.items();

  /// Null = semua request.
  ListRequestStatus? _filter;

  int _countOf(ListRequestStatus status) =>
      _items.where((i) => i.status == status).length;

  /// Tekan tombol yang belum aktif -> filter ke status itu; tekan yang sudah
  /// aktif -> kembali ke semua.
  void _toggleFilter(ListRequestStatus status) {
    setState(() => _filter = _filter == status ? null : status);
  }
class _ListRequestViewState extends State<_ListRequestView> {
  static const _loadMoreThreshold = 320.0;

  final _scrollController = ScrollController();
  String _filter = _kWaitingCode;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final remaining =
        _scrollController.position.maxScrollExtent - _scrollController.position.pixels;
    if (remaining > _loadMoreThreshold) return;

    context.read<ItRequestListBloc>().add(const ItRequestListNextPageRequested());
  }

  Future<void> _refresh() async {
    final bloc = context.read<ItRequestListBloc>()..add(const ItRequestListRefreshed());
    await bloc.stream.firstWhere((s) => s.status != ItRequestListStatus.loading);
  }

  void _openDetail(ItRequestItem item) {
    final bloc = context.read<ItRequestListBloc>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItRequestDetailScreen(
          item: item,
          repository: context.read<ItRequestRepository>(),
          onItTeamActionDone: (ItRequestDetail updated) =>
              bloc.add(ItRequestLocalItemUpdated(updated)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filter == null
        ? _items
        : _items.where((i) => i.status == _filter).toList();
    final title = _filter == null ? 'Semua Request' : _filter!.label;
    return BlocBuilder<ItRequestListBloc, ItRequestListState>(
      builder: (context, state) => _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ItRequestListState state) {
    if (state.isFirstLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ItRequestListStatus.failure && state.items.isEmpty) {
      return AppErrorView(
        message: state.errorMessage ?? 'Gagal memuat daftar request.',
        onRetry: () => context.read<ItRequestListBloc>().add(const ItRequestListRefreshed()),
      );
    }

    final waitingCount =
        state.items.where((i) => i.status.code == _kWaitingCode).length;
    final progressCount =
        state.items.where((i) => i.status.code == _kProgressCode).length;
    final filtered = state.items.where((i) => i.status.code == _filter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatusButton(
                label: ListRequestStatus.onWaiting.label,
                count: _countOf(ListRequestStatus.onWaiting),
                color: AppColors.pending,
                background: AppColors.pendingBg,
                active: _filter == ListRequestStatus.onWaiting,
                onTap: () => _toggleFilter(ListRequestStatus.onWaiting),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatusButton(
                label: ListRequestStatus.onProgress.label,
                count: _countOf(ListRequestStatus.onProgress),
                color: AppColors.present,
                background: AppColors.presentBg,
                active: _filter == ListRequestStatus.onProgress,
                onTap: () => _toggleFilter(ListRequestStatus.onProgress),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('$title (${shown.length})', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text('Tidak ada data', style: AppTextStyles.bodyMuted),
            ),
          )
        else
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            ListRequestRow(
              item: shown[i],
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Detail belum tersedia')),
              ),
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: _CounterChip(
                  label: 'On Waiting',
                  // Null selagi halaman-halaman sisanya masih ditarik di
                  // latar belakang (lih. `loadAllPages` di bloc) — angka
                  // SEMENTARA yang baru mencakup sebagian halaman sengaja
                  // tidak ditampilkan, supaya tidak terlihat "berubah
                  // terus" tiap kali satu halaman lagi masuk. Begitu
                  // `loadingMore` selesai, angkanya final dan tidak
                  // berubah lagi sampai di-refresh.
                  count: state.loadingMore ? null : waitingCount,
                  color: AppColors.pending,
                  background: AppColors.pendingBg,
                  active: _filter == _kWaitingCode,
                  onTap: () => setState(() => _filter = _kWaitingCode),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CounterChip(
                  label: 'On Progress',
                  count: state.loadingMore ? null : progressCount,
                  color: AppColors.inProgress,
                  background: AppColors.inProgressBg,
                  active: _filter == _kProgressCode,
                  onTap: () => setState(() => _filter = _kProgressCode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text('Tidak ada data', style: AppTextStyles.bodyMuted),
              ),
            )
          else
            for (var i = 0; i < filtered.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              ListRequestRow(item: filtered[i], onTap: () => _openDetail(filtered[i])),
            ],
          if (state.loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

/// Tombol filter status dengan jumlah di kanan (seperti tombol "On Waiting 8"
/// di web). Saat aktif, bingkainya menebal dan latarnya terisi warna status.
class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.count,
    required this.color,
    required this.background,
    required this.active,
    required this.onTap,
  });

  final String label;

  /// Null berarti masih dihitung (halaman-halaman lain masih ditarik di
  /// latar belakang) — tampilkan spinner kecil, bukan angka sementara yang
  /// belum final.
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? background : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: active ? 1.8 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              height: 22,
              child: count == null
                  ? Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: color),
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
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMid)),
          ],
        ),
      ),
    );
  }
}
