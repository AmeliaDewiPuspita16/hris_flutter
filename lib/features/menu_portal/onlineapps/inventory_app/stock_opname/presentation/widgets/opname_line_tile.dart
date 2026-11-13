import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/opname_formatters.dart';
import '../../domain/opname_item.dart';
import 'difference_label.dart';
import 'opname_card.dart';
import 'opname_text_styles.dart';

/// Item card in the count list. If [onEdit] is null the card is read-only
/// (no button and not tappable), e.g. in the history detail.
///
/// Two layouts:
///  - COUNTED: primary border, large Total, +/- difference badge, and the
///    system stock on the right. A pencil button edits the quantity.
///  - NOT COUNTED: grey border, the system stock is the main figure (clearly
///    labelled so it is not mistaken for a count), and a "Count" button that
///    shows the next step.
class OpnameLineTile extends StatelessWidget {
  final OpnameItem item;
  final VoidCallback? onEdit;

  const OpnameLineTile({super.key, required this.item, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final counted = item.isCounted;

    return OpnameCard(
      onTap: onEdit,
      padding: EdgeInsets.zero,
      borderColor: counted ? AppColors.primaryText : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 22,
                    color: AppColors.textMid,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.code,
                          style: AppTextStyles.caption
                              .copyWith(letterSpacing: 0.6)),
                      const SizedBox(height: 2),
                      Text(item.name, style: OpnameTextStyles.bodyBold),
                    ],
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  counted
                      ? _EditButton(onEdit: onEdit!)
                      : _CountButton(onTap: onEdit!),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: counted
                ? _CountedBottom(item: item)
                : _UncountedBottom(item: item),
          ),
        ],
      ),
    );
  }
}

/// Bottom of a COUNTED card: large Total + difference, and the system
/// stock on the right.
class _CountedBottom extends StatelessWidget {
  final OpnameItem item;

  const _CountedBottom({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total', style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    formatQty(item.countedQty!),
                    style: OpnameTextStyles.quantity.copyWith(
                      fontSize: 28,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(item.unit, style: AppTextStyles.label),
                ],
              ),
              const SizedBox(height: 6),
              DifferenceLabel(difference: item.difference, unit: item.unit),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('System stock', style: AppTextStyles.caption),
            const SizedBox(height: 2),
            Text('${formatQty(item.systemQty)} ${item.unit}',
                style: AppTextStyles.label),
          ],
        ),
      ],
    );
  }
}

/// Bottom of a NOT COUNTED card: the system stock as the main figure, with
/// a note that the physical quantity has not been entered yet.
class _UncountedBottom extends StatelessWidget {
  final OpnameItem item;

  const _UncountedBottom({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System stock', style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    formatQty(item.systemQty),
                    style: OpnameTextStyles.quantity.copyWith(
                      fontSize: 24,
                      color: AppColors.textMid,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(item.unit, style: AppTextStyles.label),
                ],
              ),
            ],
          ),
        ),
        const _UncountedBadge(),
      ],
    );
  }
}

/// Pencil button for a counted item (edits the quantity).
class _EditButton extends StatelessWidget {
  final VoidCallback onEdit;

  const _EditButton({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Edit quantity',
      onPressed: onEdit,
      style: IconButton.styleFrom(backgroundColor: AppColors.primaryLight),
      icon: Icon(Icons.edit_outlined, color: AppColors.primaryText, size: 20),
    );
  }
}

/// "Count" button for an item not counted yet. It uses text, not just an
/// icon, so new users immediately see the next step.
class _CountButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CountButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.primaryText,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
      ),
      icon: const Icon(Icons.edit_note_rounded, size: 18),
      label: const Text(
        'Count',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// "Not counted" status marker: a grey pill, text only (no icon).
class _UncountedBadge extends StatelessWidget {
  const _UncountedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Not counted',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
