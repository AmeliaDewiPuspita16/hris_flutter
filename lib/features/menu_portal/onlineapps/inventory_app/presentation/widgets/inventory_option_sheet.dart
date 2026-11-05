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
    this.subtitle,
  });

  final String title;

  /// Keterangan satu baris di bawah judul (opsional).
  final String? subtitle;
  final List<InventoryOption<T>> options;

  /// Pembuka singkat: `await InventoryOptionSheet.show(context, ...)`.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<InventoryOption<T>> options,
    String? subtitle,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InventoryOptionSheet<T>(
        title: title,
        subtitle: subtitle,
        options: options,
      ),
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
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 14),
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

    return Material(
      color: ready ? AppColors.card : AppColors.neutralBg.withAlpha(120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ready ? AppColors.primaryLight : AppColors.neutralBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  option.icon,
                  size: 21,
                  color: ready ? AppColors.primaryText : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  opacity: ready ? 1 : 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle,
                        style: AppTextStyles.caption.copyWith(
                          height: 1.35,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (ready)
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: AppColors.primaryText,
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neutralBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Coming soon',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
