import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/flash_highlight.dart';
import '../../domain/indent_completed_item.dart';
import 'indent_driver_assignment_tab.dart';
import 'indent_request_row.dart';

/// Isi tab "Completed": perjalanan driver yang sudah di-Finish atau sudah
/// diberi feedback, terbaru di atas. Tarik ke bawah untuk memuat ulang;
/// halaman berikutnya dimuat saat digulir mendekati dasar.
class IndentCompletedTab extends StatelessWidget {
  const IndentCompletedTab({
    super.key,
    required this.items,
    required this.loadingMore,
    required this.onRefresh,
    required this.onNearEnd,
    this.highlightId,
  });

  final List<IndentCompletedItem> items;
  final bool loadingMore;
  final Future<void> Function() onRefresh;
  final VoidCallback onNearEnd;

  /// id dari notifikasi yang di-tap; kartunya dinaikkan ke paling atas lalu
  /// dikedipkan.
  final String? highlightId;

  /// Lewat notifikasi, bukan `ScrollController` sendiri: daftar ini harus
  /// memakai `PrimaryScrollController` supaya geraknya menyatu dengan header
  /// `PortalModulePage`.
  bool _onScroll(ScrollNotification notification) {
    if (notification.depth == 0 &&
        notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentAfter < 300) {
      onNearEnd();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final results = [...items];
    final at = results.indexWhere((item) => item.id == highlightId);
    if (at > 0) results.insert(0, results.removeAt(at));

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: results.isEmpty
          // ListView (bukan Center saja) supaya tarik-untuk-refresh tetap
          // bisa dipakai saat daftar kosong.
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    'No completed trips yet',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            )
          : NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: results.length + (loadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == results.length) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final item = results[index];
                  return FlashHighlight(
                    key: ValueKey('hl-completed-${item.id}'),
                    active: item.id == highlightId,
                    child: _CompletedCard(item: item),
                  );
                },
              ),
            ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.item});

  final IndentCompletedItem item;

  @override
  Widget build(BuildContext context) {
    final vehicle = item.vehicle;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tanpa label ini nama bisa dikira nama driver sendiri.
                    Text(
                      'Requested by',
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (vehicle != null) ...[
                const SizedBox(width: 8),
                IndentPlateChip(plate: vehicle),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _Line(icon: Icons.place_outlined, text: item.destination),
          const SizedBox(height: 3),
          _Line(
            icon: Icons.event_outlined,
            text: '${item.date}  ·  ${item.timeRange}',
          ),
          const SizedBox(height: 3),
          _Line(icon: Icons.notes_outlined, text: item.remark),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          _Feedback(item: item),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Expanded(child: Text(text, style: AppTextStyles.caption)),
      ],
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.item});

  final IndentCompletedItem item;

  @override
  Widget build(BuildContext context) {
    final rating = item.rating;
    final feedback = item.feedback;

    if (item.waitingFeedback) {
      return Text(
        'Waiting for feedback',
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.pending,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rating != null) IndentStars(rating: rating),
        if (feedback != null) ...[
          const SizedBox(height: 4),
          Text(
            feedback,
            style: AppTextStyles.caption.copyWith(
              height: 1.4,
              color: AppColors.textMid,
            ),
          ),
        ],
        if (rating == null && feedback == null)
          Text('No feedback given', style: AppTextStyles.caption),
      ],
    );
  }
}
