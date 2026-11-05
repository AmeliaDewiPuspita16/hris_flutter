import 'package:flutter/material.dart';

import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../domain/observation_item.dart';
import '../bloc/observation_list_state.dart';
import 'observation_card.dart';
import 'observation_empty_view.dart';

/// Isi satu tab daftar Observation: skeleton saat muat pertama, layar galat,
/// keadaan kosong, atau daftar kartu dengan tarik-untuk-muat-ulang.
class ObservationListTab extends StatelessWidget {
  const ObservationListTab({
    super.key,
    required this.state,
    required this.items,
    required this.onRefresh,
    required this.onOpen,
    this.onClose,
    this.onEdit,
    this.onDelete,
    this.detailForOpen = false,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final ObservationListState state;

  /// Item yang sudah disaring (pencarian/filter) untuk tab ini.
  final List<ObservationItem> items;
  final Future<void> Function() onRefresh;
  final ValueChanged<ObservationItem> onOpen;

  /// Null = tab ini tanpa tombol Close (tab All Observations).
  final ValueChanged<ObservationItem>? onClose;

  /// Null = tab ini tanpa menu Edit / Delete (hanya tab All Observations).
  final ValueChanged<ObservationItem>? onEdit;
  final ValueChanged<ObservationItem>? onDelete;

  /// True = observasi yang masih open juga bisa dibuka detailnya (tab All
  /// Observations). False = hanya yang sudah closed (tab My Dept Open).
  final bool detailForOpen;
  final String emptyTitle;
  final String emptyMessage;

  /// Ruang di bawah daftar supaya kartu terakhir tidak tertutup FAB.
  static const _bottomPadding = 100.0;

  @override
  Widget build(BuildContext context) {
    if (state.isFirstLoad) return const _Skeleton();

    if (state.status == ObservationListStatus.failure &&
        state.all.isEmpty &&
        state.myOpen.isEmpty) {
      return AppErrorView(
        message: state.errorMessage ?? 'Failed to load observations.',
        onRetry: onRefresh,
      );
    }

    final searching = state.query.trim().isNotEmpty || state.filter.isActive;

    return RefreshIndicator(
      onRefresh: onRefresh,
      // Daftar memakai PrimaryScrollController bawaan (tanpa controller
      // sendiri) supaya geraknya terhubung dengan header — lihat
      // `PortalModulePage`.
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
                      ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, _bottomPadding),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return ObservationCard(
                  item: item,
                  onTap: item.isOpen && !detailForOpen
                      ? null
                      : () => onOpen(item),
                  onClose: item.canClose && onClose != null
                      ? () => onClose!(item)
                      : null,
                  onEdit: item.canModify && onEdit != null
                      ? () => onEdit!(item)
                      : null,
                  onDelete: item.canModify && onDelete != null
                      ? () => onDelete!(item)
                      : null,
                );
              },
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
