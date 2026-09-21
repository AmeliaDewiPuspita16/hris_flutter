import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/utils/date_formatter.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../../../../../../core/widgets/detail_field_tile.dart';
import '../../data/it_request_repository.dart';
import '../../domain/it_request_detail.dart';
import '../../domain/it_request_item.dart';
import '../../domain/it_request_new_employee.dart';
import '../bloc/detail/it_request_detail_bloc.dart';
import '../bloc/detail/it_request_detail_event.dart';
import '../bloc/detail/it_request_detail_state.dart';
import '../widgets/it_request_rating_stars.dart';
import '../widgets/it_request_section_title.dart';

/// Layar detail satu request IT/Media.
///
/// [item] dibawa dari daftar supaya kepala layar (status, kategori,
/// deskripsi) langsung tergambar sementara rinciannya masih diambil dari
/// server. Pola sama dengan `PrDetailScreen` di Procurement Monitoring.
class ItRequestDetailScreen extends StatelessWidget {
  const ItRequestDetailScreen({super.key, required this.item, this.repository});

  final ItRequestItem item;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ItRequestRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ItRequestDetailBloc(
        repository: repository ?? context.read<ItRequestRepository>(),
      )..add(ItRequestDetailRequested(item.id)),
      child: _ItRequestDetailView(item: item),
    );
  }
}

class _ItRequestDetailView extends StatelessWidget {
  const _ItRequestDetailView({required this.item});

  final ItRequestItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Detail Request',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: BlocBuilder<ItRequestDetailBloc, ItRequestDetailState>(
        builder: (context, state) {
          // Kepala layar memakai rincian begitu datang, dan item dari daftar
          // sebelum itu — status/rating di detail lebih baru.
          final head = state.detail ?? item;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(head),
                const SizedBox(height: 18),
                _buildContent(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ItRequestItem head) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  head.category.label,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: head.status.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  head.status.label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: head.status.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Chip(label: head.type.label),
              _Chip(label: head.supportType),
              _Chip(label: DateFormatter.shortDate(head.createdAt)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            head.description,
            style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5),
          ),
          if (head.rating != null) ...[
            const SizedBox(height: 12),
            ItRequestRatingStars(rating: head.rating!),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ItRequestDetailState state) {
    if (state.status == ItRequestDetailStatus.failure) {
      return SizedBox(
        height: 260,
        child: AppErrorView(
          message: state.errorMessage ?? 'Gagal memuat detail request.',
          onRetry: () =>
              context.read<ItRequestDetailBloc>().add(ItRequestDetailRequested(item.id)),
        ),
      );
    }

    final detail = state.detail;
    if (detail == null) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final hasSpecified = detail.specifiedApplication != null ||
        detail.specifiedUsername != null ||
        detail.specifiedOther != null;
    final newEmployee = detail.newEmployee;
    final hasNewEmployee = newEmployee != null &&
        (newEmployee.fullName != null ||
            newEmployee.employeeNumber != null ||
            newEmployee.department != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (detail.cancelReason != null) ...[
          _buildBanner(
            title: 'Alasan pembatalan',
            body: detail.cancelReason!,
            color: AppColors.rejected,
            background: AppColors.rejectedBg,
            icon: Icons.block_outlined,
          ),
          const SizedBox(height: 16),
        ],
        if (detail.requester != null) ...[
          _buildRequester(detail),
          const SizedBox(height: 18),
        ],
        if (detail.needs.isNotEmpty) ...[
          _buildNeeds(detail),
          const SizedBox(height: 18),
        ],
        if (hasSpecified) ...[
          _buildSpecified(detail),
          const SizedBox(height: 18),
        ],
        if (hasNewEmployee) ...[
          _buildNewEmployee(newEmployee),
          const SizedBox(height: 18),
        ],
        if (detail.handling != null) ...[
          _buildHandling(detail),
          const SizedBox(height: 18),
        ],
        if (detail.rating != null) _buildRating(detail),
      ],
    );
  }

  Widget _buildBanner({
    required String title,
    required String body,
    required Color color,
    required Color background,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequester(ItRequestDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ItRequestSectionTitle(title: 'REQUESTER', icon: Icons.person_outline),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              DetailFieldTile(label: 'Nama', value: detail.requester!.name),
              DetailFieldTile(
                label: 'Departemen',
                value: detail.requester!.department,
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeeds(ItRequestDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ItRequestSectionTitle(title: 'YANG DIBUTUHKAN', icon: Icons.checklist_outlined),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final need in detail.needs) _Chip(label: need.label)],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecified(ItRequestDetail detail) {
    final rows = <({String label, String value})>[
      if (detail.specifiedApplication != null)
        (label: 'Application', value: detail.specifiedApplication!),
      if (detail.specifiedUsername != null)
        (label: 'Username', value: detail.specifiedUsername!),
      if (detail.specifiedOther != null) (label: 'Lainnya', value: detail.specifiedOther!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ItRequestSectionTitle(title: 'SPESIFIKASI', icon: Icons.edit_note_outlined),
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

  Widget _buildNewEmployee(ItRequestNewEmployee newEmployee) {
    final rows = <({String label, String value})>[
      if (newEmployee.fullName != null)
        (label: 'Nama Lengkap', value: newEmployee.fullName!),
      if (newEmployee.employeeNumber != null)
        (label: 'Nomor Pegawai', value: newEmployee.employeeNumber!),
      if (newEmployee.executiveType != null)
        (label: 'Tipe', value: newEmployee.executiveType!),
      if (newEmployee.department != null)
        (label: 'Departemen', value: newEmployee.department!),
      if (newEmployee.section != null) (label: 'Section', value: newEmployee.section!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ItRequestSectionTitle(title: 'KARYAWAN BARU', icon: Icons.badge_outlined),
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
    final handling = detail.handling!;
    final rows = <({String label, String value})>[
      if (handling.workBy != null) (label: 'Dikerjakan oleh', value: handling.workBy!),
      if (handling.dateStart != null)
        (label: 'Mulai', value: DateFormatter.shortDate(handling.dateStart!)),
      if (handling.dateEnd != null)
        (label: 'Target selesai', value: DateFormatter.shortDate(handling.dateEnd!)),
      if (handling.dateDone != null)
        (label: 'Selesai', value: DateFormatter.shortDate(handling.dateDone!)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ItRequestSectionTitle(title: 'PENGERJAAN', icon: Icons.build_outlined),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++)
                DetailFieldTile(label: rows[i].label, value: rows[i].value),
              if (handling.note != null) ...[
                const SizedBox(height: 4),
                Text(
                  handling.note!,
                  style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5),
                ),
              ],
              if (handling.resultImageUrl != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    handling.resultImageUrl!,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRating(ItRequestDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ItRequestSectionTitle(title: 'RATING', icon: Icons.star_outline_rounded),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItRequestRatingStars(rating: detail.rating!, size: 22),
              if (detail.ratingComment != null) ...[
                const SizedBox(height: 8),
                Text(
                  detail.ratingComment!,
                  style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textMid,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
