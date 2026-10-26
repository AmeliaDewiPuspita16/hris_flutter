import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/currency_formatter.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../../../../core/widgets/detail_field_tile.dart';
import '../../data/procurement_repository.dart';
import '../../domain/pr_action.dart';
import '../../domain/pr_attachment.dart';
import '../../domain/purchase_requisition.dart';
import '../../domain/purchase_requisition_summary.dart';
import '../bloc/detail/pr_detail_bloc.dart';
import '../bloc/detail/pr_detail_event.dart';
import '../bloc/detail/pr_detail_state.dart';
import '../widgets/approval_progress_timeline.dart';
import '../widgets/document_progress_timeline.dart';
import '../widgets/pr_approval_action_bar.dart';
import '../widgets/pr_attachment_tile.dart';
import '../widgets/pr_comment_sheet.dart';
import '../widgets/pr_detail_hero.dart';
import '../widgets/pr_item_count_chip.dart';
import '../widgets/pr_item_tile.dart';
import '../widgets/pr_notes_banner.dart';
import '../widgets/pr_section_title.dart';
import '../../../../../../core/widgets/app_error_view.dart';

/// Membuka URL lampiran. Diambil alih test supaya tidak menyentuh plugin.
typedef UrlOpener = Future<bool> Function(Uri url);

/// Tahap approval yang tombol aksinya sudah boleh tampil.
///
/// Untuk sementara hanya HOD, karena baru tahap itu yang sudah diuji ke
/// server. Tahap lain ditambahkan di sini kalau sudah siap, mis.
/// 'peding_review', 'pending_dgm', dll.
const _actionableStatusCodes = {'pending_hod'};

/// Layar detail satu Purchase Requisition — padanan modal "PR Detail" di web.
///
/// Dibuka sebagai halaman penuh, bukan bottom sheet: isinya panjang (info,
/// item, lampiran, dua timeline) dan modal setinggi itu jadi sesak di HP.
///
/// [summary] dibawa dari daftar supaya nomor PR, total, dan status langsung
/// tergambar sementara rinciannya masih diambil dari server.
class PrDetailScreen extends StatelessWidget {
  const PrDetailScreen({
    super.key,
    required this.summary,
    this.repository,
    this.openUrl,
  });

  final PurchaseRequisitionSummary summary;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ProcurementRepository? repository;

  final UrlOpener? openUrl;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PrDetailBloc(
        repository: repository ?? context.read<ProcurementRepository>(),
      )..add(PrDetailRequested(summary.id)),
      child: _PrDetailView(
        summary: summary,
        openUrl: openUrl ??
            (url) => launchUrl(url, mode: LaunchMode.externalApplication),
      ),
    );
  }
}

class _PrDetailView extends StatefulWidget {
  const _PrDetailView({required this.summary, required this.openUrl});

  final PurchaseRequisitionSummary summary;
  final UrlOpener openUrl;

  @override
  State<_PrDetailView> createState() => _PrDetailViewState();
}

class _PrDetailViewState extends State<_PrDetailView> {
  final _scrollController = ScrollController();

