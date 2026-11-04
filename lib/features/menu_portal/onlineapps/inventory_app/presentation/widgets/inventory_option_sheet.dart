import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/inventory_menu.dart';

/// Bottom sheet pilihan untuk alur menu Inventory ("Choose App", lalu
/// "Request" -> product line). Bentuknya sama dengan
/// `ChooseRequestTypeSheet` di Work Order.
///
/// Mengembalikan [InventoryOption.value] yang dipilih lewat Navigator.pop,
/// atau null kalau ditutup tanpa memilih. Opsi yang belum siap tampil redup
/// dengan label "Coming soon" dan tidak bisa diketuk.
class InventoryOptionSheet<T> extends StatelessWidget {
  const InventoryOptionSheet({
    super.key,
    required this.title,
    required this.options,
  });

  final String title;
  final List<InventoryOption<T>> options;

  /// Pembuka singkat: `await InventoryOptionSheet.show(context, ...)`.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<InventoryOption<T>> options,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InventoryOptionSheet<T>(title: title, options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            for (final option in options) ...[
              _OptionTile<T>(
                option: option,
                onTap: option.ready
                    ? () => Navigator.of(context).pop(option.value)
                    : null,
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  const _OptionTile({required this.option, required this.onTap});

  final InventoryOption<T> option;

  /// Null = belum siap ("Coming soon").
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ready = option.ready;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: ready ? 1 : 0.6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ready ? AppColors.primaryLight : AppColors.neutralBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  option.icon,
                  size: 19,
                  color: ready ? AppColors.primaryText : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (ready)
                Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted)
              else
                Text(
                  'Coming soon',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
