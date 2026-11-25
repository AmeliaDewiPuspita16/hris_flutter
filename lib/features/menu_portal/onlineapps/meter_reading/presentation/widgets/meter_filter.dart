import 'package:material_ui/material_ui.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/meter_type.dart';

/// Hasil sheet filter: kode jenis meter (`kwh` / `m3`) dan kategori. Null
/// berarti "semua".
typedef MeterFilterSelection = ({String? typeCode, String? category});

/// Satu tombol persegi di samping kolom cari untuk membuka sheet filter
/// (jenis meter + kategori)
class MeterFilterButton extends StatelessWidget {
  const MeterFilterButton({
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
      label: 'Filter meters',
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
                Icons.tune_rounded,
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

/// Pil kecil "kWh x" yang menunjukkan jenis aktif dan melepasnya sekali ketuk.
class MeterActiveTypeChip extends StatelessWidget {
  const MeterActiveTypeChip({
    super.key,
    required this.type,
    required this.onClear,
  });

  final MeterType type;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _ActiveChip(icon: type.icon, label: type.label, onClear: onClear);
  }
}

/// Pil kecil "Town Centre x" yang menunjukkan kategori aktif dan melepasnya
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
    return _ActiveChip(
      icon: Icons.category_outlined,
      label: label,
      onClear: onClear,
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({
    required this.icon,
    required this.label,
    required this.onClear,
  });

  final IconData icon;
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
            Icon(icon, size: 14, color: AppColors.primaryText),
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

/// Bottom sheet filter: jenis meter dan kategori ([categories] dari server)
/// dipilih sekaligus, lalu diterapkan dengan tombol "Apply".
///
/// Mengembalikan pilihan saat "Apply" ditekan, atau null bila sheet ditutup
/// tanpa menerapkan. Pilihan sebelum "Apply" hanya hidup di sheet, jadi
/// satu kali "Apply" = satu permintaan ke server.
Future<MeterFilterSelection?> showMeterFilterSheet(
  BuildContext context, {
  required List<String> categories,
  required String? typeCode,
  required String? category,
}) {
  return showModalBottomSheet<MeterFilterSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterSheet(
      categories: categories,
      typeCode: typeCode,
      category: category,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.categories,
    required this.typeCode,
    required this.category,
  });

  final List<String> categories;
  final String? typeCode;
  final String? category;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _typeCode = widget.typeCode;
  late String? _category = widget.category;

  bool get _hasSelection => _typeCode != null || _category != null;

  void _reset() => setState(() {
        _typeCode = null;
        _category = null;
      });

  void _apply() =>
      Navigator.pop(context, (typeCode: _typeCode, category: _category));

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, media.padding.bottom + 16),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filters',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              TextButton(
                onPressed: _hasSelection ? _reset : null,
                child: Text(
                  'Reset',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Meter type'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChoiceChip(
                        icon: Icons.apps_rounded,
                        label: 'All types',
                        selected: _typeCode == null,
                        onTap: () => setState(() => _typeCode = null),
                      ),
                      _ChoiceChip(
                        icon: MeterType.electricity.icon,
                        label: 'Electricity (${MeterType.electricity.unit})',
                        selected: _typeCode == MeterType.electricity.code,
                        onTap: () => setState(
                          () => _typeCode = MeterType.electricity.code,
                        ),
                      ),
                      _ChoiceChip(
                        icon: MeterType.water.icon,
                        label: 'Water (${MeterType.water.unit})',
                        selected: _typeCode == MeterType.water.code,
                        onTap: () => setState(
                          () => _typeCode = MeterType.water.code,
                        ),
                      ),
                    ],
                  ),
                  // Tanpa daftar dari server, bagian kategori disembunyikan.
                  if (widget.categories.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const _SectionLabel('Category'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ChoiceChip(
                          label: 'All categories',
                          selected: _category == null,
                          onTap: () => setState(() => _category = null),
                        ),
                        for (final category in widget.categories)
                          _ChoiceChip(
                            label: category,
                            selected: _category == category,
                            onTap: () => setState(() => _category = category),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                textStyle: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textMid,
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primaryText : AppColors.text;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.primary.withValues(alpha: 0.10) : AppColors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primaryText : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: foreground,
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
