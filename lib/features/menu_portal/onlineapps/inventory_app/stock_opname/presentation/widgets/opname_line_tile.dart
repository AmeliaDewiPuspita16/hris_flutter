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
/// Two layouts, the card itself tells the status (no "Not counted" badge):
///  - NOT COUNTED: one quiet row. Grey icon, code, name, the system stock as
///    a small caption, and a "Count" button on the right.
///  - COUNTED: primary border, a green check in place of the icon, and a
///    footer with the counted quantity, the +/- difference and the
///    system stock. A pencil button edits the quantity.
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
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              children: [
                _Leading(counted: counted),
                const SizedBox(width: 12),
                Expanded(child: _Info(item: item)),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  counted
                      ? _EditButton(onEdit: onEdit!)
                      : _CountButton(onTap: onEdit!),
                ],
              ],
            ),
          ),
          if (counted) _CountedFooter(item: item),
          if (item.notes != null) _Notes(text: item.notes!),
        ],
      ),
    );
  }
}

/// Leading mark. A grey box icon while waiting; a filled check once counted,
/// so the status reads at a glance without any text.
class _Leading extends StatelessWidget {
  final bool counted;

  const _Leading({required this.counted});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: counted
          ? Container(
              key: const ValueKey('counted'),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryText,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.check_rounded, size: 22, color: AppColors.card),
            )
          : Container(
              key: const ValueKey('pending'),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: AppColors.textMid,
              ),
            ),
    );
  }
}

/// Code, name and (only while not counted) the system stock as a caption.
/// Once counted, the system stock moves to the footer.
class _Info extends StatelessWidget {
  final OpnameItem item;

  const _Info({required this.item});

  @override
  Widget build(BuildContext context) {
    final String? hint;
    if (!item.isCountable) {
      hint = 'Not in a store yet, so it cannot be counted';
    } else if (!item.isCounted) {
      hint = 'System ${formatQty(item.systemQty)} ${item.unit}';
    } else {
      hint = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.code,
          style: AppTextStyles.caption.copyWith(letterSpacing: 0.6),
        ),
        const SizedBox(height: 2),
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: OpnameTextStyles.bodyBold,
        ),
        if (hint != null) ...[
          const SizedBox(height: 3),
          Text(hint, style: AppTextStyles.caption),
        ],
      ],
    );
  }
}

/// Strip at the bottom of a COUNTED card: counted quantity on the
/// left, difference badge and system stock on the right.
class _CountedFooter extends StatelessWidget {
  final OpnameItem item;

  const _CountedFooter({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(height: 1, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Counted', style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatQty(item.countedQty!),
                          style: OpnameTextStyles.quantity.copyWith(
                            fontSize: 22,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(item.unit, style: AppTextStyles.label),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DifferenceLabel(
                    difference: item.difference,
                    unit: item.unit,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'System ${formatQty(item.systemQty)} ${item.unit}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Notes extends StatelessWidget {
  final String text;

  const _Notes({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notes_rounded, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
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
      icon: Icon(Icons.edit_outlined, color: AppColors.primaryText, size: 20),
    );
  }
}

/// Text pill for an item not counted yet. Text, not just an icon, so new
/// users immediately see the next step.
class _CountButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CountButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryText,
        side: BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
      ),
      child: const Text(
        'Count',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
