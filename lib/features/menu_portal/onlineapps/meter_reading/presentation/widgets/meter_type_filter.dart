import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/meter_type.dart';

/// Tombol persegi di samping kolom cari untuk membuka pilihan jenis meter
/// (listrik / air). Bertitik dan berbingkai hijau selama ada jenis yang aktif.
///
/// Pengganti filter kategori: API Meter Reading hanya punya filter `type`
/// (kwh / m3), belum ada endpoint kategori.
class MeterTypeButton extends StatelessWidget {
  const MeterTypeButton({
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
      label: 'Filter by meter type',
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

/// Pil kecil "kWh ✕" yang menunjukkan jenis aktif dan melepasnya sekali ketuk.
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
            Icon(type.icon, size: 14, color: AppColors.primaryText),
            const SizedBox(width: 6),
            Text(
              type.label,
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

/// Bottom sheet pilihan jenis meter.
///
/// Mengembalikan `(code: ...)` saat user memilih — `code` null berarti "All
/// types" — atau null bila sheet ditutup tanpa memilih. Record dipakai supaya
/// "pilih Semua" bisa dibedakan dari "batal".
Future<({String? code})?> showMeterTypeSheet(
  BuildContext context, {
  required String? selectedCode,
}) {
  return showModalBottomSheet<({String? code})>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _TypeSheet(selectedCode: selectedCode),
  );
}

class _TypeSheet extends StatelessWidget {
  const _TypeSheet({required this.selectedCode});

  final String? selectedCode;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
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
            'Meter type',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          _TypeOption(
            icon: Icons.apps_rounded,
            label: 'All types',
            selected: selectedCode == null,
            onTap: () => Navigator.pop(context, (code: null)),
          ),
          _TypeOption(
            icon: MeterType.electricity.icon,
            label: 'Electricity (${MeterType.electricity.unit})',
            selected: selectedCode == MeterType.electricity.code,
            onTap: () => Navigator.pop(context, (code: MeterType.electricity.code)),
          ),
          _TypeOption(
            icon: MeterType.water.icon,
            label: 'Water (${MeterType.water.unit})',
            selected: selectedCode == MeterType.water.code,
            onTap: () => Navigator.pop(context, (code: MeterType.water.code)),
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
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
                Icon(icon, size: 20, color: selected ? AppColors.primaryText : AppColors.textMid),
                const SizedBox(width: 12),
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
