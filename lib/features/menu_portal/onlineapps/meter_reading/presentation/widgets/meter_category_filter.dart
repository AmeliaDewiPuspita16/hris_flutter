import 'package:material_ui/material_ui.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Tombol persegi di samping tombol jenis meter untuk membuka pilihan
/// kategori. Bertitik dan berbingkai hijau selama ada kategori yang aktif.
class MeterCategoryButton extends StatelessWidget {
  const MeterCategoryButton({
    super.key,
    required this.active,
    required this.onTap,
  });

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Filter by category',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withValues(alpha: 0.08) : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.primaryText : AppColors.border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.category_outlined,
                size: 22,
                color: active ? AppColors.primaryText : AppColors.textMid,
              ),
              if (active)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryText,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.card, width: 1.5),
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

/// Pil kecil "Town Centre ✕" yang menunjukkan kategori aktif dan melepasnya
/// sekali ketuk.
class MeterActiveCategoryChip extends StatelessWidget {
  const MeterActiveCategoryChip({
    super.key,
    required this.label,
    required this.onClear,
  });

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onClear,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 14, color: AppColors.primaryText),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.close_rounded, size: 16, color: AppColors.primaryText),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet pilihan kategori ([categories] dari server).
///
/// Mengembalikan `(label: ...)` saat user memilih — `label` null berarti
/// "All categories" — atau null bila sheet ditutup tanpa memilih. Record
/// dipakai supaya "pilih Semua" bisa dibedakan dari "batal".
Future<({String? label})?> showMeterCategorySheet(
  BuildContext context, {
  required List<String> categories,
  required String? selectedLabel,
}) {
  return showModalBottomSheet<({String? label})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategorySheet(
      categories: categories,
      selectedLabel: selectedLabel,
    ),
  );
}

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({required this.categories, required this.selectedLabel});

  final List<String> categories;
  final String? selectedLabel;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.7),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, media.padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Category',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                _CategoryOption(
                  label: 'All categories',
                  selected: selectedLabel == null,
                  onTap: () => Navigator.pop(context, (label: null)),
                ),
                for (final category in categories)
                  _CategoryOption(
                    label: category,
                    selected: selectedLabel == category,
                    onTap: () => Navigator.pop(context, (label: category)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primaryText : AppColors.text,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
