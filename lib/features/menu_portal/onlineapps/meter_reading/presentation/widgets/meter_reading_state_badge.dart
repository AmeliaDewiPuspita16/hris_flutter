import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/meter_reading_state.dart';

/// Pil kecil berisi titik berwarna dan label status pencatatan.
class MeterReadingStateBadge extends StatelessWidget {
  const MeterReadingStateBadge({super.key, required this.state});

  final MeterReadingState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: state.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(state.icon, size: 13, color: state.color),
          const SizedBox(width: 5),
          Text(
            state.label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: state.color,
            ),
          ),
        ],
      ),
    );
  }
}
