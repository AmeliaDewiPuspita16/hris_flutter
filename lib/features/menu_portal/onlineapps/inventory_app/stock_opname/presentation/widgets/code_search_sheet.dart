import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/opname_item.dart';
import 'opname_text_styles.dart';

/// Result of [showCodeSearchSheet]. Exactly one field is set:
/// - [rack]    : the user picked a rack from the list
/// - [item]    : the user picked an item (already specific: code + location)
/// - [rawCode] : the user pressed Enter on the keyboard with typed text
///               (processed like a scan result)
class CodeSearchResult {
  final String? rack;
  final OpnameItem? item;
  final String? rawCode;

  const CodeSearchResult.rack(String this.rack)
      : item = null,
        rawCode = null;

  const CodeSearchResult.item(OpnameItem this.item)
      : rack = null,
        rawCode = null;

  const CodeSearchResult.code(String this.rawCode)
      : rack = null,
        item = null;
}

/// Opens the rack/item search sheet. Returns null if it is closed without
/// picking anything.
Future<CodeSearchResult?> showCodeSearchSheet(
  BuildContext context, {
  required List<OpnameItem> items,
}) {
  return showModalBottomSheet<CodeSearchResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CodeSearchSheet(items: items),
  );
}

class _CodeSearchSheet extends StatefulWidget {
  final List<OpnameItem> items;

  const _CodeSearchSheet({required this.items});

  @override
  State<_CodeSearchSheet> createState() => _CodeSearchSheetState();
}

class _CodeSearchSheetState extends State<_CodeSearchSheet> {
  /// Maximum number of results per group, so the list does not get too long.
  static const int _maxRacks = 8;
  static const int _maxItems = 20;

  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Enter on the keyboard: process the text exactly like a scan result.
  void _submit(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return;
    Navigator.pop(context, CodeSearchResult.code(raw));
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();

    // Racks: unique locations containing the search text, plus item counts.
    final rackCounts = <String, int>{};
    if (q.isNotEmpty) {
      for (final e in widget.items) {
        if (e.location.toLowerCase().contains(q)) {
          rackCounts[e.location] = (rackCounts[e.location] ?? 0) + 1;
        }
      }
    }
    final racks = rackCounts.entries.take(_maxRacks).toList();

    // Items: match on code OR name.
    final items = q.isEmpty
        ? <OpnameItem>[]
        : widget.items
            .where((e) =>
                e.code.toLowerCase().contains(q) ||
                e.name.toLowerCase().contains(q))
            .take(_maxItems)
            .toList();

    final noResult = q.isNotEmpty && racks.isEmpty && items.isEmpty;

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Search racks or items', style: OpnameTextStyles.bodyBold),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: _submit,
              decoration: InputDecoration(
                hintText: 'Item code / name, or rack code',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                if (q.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Type just part of it, e.g. "004/03", "semen", '
                      'or "MLKPL".',
                      style: AppTextStyles.caption,
                    ),
                  ),
                if (noResult)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'No racks or items match "$_query".',
                      style: AppTextStyles.caption,
                    ),
                  ),
                if (racks.isNotEmpty) ...[
                  const _SectionLabel('Racks'),
                  for (final r in racks)
                    ListTile(
                      leading: Icon(Icons.place_outlined,
                          color: AppColors.primaryText),
                      title: Text(r.key, style: AppTextStyles.body),
                      subtitle:
                          Text(r.value == 1 ? '1 item' : '${r.value} items',
                              style: AppTextStyles.caption),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.pop(context, CodeSearchResult.rack(r.key)),
                    ),
                ],
                if (items.isNotEmpty) ...[
                  const _SectionLabel('Items'),
                  for (final e in items)
                    ListTile(
                      leading: Icon(Icons.inventory_2_outlined,
                          color: AppColors.primaryText),
                      title: Text(e.name, style: AppTextStyles.body),
                      subtitle: Text('${e.code}  ·  ${e.location}',
                          style: AppTextStyles.caption),
                      trailing: e.isCounted
                          ? Icon(Icons.check_circle,
                              color: AppColors.primaryText, size: 20)
                          : const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.pop(context, CodeSearchResult.item(e)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textMid,
        ),
      ),
    );
  }
}
