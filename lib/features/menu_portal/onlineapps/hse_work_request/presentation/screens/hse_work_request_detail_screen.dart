import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../../../../core/widgets/detail_field_tile.dart';
import '../../../../../../core/widgets/status_badge.dart';
import '../../domain/hse_checklist_catalog.dart';
import '../../domain/hse_work_request.dart';
import '../../domain/hse_request_status.dart';
import '../../domain/hse_request_category.dart';
import '../widgets/hse_checklist_group.dart';
import '../widgets/hse_choice_chip_group.dart';

/// Detail satu permit HSE
/// (info, checklist) plus kolom Acknowledge/Approval dari tabel list,
/// supaya user tidak perlu balik ke daftar untuk tahu sudah di-acknowledge
/// siapa.
class HseWorkRequestDetailScreen extends StatelessWidget {
  const HseWorkRequestDetailScreen({super.key, required this.request});

  final HseWorkRequest request;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormatter.shortDateID(request.dateStart) ==
            DateFormatter.shortDateID(request.dateEnd)
        ? DateFormatter.shortDateID(request.dateStart)
        : '${DateFormatter.shortDateID(request.dateStart)} – '
            '${DateFormatter.shortDateID(request.dateEnd)}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: request.idRegister ?? 'Detail Permit',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(request.pic, style: AppTextStyles.h2.copyWith(fontSize: 17)),
              ),
              StatusBadge(status: request.status.appStatus, label: request.status.label),
            ],
          ),
          const SizedBox(height: 4),
          Text(request.department, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 16),

          // Acknowledge & Approval — sengaja dipisah dari info umum karena
          // ini dua approver yang berbeda tahapannya di web (kolom
          // "Acknowledge" dan "Approval" terpisah di tabel List Request).
          Row(
            children: [
              Expanded(
                child: _ApprovalCard(
                  label: 'Acknowledge',
                  name: request.acknowledgeBy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ApprovalCard(
                  label: 'Approval',
                  name: request.approvalBy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Detail Pekerjaan', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                DetailFieldTile(label: 'Kategori', value: request.category.label),
                DetailFieldTile(label: 'Location', value: request.location),
                DetailFieldTile(label: 'Materials', value: request.materials),
                DetailFieldTile(label: 'Vendor', value: request.vendor ?? '-'),
                DetailFieldTile(
                  label: 'Total Workers',
                  value: '${request.totalWorkers}',
                ),
                DetailFieldTile(label: 'Date of Work', value: dateLabel, showDivider: false),
              ],
            ),
          ),
          const SizedBox(height: 16),

          HseChecklistGroup(
            title: 'General Checklist',
            options: HseChecklistCatalog.generalChecklist,
            selected: request.generalChecklist.toSet(),
            readOnly: true,
            otherController: TextEditingController(text: request.otherGeneralChecklist ?? ''),
          ),
          HseChoiceChipGroup(
            title: 'Type of Works',
            options: HseChecklistCatalog.typeOfWorks,
            selected: request.typeOfWorks.toSet(),
            readOnly: true,
            otherController: TextEditingController(text: request.otherTypeOfWork ?? ''),
          ),
          HseChoiceChipGroup(
            title: 'Personal Protective Equipment',
            options: HseChecklistCatalog.personalProtectiveEquipment,
            selected: request.ppe.toSet(),
            readOnly: true,
            otherController: TextEditingController(text: request.otherPpe ?? ''),
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.label, required this.name});

  final String label;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final isDone = name != null;

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDone ? Icons.verified_outlined : Icons.hourglass_top_outlined,
                size: 15,
                color: isDone ? AppColors.present : AppColors.pending,
              ),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name ?? 'Menunggu',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: isDone ? AppColors.text : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
