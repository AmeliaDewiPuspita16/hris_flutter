import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
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
import '../widgets/est_delete_dialog.dart';
import '../widgets/est_progress_timeline.dart';
import '../widgets/est_request_feedback_sheet.dart';
import 'add_est_request_screen.dart';

/// Layar detail EST Request — pengganti PDF report ("Show Details") di web,
/// berupa layar rapi ala app.
///
/// Bagian atas (identitas, deskripsi, foto) langsung tampil dari baris
/// daftar yang diketuk ([item]), jadi layar tidak kosong selagi menunggu
/// server. Bagian lain — timeline progress, rencana kerja, laporan selesai,
/// feedback — datang dari `GET /est_work_order/{id}` lewat
/// [EstRequestDetailBloc]. Semua user boleh membuka WO siapa pun.
///
/// Tombol Edit / Delete / Verify tampil sesuai flag `canEdit` / `canDelete`
/// / `canRate` dari server (hanya pemilik; edit & hapus hanya saat menunggu
/// HOD, verify hanya saat pekerjaan selesai dan belum dirating). Layar
/// menutup diri dengan `true` bila ada perubahan (diedit, dihapus, atau
/// dirating) supaya daftar dimuat ulang, `false` bila tidak.
class EstRequestDetailScreen extends StatefulWidget {
  const EstRequestDetailScreen({super.key, required this.item});

  final EstRequestItem item;

  @override
  State<EstRequestDetailScreen> createState() => _EstRequestDetailScreenState();
}

class _EstRequestDetailScreenState extends State<EstRequestDetailScreen> {
  late final EstRequestDetailBloc _bloc;

  /// True setelah WO berhasil diedit — hasil layar ini ke pemanggil.
  bool _changed = false;
  bool _deleting = false;

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

  Future<void> _edit(EstRequestItem item) async {
    if (_deleting) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddEstRequestScreen(initialItem: item)),
    );
    if (saved != true || !mounted) return;

    _changed = true;
    _bloc.add(const EstRequestDetailRefreshed());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request updated')),
    );
  }

  /// Buka sheet verifikasi + rating; bintang & catatan dikirim ke server dari
  /// dalam sheet (loading dan galat ditampilkan di sana, sheet tetap terbuka
  /// bila gagal). Begitu server menerima, detail dimuat ulang supaya status
  /// jadi Finished dan bagian Feedback User terisi.
  Future<void> _verify(EstRequestItem item) async {
    if (_deleting) return;

    final repository = context.read<EstRequestRepository>();
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EstRequestFeedbackSheet(
        description: '${item.type} · ${item.location}',
        onSubmit: (star, message) =>
            repository.submitRating(item.id, star: star, message: message),
      ),
    );

    if (sent != true || !mounted) return;

    _changed = true;
    _bloc.add(const EstRequestDetailRefreshed());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback')),
    );
  }

  Future<void> _delete(EstRequestItem item) async {
    if (_deleting) return;

    final confirmed = await EstDeleteDialog.show(context, item);
    if (!confirmed || !mounted) return;

    final repository = context.read<EstRequestRepository>();
    // Diambil sebelum await: snackbar harus tetap tampil di layar daftar
    // setelah layar ini ditutup.
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _deleting = true);
    try {
      await repository.delete(item.id);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Request deleted')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      // Mis. 422 karena HOD sudah memproses: muat ulang supaya flag
      // `can_*` dan tombolnya ikut menyesuaikan.
      _bloc.add(const EstRequestDetailRefreshed());
    } catch (e, stack) {
      AppLogger.error('Hapus EST request gagal karena galat tak terduga', e, stack);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Semua jalan keluar (tombol back, gestur, tombol sistem) membawa hasil
    // yang sama: apakah daftar perlu dimuat ulang.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'EST Work Order',
        onBack: () => Navigator.of(context).pop(_changed),
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
              icon: Icons.description_outlined,
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
                icon: Icons.block_outlined,
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
              icon: Icons.notes_outlined,
              child: Text(
                item.description,
                style: AppTextStyles.body.copyWith(height: 1.5),
              ),
            ),
            if (item.imageUrl != null)
              _SectionCard(
                title: 'Photo',
                icon: Icons.image_outlined,
                child: _NetworkPhoto(url: item.imageUrl!),
              ),
            ..._buildServerSections(state, detail),
            if (item.canRate) _VerifyButton(onPressed: () => _verify(item)),
            if (item.canEdit || item.canDelete)
              _ActionBar(
                busy: _deleting,
                onEdit: item.canEdit ? () => _edit(item) : null,
                onDelete: item.canDelete ? () => _delete(item) : null,
              ),
          ];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                for (var i = 0; i < sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: 18),
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
            icon: Icons.checklist_outlined,
            child: EstProgressTimeline(steps: detail.progress),
          ),
        if (detail.plan != null) ...[
          _SectionCard(
            title: 'Method & Material',
            icon: Icons.build_outlined,
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
            icon: Icons.fact_check_outlined,
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
            icon: Icons.handyman_outlined,
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
            icon: Icons.star_outline_rounded,
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

/// Tombol "Verify & Give Feedback" di bawah detail, tampil saat server
/// mengizinkan requester memverifikasi (`can_rate`).
class _VerifyButton extends StatelessWidget {
  const _VerifyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.star_rounded, size: 18),
        label: Text(
          'Verify & Give Feedback',
          style: AppTextStyles.buttonText.copyWith(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

/// Tombol Edit / Delete di bawah detail. Masing-masing hanya muncul kalau
/// server mengizinkan (`can_edit` / `can_delete`).
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.busy, this.onEdit, this.onDelete});

  final bool busy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onEdit != null)
          Expanded(
            child: SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(
                  'Edit',
                  style: AppTextStyles.buttonText
                      .copyWith(color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        if (onEdit != null && onDelete != null) const SizedBox(width: 10),
        if (onDelete != null)
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: busy ? null : onDelete,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delete_outline, size: 18),
                label: Text(
                  'Delete',
                  style:
                      AppTextStyles.buttonText.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hseRequest,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Satu bagian detail: judul DI LUAR kotak (ikon + huruf kapital), isi di
/// dalam [AppCard] — gaya sama dengan `PrDetailScreen` di Procurement.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: title, icon: icon),
        AppCard(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: child,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.primary,
              ),
            ),
          ),
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
