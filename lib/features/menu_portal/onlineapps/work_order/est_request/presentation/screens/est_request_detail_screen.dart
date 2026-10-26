import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../../../../../../core/widgets/detail_field_tile.dart';
import '../../data/est_request_repository.dart';
import '../../domain/est_request_detail.dart';
import '../../domain/est_request_item.dart';
import '../bloc/detail/est_request_detail_bloc.dart';
import '../bloc/detail/est_request_detail_event.dart';
import '../bloc/detail/est_request_detail_state.dart';
import '../widgets/est_progress_timeline.dart';

/// Layar detail EST Request — pengganti PDF report ("Show Details") di web,
/// berupa layar rapi ala app.
///
/// Bagian atas (identitas, deskripsi, foto) langsung tampil dari baris
/// daftar yang diketuk ([item]), jadi layar tidak kosong selagi menunggu
/// server. Bagian lain — timeline progress, rencana kerja, laporan selesai,
/// feedback — datang dari `GET /est_work_order/{id}` lewat
/// [EstRequestDetailBloc]. Semua user boleh membuka WO siapa pun.
///
/// TODO(est): tombol "Verify & Give Feedback" (saat `canRate`) menyusul
/// bersama endpoint rating.
class EstRequestDetailScreen extends StatefulWidget {
  const EstRequestDetailScreen({super.key, required this.item});

  final EstRequestItem item;

  @override
  State<EstRequestDetailScreen> createState() => _EstRequestDetailScreenState();
}

