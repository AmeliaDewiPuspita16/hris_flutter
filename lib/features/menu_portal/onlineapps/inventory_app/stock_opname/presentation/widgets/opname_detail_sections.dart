import 'package:material_ui/material_ui.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/opname_formatters.dart';
import '../../domain/opname_item.dart';
import '../../domain/opname_record.dart';
import 'difference_label.dart';
import 'opname_card.dart';
import 'opname_line_tile.dart';
import 'opname_text_styles.dart';

/// Kartu putih dengan ikon dan judul di atasnya, dipakai tiap blok di detail
/// opname (impact, details, notes, progress).
class OpnameSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const OpnameSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return OpnameCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryText),
              const SizedBox(width: 8),
              Text(title, style: OpnameTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Penjelasan singkat status, supaya staf tahu apakah stok sudah berubah.
class OpnameStatusNote extends StatelessWidget {
  final OpnameDetail detail;

  const OpnameStatusNote({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final confirmed = detail.status == OpnameStatus.confirmed;
    final text = switch (detail.status) {
      OpnameStatus.draft =>
        'Draft: stock has not changed yet. System stock and differences use '
            'the current stock of each location and are recalculated when the '
            'opname is confirmed.',
      OpnameStatus.confirmed =>
        'Confirmed. Stock has been adjusted to match this count.',
      OpnameStatus.other => 'The app does not recognize this opname status.',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: confirmed ? AppColors.presentBg : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            confirmed ? Icons.check_circle_outline : Icons.info_outline,
            size: 20,
            color: confirmed ? OpnameTextStyles.success : AppColors.primaryText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.label.copyWith(
                color: confirmed
                    ? OpnameTextStyles.success
                    : AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Catatan opname dalam kartu sendiri, selebar kartu, supaya catatan panjang
/// tetap enak dibaca (di baris Details yang sempit teksnya terdesak ke
/// kanan). Teks diberi garis aksen di kirinya seperti kutipan.
class OpnameNotesCard extends StatelessWidget {
  final String notes;

  const OpnameNotesCard({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return OpnameSectionCard(
      title: 'Notes',
      icon: Icons.notes_rounded,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  color: AppColors.primaryText.withValues(alpha: 0.4),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Text(
                      notes,
                      style: AppTextStyles.body.copyWith(height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lokasi dan penghitung sebagai baris ikon yang dipisah garis tipis.
/// Catatan (notes) punya kartu sendiri: [OpnameNotesCard].
class OpnameDetailsCard extends StatelessWidget {
  final OpnameDetail detail;

  const OpnameDetailsCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final rows = <(IconData, String, String)>[
      if (d.locationLabel.isNotEmpty)
        (Icons.place_outlined, 'Location', d.locationLabel),
      (Icons.person_outline, 'Counted by', d.countedBy),
    ];

    return OpnameSectionCard(
      title: 'Opname Details',
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            _DetailRow(
              icon: rows[i].$1,
              label: rows[i].$2,
              value: rows[i].$3,
              last: i == rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.primaryText),
              const SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: Text(label, style: AppTextStyles.caption),
              ),
              Expanded(child: Text(value, style: AppTextStyles.body)),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

/// Siapa yang menyimpan hitungan dan siapa yang mengonfirmasinya (atau bahwa
/// masih menunggu), seperti blok approvals di detail work permit.
class OpnameProgressCard extends StatelessWidget {
  final OpnameDetail detail;

  const OpnameProgressCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final confirmed = d.status == OpnameStatus.confirmed;

    return OpnameSectionCard(
      title: 'Progress',
      icon: Icons.timeline_rounded,
      child: Column(
        children: [
          _StepRow(
            done: true,
            label: 'Counted & saved by',
            value: d.createdBy ?? d.countedBy,
            when: d.createdAt == null ? null : formatShortDateTime(d.createdAt!),
            last: false,
          ),
          _StepRow(
            done: confirmed,
            label: 'Confirmed by',
            value: confirmed
                ? (d.confirmedBy ?? '-')
                : 'Waiting for confirmation',
            when: confirmed && d.confirmedAt != null
                ? formatShortDateTime(d.confirmedAt!)
                : null,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final bool done;
  final String label;
  final String value;
  final String? when;
  final bool last;

  const _StepRow({
    required this.done,
    required this.label,
    required this.value,
    required this.when,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                done ? Icons.check_circle : Icons.hourglass_empty_rounded,
                size: 20,
                color: done ? OpnameTextStyles.success : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: done ? null : AppColors.textMid,
                      ),
                    ),
                    if (when != null) ...[
                      const SizedBox(height: 2),
                      Text(when!, style: AppTextStyles.caption),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

/// "What will change" (draft) / "What changed" (confirmed): baris yang
/// hitungannya beda dari stok sistem, sebagai `sistem -> hitungan` beserta
/// selisihnya. Baris yang cocok cukup disebut dalam satu kalimat.
class OpnameImpactCard extends StatelessWidget {
  final OpnameDetail detail;

  const OpnameImpactCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final draft = d.status != OpnameStatus.confirmed;
    final counted = d.items.where((e) => e.isCounted).toList();
    final changed = counted.where((e) => (e.difference ?? 0) != 0).toList();
    final same = counted.length - changed.length;

    return OpnameSectionCard(
      title: draft ? 'What will change' : 'What changed',
      icon: Icons.swap_vert_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (changed.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                draft
                    ? 'No stock will change: every count matches the system '
                        'stock.'
                    : 'No stock was changed: every count matched the system '
                        'stock.',
                style: AppTextStyles.body.copyWith(color: AppColors.textMid),
              ),
            )
          else
            for (var i = 0; i < changed.length; i++)
              _ImpactRow(item: changed[i], last: i == changed.length - 1),
          if (same > 0 && changed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Text(
                same == 1
                    ? '1 more item matches the system stock.'
                    : '$same more items match the system stock.',
                style: AppTextStyles.caption,
              ),
            ),
          if (draft)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(
                'Based on the current stock. It is recalculated when the '
                'draft is confirmed.',
                style: AppTextStyles.caption,
              ),
            ),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final OpnameItem item;
  final bool last;

  const _ImpactRow({required this.item, required this.last});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: OpnameTextStyles.bodyBold.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.code} · ${item.location}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          formatQty(item.systemQty),
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textMid,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${formatQty(item.countedQty!)} ${item.unit}',
                          style: OpnameTextStyles.bodyBold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DifferenceLabel(difference: item.difference, unit: item.unit),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

/// Daftar barang yang dihitung, dikelompokkan per lokasi sesuai urutan
/// kemunculannya. Hanya-baca: [OpnameLineTile] tanpa `onEdit`.
class OpnameItemsSection extends StatelessWidget {
  final List<OpnameItem> items;

  const OpnameItemsSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<OpnameItem>>{};
    for (final e in items) {
      groups.putIfAbsent(e.location, () => []).add(e);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Text(
            items.length == 1 ? 'Item' : 'Items (${items.length})',
            style: OpnameTextStyles.bodyBold.copyWith(fontSize: 16),
          ),
        ),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.place, size: 16, color: AppColors.primaryText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(entry.key, style: OpnameTextStyles.bodyBold),
                ),
                Text(
                  entry.value.length == 1
                      ? '1 item'
                      : '${entry.value.length} items',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          for (final item in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OpnameLineTile(item: item),
            ),
        ],
      ],
    );
  }
}
