import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../domain/item_request_stock_option.dart';
import 'item_request_stock_icon.dart';

/// Bottom sheet "Select Item": kolom cari + daftar barang, padanan dropdown
/// ber-search (select2) di web. Pencarian lokal atas [items] yang sudah
/// dimuat, mencocokkan kode maupun nama barang.
///
/// Mengembalikan [ItemRequestStockOption] yang dipilih lewat Navigator.pop,
/// atau null kalau ditutup tanpa memilih.
class ItemRequestStockPickerSheet extends StatefulWidget {
  const ItemRequestStockPickerSheet({
    super.key,
    required this.items,
    this.selectedId,
    this.takenIds = const {},
  });

  final List<ItemRequestStockOption> items;
  final int? selectedId;

  /// Barang yang sudah dipakai di baris lain pada form yang sama: tampil
  /// redup dan tidak bisa dipilih lagi (server menolak barang dobel).
  final Set<int> takenIds;

  static Future<ItemRequestStockOption?> show(
    BuildContext context, {
    required List<ItemRequestStockOption> items,
    int? selectedId,
    Set<int> takenIds = const {},
  }) {
    return showModalBottomSheet<ItemRequestStockOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItemRequestStockPickerSheet(
        items: items,
        selectedId: selectedId,
        takenIds: takenIds,
      ),
    );
  }

  @override
  State<ItemRequestStockPickerSheet> createState() =>
      _ItemRequestStockPickerSheetState();
}

class _ItemRequestStockPickerSheetState extends State<ItemRequestStockPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ItemRequestStockOption> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items
        .where((i) =>
            i.code.toLowerCase().contains(q) || i.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    final height = MediaQuery.sizeOf(context).height * 0.8;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        child: Container(
          height: height,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Select Item', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 10),
              AppTextField(
                controller: _searchController,
                hint: 'Search code or name...',
                icon: Icons.search,
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text('No items found',
                            style: AppTextStyles.bodyMuted),
                      )
                    : ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: results.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final option = results[index];
                          final selected = option.id == widget.selectedId;
                          final taken = widget.takenIds.contains(option.id);

                          return InkWell(
                            onTap:
                                taken ? null : () => Navigator.of(context).pop(option),
                            child: Opacity(
                              opacity: taken ? 0.45 : 1,
                              child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  _OptionThumb(option: option),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.displayLabel,
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                          ),
                                        ),
                                        if (option.stock != null ||
                                            option.category != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                              if (option.category != null)
                                                option.category!,
                                              if (option.stock != null)
                                                'Stock: ${option.stockLabel}',
                                              if (taken) 'Already added',
                                            ].join(' · '),
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    color:
                                                        AppColors.textMuted),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    Icon(Icons.check,
                                        size: 18, color: AppColors.primaryText),
                                ],
                              ),
                            ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Foto barang dari server; jatuh ke ikon tebakan bila tidak ada foto atau
/// gagal dimuat.
class _OptionThumb extends StatelessWidget {
  const _OptionThumb({required this.option});

  final ItemRequestStockOption option;

  static const _size = 36.0;

  @override
  Widget build(BuildContext context) {
    final fallback = ItemRequestStockIcon(itemName: option.name, size: _size);
    final url = option.imageUrl;
    if (url == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
