import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/installed_meter.dart';
import '../../domain/meter_value_format.dart';
import 'meter_type_avatar.dart';

/// Satu meter terpasang: S/N dan catatan, lalu tiga angka — sebelumnya,
/// terakhir, dan pemakaian.
class InstalledMeterTile extends StatelessWidget {
  const InstalledMeterTile({
    super.key,
    required this.meter,
    this.showDivider = true,
  });

  final InstalledMeter meter;
  final bool showDivider;

  String _format(num? value) => value == null ? '—' : formatMeterValue(value);

  @override
  Widget build(BuildContext context) {
    final remark = meter.remark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MeterTypeAvatar(type: meter.type, size: 32, soft: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'S/N ${meter.serialNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  if (remark != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.neutralBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(remark, style: AppTextStyles.caption),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.neutralBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _Stat(label: 'PREVIOUS', value: _format(meter.previousValue)),
                    _Stat(
                      label: 'LAST',
                      value: _format(meter.lastValue),
                      emphasized: true,
                    ),
                    _Stat(
                      label: 'USAGE',
                      value: _format(meter.consumption),
                      emphasized: meter.consumption != null,
                      color: meter.consumption == null ? null : AppColors.present,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, thickness: 1, color: AppColors.border),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.color,
  });

  final Color? color;

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              color: color ?? (emphasized ? AppColors.primaryText : AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
