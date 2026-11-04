import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/utils/date_formatter.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../../../../../../core/widgets/detail_field_tile.dart';
import '../../../../../../../core/widgets/user_avatar.dart';
import '../../data/it_request_repository.dart';
import '../../domain/it_request_detail.dart';
import '../../domain/it_request_file.dart';
import '../../domain/it_request_item.dart';
import '../../domain/it_request_new_employee.dart';
import '../bloc/detail/it_request_detail_bloc.dart';
import '../bloc/detail/it_request_detail_event.dart';
import '../bloc/detail/it_request_detail_state.dart';
import '../widgets/it_request_complete_sheet.dart';
import '../widgets/it_request_rating_stars.dart';
import '../widgets/it_request_respond_sheet.dart';
import '../widgets/it_request_section_title.dart';

/// Layar detail satu request IT/Media.
///
/// Susunannya mengikuti modal "Request Detail" di web: kartu Request Detail
/// (pemohon, tanggal, approval, kebutuhan, deskripsi, lampiran), lalu IT
/// Handling (progres, checking, pengerja, catatan, foto bukti), lalu Rating
/// & Feedback.
///
/// [item] dibawa dari daftar supaya kartu Request Detail langsung tergambar
/// sementara rinciannya masih diambil dari server. Pola sama dengan
/// `PrDetailScreen` di Procurement Monitoring.
///
/// [onItTeamActionDone] diisi HANYA saat layar ini dibuka dari tab "List
/// Request" tim IT (lih. `ListRequestTab`) — kehadirannya yang menentukan
/// apakah action bar Respond/Complete Request ditampilkan, BUKAN flag
/// terpisah, supaya staff biasa yang membuka request miliknya sendiri lewat
/// "Form IT & Media" tidak pernah melihat aksi yang bukan wewenangnya
/// (server toh menolak lewat role, tapi UI tidak perlu menawarkannya).
/// Dipanggil dengan rincian terbaru setelah respond/complete berhasil,
/// supaya pemanggil (daftar) bisa menyinkronkan baris yang sama.
class ItRequestDetailScreen extends StatelessWidget {
  const ItRequestDetailScreen({
    super.key,
    required this.item,
    this.repository,
    this.onItTeamActionDone,
  });

  final ItRequestItem item;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ItRequestRepository? repository;

  final ValueChanged<ItRequestDetail>? onItTeamActionDone;

  @override
  Widget build(BuildContext context) {
    final resolvedRepository = repository ?? context.read<ItRequestRepository>();

    return BlocProvider(
      create: (_) => ItRequestDetailBloc(repository: resolvedRepository)
        ..add(ItRequestDetailRequested(item.id)),
      child: _ItRequestDetailView(
        item: item,
        repository: resolvedRepository,
        onItTeamActionDone: onItTeamActionDone,
      ),
    );
  }
}

class _ItRequestDetailView extends StatelessWidget {
  const _ItRequestDetailView({
    required this.item,
    required this.repository,
    this.onItTeamActionDone,
  });

