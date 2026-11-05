import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/observation_status.dart';

/// Badge status OPEN (merah) / CLOSED (hijau) — kolom "Status" di web.
class ObservationStatusPill extends StatelessWidget {
  const ObservationStatusPill({super.key, required this.status});

  final ObservationStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: status.color,
        ),
      ),
    );
  }
}
