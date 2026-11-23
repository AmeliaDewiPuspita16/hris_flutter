import 'package:material_ui/material_ui.dart';

import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../core/widgets/flash_highlight.dart';
import '../../domain/observation_item.dart';
import '../bloc/observation_list_state.dart';
import 'observation_card.dart';
import 'observation_empty_view.dart';

/// Isi satu tab daftar Observation: skeleton saat muat pertama, layar galat,
/// keadaan kosong, atau daftar kartu dengan tarik-untuk-muat-ulang.
class ObservationListTab extends StatelessWidget {
  const ObservationListTab({
    super.key,
    required this.tab,
    required this.searching,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onOpen,
    this.onClose,
    this.onEdit,
    this.onDelete,
    this.detailForOpen = false,
    this.showOwnership = false,
    this.highlightId,
    required this.emptyTitle,
    required this.emptyMessage,
    this.emptyIcon,
  });

  /// Baris yang sudah dimuat untuk tab ini beserta status paginasinya.
  final ObservationTabData tab;

  /// True = ada pencarian/filter aktif, jadi daftar kosong berarti "tidak
  /// ada hasil", bukan "belum ada data".
  final bool searching;
  final Future<void> Function() onRefresh;

  /// Dipanggil saat daftar hampir mencapai ujung bawah (dan juga oleh
  /// tombol "retry" bila memuat halaman berikutnya gagal).
  final VoidCallback onLoadMore;
  final ValueChanged<ObservationItem> onOpen;

  /// Null = tab ini tanpa tombol Close (tab All Observations).
  final ValueChanged<ObservationItem>? onClose;

  /// Null = tab ini tanpa menu Edit / Delete (hanya tab All Observations).
  final ValueChanged<ObservationItem>? onEdit;
  final ValueChanged<ObservationItem>? onDelete;

  /// True = observasi yang masih open juga bisa dibuka detailnya (tab All
  /// Observations). False = hanya yang sudah closed (tab My Dept Open).
  final bool detailForOpen;

  /// Teruskan ke kartu: tampilkan penanda "Your report" / "For your dept".
  final bool showOwnership;

  /// id temuan dari notifikasi: dinaikkan ke paling atas dan dikedipkan.
  /// Null = tidak ada yang disorot di tab ini.
  final String? highlightId;
  final String emptyTitle;
  final String emptyMessage;

  /// Ikon keadaan kosong; null = ikon bawaan [ObservationEmptyView].
  final IconData? emptyIcon;

  /// Ruang di bawah daftar supaya kartu terakhir tidak tertutup FAB.
  static const _bottomPadding = 100.0;

  /// Sisa ruang gulir (piksel) di bawah daftar saat halaman berikutnya
  /// mulai dimuat, supaya terasa tanpa jeda.
  static const _loadMoreThreshold = 400.0;

  /// Temuan dari notifikasi dinaikkan ke paling atas supaya langsung
  /// terlihat, sama seperti EST Request dan HSE.
  List<ObservationItem> _withHighlightFirst(List<ObservationItem> list) {
    final id = highlightId;
    final at = id == null ? -1 : list.indexWhere((i) => i.id == id);
    if (at <= 0) return list;
    return [list[at], ...list.take(at), ...list.skip(at + 1)];
  }

  @override
  Widget build(BuildContext context) {
    if (tab.isInitialLoading) return const _Skeleton();

    final items = tab.items;
    if (tab.error != null && items.isEmpty) {
      return AppErrorView(message: tab.error!, onRetry: onRefresh);
    }

    final shown = _withHighlightFirst(items);

    // Penanda ujung daftar: spinner saat memuat, atau tombol coba lagi
    // bila halaman berikutnya gagal dimuat.
    final showFooter = tab.hasMore || tab.error != null;

    return RefreshIndicator(
      onRefresh: onRefresh,
      // Daftar memakai PrimaryScrollController bawaan (tanpa controller
      // sendiri) supaya geraknya terhubung dengan header — lihat
      // `PortalModulePage`. Karena itu gulir dipantau lewat notifikasi,
      // bukan controller.
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.depth == 0 &&
              n.metrics.extentAfter < _loadMoreThreshold &&
              tab.hasMore &&
              !tab.loadingMore &&
              !tab.loading &&
              tab.error == null) {
            onLoadMore();
          }
          return false;
        },
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, _bottomPadding),
                children: [
                  searching
                      ? const ObservationEmptyView(
                          icon: Icons.search_off_rounded,
                          title: 'No results',
                          message:
                              'Nothing matches your search or filter. Try a different keyword.',
                        )
                      : ObservationEmptyView(
                          title: emptyTitle,
                          message: emptyMessage,
                          icon: emptyIcon ?? Icons.inbox_outlined,
                        ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, _bottomPadding),
                itemCount: shown.length + (showFooter ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == shown.length) {
                    return _Footer(
                      error: tab.error,
                      onRetry: onLoadMore,
                    );
                  }
                  final item = shown[index];
                  final card = ObservationCard(
                    item: item,
                    showOwnership: showOwnership,
                    onTap: item.isOpen && !detailForOpen
                        ? null
                        : () => onOpen(item),
                    onClose: item.canClose && onClose != null
                        ? () => onClose!(item)
                        : null,
                    onEdit: item.canEdit && onEdit != null
                        ? () => onEdit!(item)
                        : null,
                    onDelete: item.canDelete && onDelete != null
                        ? () => onDelete!(item)
                        : null,
                  );
                  return FlashHighlight(
                    key: ValueKey('hl-${item.id}'),
                    active: item.id == highlightId,
                    child: card,
                  );
                },
              ),
      ),
    );
  }
}

/// Ujung daftar: spinner kecil saat halaman berikutnya dimuat, atau pesan
/// galat dengan tombol coba lagi.
class _Footer extends StatelessWidget {
  const _Footer({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Failed to load more. Tap to retry'),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            const ShimmerBox(height: 172, borderRadius: 16),
          ],
        ],
      ),
    );
  }
}
