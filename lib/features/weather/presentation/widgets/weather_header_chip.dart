import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/weather_forecast.dart';
import 'weather_icon.dart';

/// Chip cuaca kecil di header hijau Beranda: ikon, suhu, dan kondisi.
/// Ketuk untuk membuka halaman prakiraan lengkap.
class WeatherHeaderChip extends StatelessWidget {
  const WeatherHeaderChip({super.key, required this.slot, this.onTap});

  final WeatherSlot slot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Weather ${slot.tempC}°C, ${slot.conditionLabel}. Open forecast',
      excludeSemantics: true,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WeatherIcon(
                  condition: slot.condition,
                  isNight: slot.isNight,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${slot.tempC}°C',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 84),
                      child: Text(
                        slot.conditionLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 10.5,
                          height: 1.2,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