class _EstRequestDetailScreenState extends State<EstRequestDetailScreen> {
  late final EstRequestDetailBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = EstRequestDetailBloc(
      repository: context.read<EstRequestRepository>(),
      id: widget.item.id,
    )..add(const EstRequestDetailStarted());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  /// Menunggu sampai muat ulang selesai supaya indikator tarik-refresh
  /// berhenti tepat saat datanya sudah datang.
  Future<void> _refresh() async {
    _bloc.add(const EstRequestDetailRefreshed());
    await _bloc.stream
        .firstWhere((s) => s.status != EstRequestDetailStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'EST Work Order',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: BlocBuilder<EstRequestDetailBloc, EstRequestDetailState>(
        bloc: _bloc,
        builder: (context, state) {
          final detail = state.detail;
          // Data dari server lebih baru daripada baris daftar, jadi dipakai
          // begitu sudah ada.
          final item = detail?.item ?? widget.item;

          final sections = <Widget>[
            _SectionCard(
              title: 'Request',
              child: Column(
                children: [
                  DetailFieldTile(label: 'Name', value: item.requesterName),
                  DetailFieldTile(label: 'Department', value: item.department),
                  DetailFieldTile(label: 'Date', value: item.date),
                  DetailFieldTile(label: 'Type of Request', value: item.type),
                  DetailFieldTile(label: 'Location', value: item.location),
                  DetailFieldTile(
                    label: 'Status',
                    value: item.status.label,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            if (item.rejectReason != null)
              _SectionCard(
                title: 'Reject reason',
                child: Text(
                  item.rejectReason!,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.rejected,
                    height: 1.5,
                  ),
                ),
              ),
            _SectionCard(
              title: 'Description of request',
              child: Text(
                item.description,
                style: AppTextStyles.body.copyWith(height: 1.5),
              ),
            ),
            if (item.imageUrl != null)
              _SectionCard(
                title: 'Photo',
                child: _NetworkPhoto(url: item.imageUrl!),
              ),
            ..._buildServerSections(state, detail),
          ];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                for (var i = 0; i < sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  sections[i],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Bagian yang butuh respons detail: skeleton selagi memuat, kartu galat
  /// bila gagal, selain itu timeline + rencana + laporan + feedback.
  List<Widget> _buildServerSections(
    EstRequestDetailState state,
    EstRequestDetail? detail,
  ) {
    if (state.isFirstLoad) {
      return const [_DetailSkeleton()];
    }

    return [
      if (detail != null) ...[
        if (detail.progress.isNotEmpty)
          _SectionCard(
            title: 'Progress',
            child: EstProgressTimeline(steps: detail.progress),
          ),
        if (detail.plan != null) ...[
          _SectionCard(
            title: 'Method & Material',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Method', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  detail.plan!.workingMethod,
                  style: AppTextStyles.body.copyWith(height: 1.5),
                ),
                const SizedBox(height: 14),
                Text('Material and Tools', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  detail.plan!.materialAndTools,
                  style: AppTextStyles.body.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Approval',
            child: Column(
              children: [
                DetailFieldTile(
                  label: 'Duration',
                  value: detail.plan!.durationLabel,
                ),
                DetailFieldTile(
                  label: 'Man Power',
                  value: '${detail.plan!.manPower ?? '-'}',
                ),
                DetailFieldTile(
                  label: 'Approve By',
                  value: detail.plan!.approvedBy ?? '-',
                ),
                DetailFieldTile(
                  label: 'Date Approve',
                  value: detail.plan!.approvedAt ?? '-',
                ),
                DetailFieldTile(
                  label: 'Approval Status',
                  value: detail.plan!.approvalLabel,
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
        if (detail.finish != null)
          _SectionCard(
            title: 'Work Implementation',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailFieldTile(
                  label: 'Start Date',
                  value: detail.finish!.dateStart,
                ),
                DetailFieldTile(
                  label: 'End Date',
                  value: detail.finish!.dateEnd,
                ),
                DetailFieldTile(
                  label: 'Work By',
                  value: detail.finish!.workBy,
                  showDivider: detail.finish!.imageUrl != null,
                ),
                if (detail.finish!.imageUrl != null) ...[
                  const SizedBox(height: 10),
                  _NetworkPhoto(url: detail.finish!.imageUrl!),
                ],
              ],
            ),
          ),
        if (detail.finish != null ||
            detail.item.rating != null ||
            detail.feedback != null)
          _SectionCard(
            title: 'Feedback User',
            child: _FeedbackBody(
              rating: detail.item.rating,
              feedback: detail.feedback,
            ),
          ),
      ],
      if (state.status == EstRequestDetailStatus.failure)
        _InlineError(
          message: state.errorMessage ?? 'Failed to load the request detail.',
          onRetry: () => _bloc.add(const EstRequestDetailRefreshed()),
        ),
    ];
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Foto dari server. Server bisa mengirim `.heic` yang tidak bisa
/// ditampilkan di semua perangkat, jadi galat gambar ditangani dengan
/// pesan, bukan dibiarkan merah.
class _NetworkPhoto extends StatelessWidget {
  const _NetworkPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            height: 190,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (context, error, stack) => Container(
          width: double.infinity,
          height: 80,
          alignment: Alignment.center,
          color: AppColors.neutralBg,
          child: Text(
            'Photo cannot be displayed.',
            style: AppTextStyles.caption,
          ),
        ),
      ),
    );
  }
}

class _FeedbackBody extends StatelessWidget {
  const _FeedbackBody({required this.rating, required this.feedback});

  final int? rating;
  final String? feedback;

  @override
  Widget build(BuildContext context) {
    final hasText = feedback != null;
    final placeholder = rating == null
        ? 'No feedback from the requester yet.'
        : 'No written feedback.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rating != null) ...[
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 20,
                  color: AppColors.accent,
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Text(
          feedback ?? placeholder,
          style: AppTextStyles.body.copyWith(
            color: hasText ? AppColors.text : AppColors.textMuted,
            fontStyle: hasText ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.rejected,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton untuk bagian yang menunggu respons detail: kartu timeline dan
/// kartu rencana kerja.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ShimmerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLine(width: 90, height: 14),
              SizedBox(height: 14),
              ShimmerLine(width: 170, height: 11),
              SizedBox(height: 12),
              ShimmerLine(width: 150, height: 11),
              SizedBox(height: 12),
              ShimmerLine(width: 190, height: 11),
            ],
          ),
        ),
        SizedBox(height: 12),
        ShimmerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLine(width: 130, height: 14),
              SizedBox(height: 14),
              ShimmerLine(height: 11),
              SizedBox(height: 8),
              ShimmerLine(width: 200, height: 11),
            ],
          ),
        ),
      ],
    );
  }
}