  /// Sekali true tetap true, walau user menggulung naik lagi.
  bool _reachedBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkReachedBottom);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkReachedBottom() {
    if (_reachedBottom || !_scrollController.hasClients) return;

    // Jangan dihitung selagi rincian PR belum datang.
    if (context.read<PrDetailBloc>().state.requisition == null) return;

    final position = _scrollController.position;
    // Toleransi 24px supaya tidak harus pas sampai piksel terakhir.
    if (position.pixels >= position.maxScrollExtent - 24) {
      setState(() => _reachedBottom = true);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  Future<void> _open(BuildContext context, PrAttachment attachment) async {
    final url = attachment.openableUrl;
    if (url == null) return;

    final opened = await widget.openUrl(Uri.parse(url));
    if (opened || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tidak bisa membuka ${attachment.label}.')),
    );
  }

  Future<void> _onApprove(BuildContext context, PurchaseRequisition pr) async {
    final comment = await showCommentSheet(
      context,
      title: 'Approve PR',
      description: '${pr.prNumber} will be approved and moved to the next '
          'stage.',
      confirmLabel: 'Approve',
      icon: Icons.check_circle_outline,
      color: AppColors.primary,
      required: false,
    );
    if (comment == null || !context.mounted) return;
    context.read<PrDetailBloc>().add(
          PrActionSubmitted(PrAction.approve, comments: comment),
        );
  }

  Future<void> _onRevision(BuildContext context, PurchaseRequisition pr) async {
    final comment = await showCommentSheet(
      context,
      title: 'Return for Revision',
      description: '${pr.prNumber} will be sent back to the requestor for '
          'correction. Approval will restart from the beginning after it is '
          'resubmitted.',
      confirmLabel: 'Send for Revision',
      icon: Icons.edit_note_outlined,
      color: AppColors.accent,
    );
    if (comment == null || !context.mounted) return;
    context.read<PrDetailBloc>().add(
          PrActionSubmitted(PrAction.revision, comments: comment),
        );
  }

  Future<void> _onReject(BuildContext context, PurchaseRequisition pr) async {
    final comment = await showCommentSheet(
      context,
      title: 'Reject PR',
      description: '${pr.prNumber} will be rejected. The reason will be '
          'visible to the requestor.',
      confirmLabel: 'Reject',
      icon: Icons.block_outlined,
      color: AppColors.rejected,
    );
    if (comment == null || !context.mounted) return;
    context.read<PrDetailBloc>().add(
          PrActionSubmitted(PrAction.reject, comments: comment),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrDetailBloc, PrDetailState>(
      listenWhen: (previous, current) =>
          current.feedback != null &&
          !identical(previous.feedback, current.feedback),
      listener: (context, state) {
        final feedback = state.feedback!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(feedback.message),
              backgroundColor:
                  feedback.isError ? AppColors.rejected : AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: Scaffold(
        // Body memanjang sampai ke belakang action bar yang transparan.
        extendBody: true,
        backgroundColor: AppColors.bg,
        appBar: BackHeader(
          title: widget.summary.prNumber,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: NotificationListener<ScrollMetricsNotification>(
          // Ukuran konten berubah (data baru datang, PR pendek): cek ulang.
          onNotification: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _checkReachedBottom();
            });
            return false;
          },
          child: BlocBuilder<PrDetailBloc, PrDetailState>(
            builder: (context, state) {
              return SingleChildScrollView(
                controller: _scrollController,
                // Padding bawah besar supaya konten terakhir tidak tertutup
                // action bar.
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Kepala layar memakai rincian begitu datang, dan ringkasan
                    // dari daftar sebelum itu — status di detail lebih baru.
                    PrDetailHero(
                        requisition: state.requisition ?? widget.summary),
                    const SizedBox(height: 20),
                    _buildContent(context, state),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: BlocBuilder<PrDetailBloc, PrDetailState>(
          builder: (context, state) {
            final pr = state.requisition;

            /// Tombol hanya untuk PR yang masih berjalan di rantai approval
            /// (pending_*). Siapa yang berhak memutuskan tetap ditentukan server
            // if (pr == null) return const SizedBox.shrink();
            // if (pr == null || !pr.status.isPending) { //(PERUBAHAN 2)
            //   return const SizedBox.shrink();  //(PERUBAHAN 2)
            // }  // (PERUBAHAN 2)

            if (pr == null || !_actionableStatusCodes.contains(pr.status.code)) {
              return const SizedBox.shrink();
            }

            return PrApprovalActionBar(
              enabled: _reachedBottom,
              onLockedTap: _scrollToBottom,
              isLoading: state.isSubmitting,
              onApprove: () => _onApprove(context, pr),
              onRevision: () => _onRevision(context, pr),
              onReject: () => _onReject(context, pr),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PrDetailState state) {
    if (state.status == PrDetailStatus.failure) {
      return SizedBox(
        height: 260,
        child: AppErrorView(
          message: state.errorMessage ?? 'Gagal memuat detail PR.',
          onRetry: () => context
              .read<PrDetailBloc>()
              .add(PrDetailRequested(widget.summary.id)),
        ),
      );
    }

    final pr = state.requisition;
    if (pr == null) {
      return const ShimmerDetailSections(rowsPerSection: [4, 2, 3]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pr.rejectionReason != null) ...[
          PrNotesBanner(
            title: 'Alasan penolakan',
            body: pr.rejectionReason!,
            color: AppColors.rejected,
            background: AppColors.rejectedBg,
            icon: Icons.block_outlined,
          ),
          const SizedBox(height: 16),
        ],
        if (pr.revisionNotes != null) ...[
          PrNotesBanner(
            title: 'Catatan revisi',
            body: pr.revisionNotes!,
            color: AppColors.violet,
            background: AppColors.violetBg,
            icon: Icons.edit_note_outlined,
          ),
          const SizedBox(height: 16),
        ],
        _buildInformation(pr),
        const SizedBox(height: 18),
        _buildPurpose(pr),
        if (pr.items.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildItems(pr),
        ],
        if (pr.attachments.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildAttachments(context, pr),
        ],
        if (pr.approvalProgress.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildApprovalProgress(pr),
        ],
        if (pr.documentProgress.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildDocumentProgress(pr),
        ],
      ],
    );
  }

  Widget _buildInformation(PurchaseRequisition pr) {
    // Baris yang nilainya kosong dilewati daripada menampilkan deretan "—".
    final rows = <({String label, String value})>[
      (label: 'Date', value: DateFormatter.shortDate(pr.prDate)),
      (label: 'Department', value: pr.department),
      (label: 'Section', value: pr.section),
      (label: 'Requestor', value: pr.requestor),
      if (pr.requiredDate != null)
        (
          label: 'Required Date',
          value: DateFormatter.shortDate(pr.requiredDate!)
        ),
      if (pr.priority != null) (label: 'Priority', value: pr.priority!),
      if (pr.paperRef != null) (label: 'Paper Ref', value: pr.paperRef!),
      if (pr.submittedAt != null)
        (label: 'Submitted', value: DateFormatter.dateTimeID(pr.submittedAt!)),
      if (pr.approvedAt != null)
        (label: 'Approved', value: DateFormatter.dateTimeID(pr.approvedAt!)),
    ].where((row) => row.value.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrSectionTitle(
          title: 'INFORMASI',
          icon: Icons.description_outlined,
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                DetailFieldTile(
                  label: rows[i].label,
                  value: rows[i].value,
                  showDivider: i != rows.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurpose(PurchaseRequisition pr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrSectionTitle(title: 'PURPOSE', icon: Icons.flag_outlined),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Text(
            pr.purpose,
            style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildItems(PurchaseRequisition pr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrSectionTitle(
          title: 'ITEMS',
          icon: Icons.list_alt_outlined,
          trailing: PrItemCountChip(label: pr.itemCountLabel),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final item in pr.items)
                PrItemTile(item: item, showDivider: true),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    // Labelnya yang mengalah kalau ruang kurang — nominal
                    // total tidak boleh terpotong.
                    const Expanded(
                      child: Text(
                        'Estimated Total',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatRupiah(pr.totalEstimatedAmount),
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachments(BuildContext context, PurchaseRequisition pr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrSectionTitle(title: 'ATTACHMENTS', icon: Icons.attach_file),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < pr.attachments.length; i++)
                PrAttachmentTile(
                  attachment: pr.attachments[i],
                  showDivider: i != pr.attachments.length - 1,
                  onOpen: pr.attachments[i].openableUrl == null
                      ? null
                      : () => _open(context, pr.attachments[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalProgress(PurchaseRequisition pr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrSectionTitle(
          title: 'APPROVAL PROGRESS',
          icon: Icons.checklist_outlined,
        ),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: ApprovalProgressTimeline(steps: pr.approvalProgress),
        ),
      ],
    );
  }

  Widget _buildDocumentProgress(PurchaseRequisition pr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrSectionTitle(
          title: 'PROGRESS DOKUMEN',
          icon: Icons.account_tree_outlined,
        ),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: DocumentProgressTimeline(stages: pr.documentProgress),
        ),
      ],
    );
  }
}
