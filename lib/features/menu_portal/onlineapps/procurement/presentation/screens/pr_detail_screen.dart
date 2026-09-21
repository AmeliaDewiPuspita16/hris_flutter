import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/currency_formatter.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../../../../core/widgets/detail_field_tile.dart';
import '../../data/procurement_repository.dart';
import '../../domain/pr_attachment.dart';
import '../../domain/purchase_requisition.dart';
import '../../domain/purchase_requisition_summary.dart';
import '../bloc/detail/pr_detail_bloc.dart';
import '../bloc/detail/pr_detail_event.dart';
import '../bloc/detail/pr_detail_state.dart';
import '../widgets/approval_progress_timeline.dart';
import '../widgets/document_progress_timeline.dart';
import '../widgets/pr_attachment_tile.dart';
import '../widgets/pr_detail_hero.dart';
import '../widgets/pr_item_count_chip.dart';
import '../widgets/pr_item_tile.dart';
import '../widgets/pr_notes_banner.dart';
import '../widgets/pr_section_title.dart';
import '../widgets/procurement_error_view.dart';

/// Membuka URL lampiran. Diambil alih test supaya tidak menyentuh plugin.
typedef UrlOpener = Future<bool> Function(Uri url);

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

class _PrDetailView extends StatelessWidget {
  const _PrDetailView({required this.summary, required this.openUrl});

  final PurchaseRequisitionSummary summary;
  final UrlOpener openUrl;

  Future<void> _open(BuildContext context, PrAttachment attachment) async {
    final url = attachment.openableUrl;
    if (url == null) return;

    final opened = await openUrl(Uri.parse(url));
    if (opened || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tidak bisa membuka ${attachment.label}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: summary.prNumber,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: BlocBuilder<PrDetailBloc, PrDetailState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kepala layar memakai rincian begitu datang, dan ringkasan
                // dari daftar sebelum itu — status di detail lebih baru.
                PrDetailHero(requisition: state.requisition ?? summary),
                const SizedBox(height: 20),
                _buildContent(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PrDetailState state) {
    if (state.status == PrDetailStatus.failure) {
      return SizedBox(
        height: 260,
        child: ProcurementErrorView(
          message: state.errorMessage ?? 'Gagal memuat detail PR.',
          onRetry: () =>
              context.read<PrDetailBloc>().add(PrDetailRequested(summary.id)),
        ),
      );
    }

    final pr = state.requisition;
    if (pr == null) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
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
        (label: 'Required Date', value: DateFormatter.shortDate(pr.requiredDate!)),
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
