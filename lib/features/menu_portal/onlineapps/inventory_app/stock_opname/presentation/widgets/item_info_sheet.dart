import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/opname_formatters.dart';
import '../../domain/opname_item.dart';
import 'opname_text_styles.dart';

/// Data of a scanned item that is not in the count list: code, reference,
/// category and the stock of every location holding it.
///
/// Pops with the count row to open: tapping a location counts the item
/// there; "Count at ..." counts it at the scanned store / rack
/// ([scopeLabel], null when none was scanned). [onCountAt] builds the row
/// (null location = the scanned store / rack).
class ItemInfoSheet extends StatelessWidget {
  final OpnameLookup info;
  final String? scopeLabel;
  final OpnameItem Function(OpnameLookupLocation? location) onCountAt;

  const ItemInfoSheet({
    super.key,
    required this.info,
    required this.onCountAt,
    this.scopeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final details = [
      if (info.internalReference != null) 'Ref. ${info.internalReference}',
      if (info.category != null) info.category!,
      if (info.unit.isNotEmpty) info.unit,
    ].join('  ·  ');

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info.code, style: AppTextStyles.caption),
                        Text(info.name, style: OpnameTextStyles.bodyBold),
                        if (details.isNotEmpty)
                          Text(details, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Total system stock: ${formatQty(info.totalQty)} ${info.unit}',
                style: AppTextStyles.body,
              ),
            ),
            Divider(height: 16, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('LOCATIONS', style: OpnameTextStyles.sectionLabel),
            ),
            if (info.locations.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  'Not placed in any store or rack yet.',
                  style: AppTextStyles.label,
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final l in info.locations)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.place_outlined,
                          color: AppColors.primaryText,
                        ),
                        title: Text(l.label, style: AppTextStyles.body),
                        subtitle: Text(
                          'System: ${formatQty(l.systemQty)} ${info.unit}',
                          style: AppTextStyles.caption,
                        ),
                        trailing: const Icon(Icons.edit_outlined, size: 20),
                        onTap: () => Navigator.pop(context, onCountAt(l)),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: scopeLabel == null
                  ? Text(
                      info.locations.isEmpty
                          ? 'Scan a store or rack first to count this item there.'
                          : 'Tap a location to count it there, or scan a store / rack first.',
                      style: AppTextStyles.caption,
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pop(context, onCountAt(null)),
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: Text('Count at $scopeLabel'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