  final ItRequestItem item;
  final ItRequestRepository repository;
  final ValueChanged<ItRequestDetail>? onItTeamActionDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Request Detail #${item.id}',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: BlocBuilder<ItRequestDetailBloc, ItRequestDetailState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildSections(context, state),
            ),
          );
        },
      ),
      bottomNavigationBar: onItTeamActionDone == null
          ? null
          : BlocBuilder<ItRequestDetailBloc, ItRequestDetailState>(
              builder: (context, state) =>
                  _buildItTeamActionBar(context, state) ?? const SizedBox.shrink(),
            ),
    );
  }

  Widget? _buildItTeamActionBar(BuildContext context, ItRequestDetailState state) {
    final detail = state.detail;
    if (detail == null) return null;

    final String label;
    final Future<ItRequestDetail?> Function(BuildContext) openSheet;
    switch (detail.status.code) {
      case 'waiting':
        label = 'Respond';
        openSheet = (ctx) => showModalBottomSheet<ItRequestDetail>(
              context: ctx,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ItRequestRespondSheet(detail: detail, repository: repository),
            );
      case 'progress':
        label = 'Complete Request';
        openSheet = (ctx) => showModalBottomSheet<ItRequestDetail>(
              context: ctx,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ItRequestCompleteSheet(detail: detail, repository: repository),
            );
      default:
        // Status lain (sudah complete, done, finished, dst) tidak punya
        // aksi tim IT lagi di layar ini.
        return null;
    }

    final detailBloc = context.read<ItRequestDetailBloc>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final updated = await openSheet(context);
                if (updated == null) return;

                detailBloc.add(ItRequestDetailUpdated(updated));
                onItTeamActionDone?.call(updated);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(label, style: AppTextStyles.buttonText.copyWith(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, ItRequestDetailState state) {
    final detail = state.detail;
    // Kartu Request Detail memakai rincian begitu datang, dan item dari
    // daftar sebelum itu — status/approval di detail lebih baru.
    final head = detail ?? item;

    final Widget rest;
    if (state.status == ItRequestDetailStatus.failure) {
      rest = SizedBox(
        height: 260,
        child: AppErrorView(
          message: state.errorMessage ?? 'Failed to load the request detail.',
          onRetry: () =>
              context.read<ItRequestDetailBloc>().add(ItRequestDetailRequested(item.id)),
        ),
      );
    } else if (detail == null) {
      rest = const ShimmerDetailSections();
    } else {
      rest = _buildDetailSections(detail);
    }

    return [
      if (detail?.cancelReason != null) ...[
        _CancelBanner(reason: detail!.cancelReason!),
        const SizedBox(height: 16),
      ],
      _buildRequestDetail(head, detail),
      const SizedBox(height: 16),
      rest,
    ];
  }

  // ---------------------------------------------------------------------
  // REQUEST DETAIL
  // ---------------------------------------------------------------------

  Widget _buildRequestDetail(ItRequestItem head, ItRequestDetail? detail) {
    final requester = head.requester;
    final approvedAt = detail?.approvedAt;
    final attachment = detail?.attachment;

    return _SectionCard(
      title: 'REQUEST DETAIL',
      icon: Icons.assignment_outlined,
      trailing: _Badge(
        label: head.status.label,
        color: head.status.color,
        background: head.status.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldRow(
            left: _Field(
              label: 'REQUESTOR',
              child: requester == null
                  ? const _Value('-')
                  : _PersonLine(name: requester.name),
            ),
            right: _Field(
              label: 'DEPARTMENT',
              child: _Value(requester?.department ?? '-'),
            ),
          ),
          _FieldRow(
            left: _Field(
              label: 'REQUESTED ON',
              child: _Value(DateFormatter.shortDate(head.createdAt)),
            ),
            right: _Field(
              label: 'REQUEST TYPE',
              child: _Value(_requestType(head)),
            ),
          ),
          _FieldRow(
            left: _Field(
              label: 'APPROVAL STATUS',
              child: Align(
                alignment: Alignment.centerLeft,
                child: _approvalBadge(head.approval.code, head.approval.label),
              ),
            ),
            right: _Field(
              label: 'APPROVED ON',
              child: _Value(
                approvedAt == null ? '-' : DateFormatter.shortDate(approvedAt.toLocal()),
              ),
            ),
          ),
          Divider(height: 20, color: AppColors.border),
          _Field(
            label: 'WHAT DO YOU NEED?',
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Badge(
                label: head.category.label,
                color: Colors.white,
                background: AppColors.primary,
              ),
            ),
          ),
          if (detail != null && detail.needs.isNotEmpty)
            _Field(
              label: 'EQUIPMENT',
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final need in detail.needs)
                    _Badge(
                      label: need.label,
                      color: Colors.white,
                      background: AppColors.teal,
                    ),
                ],
              ),
            ),
          if (detail?.specifiedApplication != null)
            _Field(label: 'APPLICATION', child: _Value(detail!.specifiedApplication!)),
          if (detail?.specifiedUsername != null)
            _Field(label: 'USERNAME', child: _Value(detail!.specifiedUsername!)),
          if (detail?.specifiedOther != null)
            _Field(label: 'OTHERS', child: _Value(detail!.specifiedOther!)),
          _Field(
            label: 'DESCRIPTION',
            child: _NoteBox(text: head.description),
          ),
          // Lampiran hanya diketahui dari rincian; sebelum itu disembunyikan
          // supaya tidak sempat tertulis "No attachment." lalu berubah.
          if (detail != null)
            _Field(
              label: 'ATTACHMENT',
              bottomSpacing: 0,
              child: attachment == null
                  ? Text(
                      'No attachment.',
                      style: AppTextStyles.bodyMuted.copyWith(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : _AttachmentLink(file: attachment),
            ),
        ],
      ),
    );
  }

  static String _requestType(ItRequestItem head) {
    final support = head.supportType.trim();
    return support.isEmpty ? head.type.label : '${head.type.label} ($support)';
  }

  static Widget _approvalBadge(String code, String label) {
    final (color, background) = switch (code) {
      'approved' => (AppColors.present, AppColors.presentBg),
      'rejected' || 'cancelled' => (AppColors.rejected, AppColors.rejectedBg),
      'waiting' || 'pending' => (AppColors.pending, AppColors.pendingBg),
      _ => (AppColors.neutral, AppColors.neutralBg),
    };
    return _Badge(
      label: label.isEmpty ? '-' : label,
      color: AppColors.isDark ? color : Colors.white,
      background: AppColors.isDark ? background : color,
    );
  }

  // ---------------------------------------------------------------------
  // IT HANDLING, NEW EMPLOYEE, RATING
  // ---------------------------------------------------------------------

  Widget _buildDetailSections(ItRequestDetail detail) {
    final newEmployee = detail.newEmployee;
    final hasNewEmployee = newEmployee != null &&
        (newEmployee.fullName != null ||
            newEmployee.employeeNumber != null ||
            newEmployee.department != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasNewEmployee) ...[
          for (var i = 0; i < 1 + newEmployee.additional.length; i++) ...[
            _buildNewEmployee(
              i == 0 ? newEmployee : newEmployee.additional[i - 1],
              title: newEmployee.additional.isEmpty
                  ? 'NEW EMPLOYEE'
                  : 'NEW EMPLOYEE ${i + 1}',
            ),
            const SizedBox(height: 16),
          ],
        ],
        _buildHandling(detail),
        if (detail.rating != null) ...[
          const SizedBox(height: 16),
          _buildRating(detail),
        ],
      ],
    );
  }

  Widget _buildNewEmployee(
    ItRequestNewEmployee newEmployee, {
    String title = 'NEW EMPLOYEE',
  }) {
    final rows = <({String label, String value})>[
      if (newEmployee.fullName != null)
        (label: 'Full Name', value: newEmployee.fullName!),
      if (newEmployee.employeeNumber != null)
        (label: 'Employee Number', value: newEmployee.employeeNumber!),
      if (newEmployee.executiveType != null)
        (label: 'Type', value: newEmployee.executiveType!),
      if (newEmployee.department != null)
        (label: 'Department', value: newEmployee.department!),
      if (newEmployee.section != null) (label: 'Section', value: newEmployee.section!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ItRequestSectionTitle(title: title, icon: Icons.badge_outlined),
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

  Widget _buildHandling(ItRequestDetail detail) {
    final handling = detail.handling;
    final checking = detail.checking;

    final dates = <String>[
      if (handling?.dateStart != null)
        'Started ${DateFormatter.shortDate(handling!.dateStart!)}',
      if (handling?.dateDone != null)
        'Finished ${DateFormatter.shortDate(handling!.dateDone!)}'
      else if (handling?.dateEnd != null)
        'Target ${DateFormatter.shortDate(handling!.dateEnd!)}',
    ];

    return _SectionCard(
      title: 'IT HANDLING',
      icon: Icons.build_outlined,
      iconColor: AppColors.present,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldRow(
            left: _Field(
              label: 'PROGRESS',
              child: Align(
                alignment: Alignment.centerLeft,
                child: _Badge(
                  label: detail.status.label,
                  color: detail.status.color,
                  background: detail.status.background,
                ),
              ),
            ),
            right: _Field(
              label: 'CHECKING STATUS',
              child: Align(
                alignment: Alignment.centerLeft,
                child: _Badge(
                  label: checking.checked
                      ? 'Checked'
                      : (checking.label.isEmpty ? 'Unchecked' : checking.label),
                  color: checking.checked ? AppColors.present : AppColors.neutral,
                  background:
                      checking.checked ? AppColors.presentBg : AppColors.neutralBg,
                ),
              ),
            ),
          ),
          if (handling == null)
            Text(
              'Not handled by the IT team yet.',
              style: AppTextStyles.bodyMuted.copyWith(
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            if (handling.workBy != null)
              _Field(
                label: 'WORKED ON BY',
                child: _PersonLine(
                  name: handling.workBy!,
                  subtitle: dates.isEmpty ? null : dates.join(' · '),
                ),
              ),
            if (handling.note != null)
              _Field(label: 'IT NOTES', child: _NoteBox(text: handling.note!)),
            if (handling.resultImageUrl != null)
              _Field(
                label: 'EVIDENCE PHOTO',
                bottomSpacing: 0,
                child: _EvidencePhoto(url: handling.resultImageUrl!),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRating(ItRequestDetail detail) {
    final rating = detail.rating!;
    return _SectionCard(
      title: 'RATING & FEEDBACK',
      icon: Icons.star_rounded,
      iconColor: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ItRequestRatingStars(rating: rating, size: 26),
              const SizedBox(width: 8),
              Text(
                '$rating/5',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (detail.ratingComment != null) ...[
            const SizedBox(height: 14),
            _Field(
              label: 'FEEDBACK',
              bottomSpacing: 0,
              child: _NoteBox(text: detail.ratingComment!),
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------
// Komponen kecil
// -------------------------------------------------------------------------

/// Kartu satu bagian dengan judul ber-ikon dan garis pemisah di dalamnya,
/// seperti panel di modal web.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor ?? AppColors.primaryText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          Divider(height: 22, color: AppColors.border),
          child,
        ],
      ),
    );
  }
}

/// Dua [_Field] berdampingan, seperti grid dua kolom di web.
class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

/// Label kecil kapital abu-abu di atas isinya.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.bottomSpacing = 14,
  });

  final String label;
  final Widget child;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(fontSize: 13.5, color: AppColors.text),
    );
  }
}

/// Avatar inisial + nama tebal, opsional dengan baris keterangan kecil.
class _PersonLine extends StatelessWidget {
  const _PersonLine({required this.name, this.subtitle});

  final String name;
  final String? subtitle;

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UserAvatar(
          initials: _initials(name),
          radius: 16,
          fontSize: 11,
          backgroundColor: AppColors.pinkBg,
          textColor: AppColors.pink,
          fontWeight: FontWeight.w800,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Teks panjang (deskripsi, catatan IT, feedback) dalam kotak abu-abu.
class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Foto atau dokumen yang dilampirkan pemohon. Dibuka di aplikasi lain
/// (peramban, pembaca PDF, dst.) lewat tautannya.
class _AttachmentLink extends StatelessWidget {
  const _AttachmentLink({required this.file});

  final ItRequestFile file;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutralBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => launchUrl(
          Uri.parse(file.url),
          mode: LaunchMode.externalApplication,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                file.isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
                size: 18,
                color: AppColors.primaryText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Foto bukti pengerjaan; ketuk untuk membukanya penuh di aplikasi lain.
class _EvidencePhoto extends StatelessWidget {
  const _EvidencePhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.neutralBg,
              alignment: Alignment.center,
              child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

class _CancelBanner extends StatelessWidget {
  const _CancelBanner({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rejected.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.block_outlined, size: 18, color: AppColors.rejected),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancellation reason',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.rejected,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(reason, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
