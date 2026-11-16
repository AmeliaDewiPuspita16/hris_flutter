import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/widgets/status_badge.dart';
import '../../domain/opname_record.dart';
import 'opname_text_styles.dart';

/// Opname status badge: Draft (amber, like the web), Confirmed (green).
class OpnameStatusBadge extends StatelessWidget {
  final OpnameStatus status;

  const OpnameStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case OpnameStatus.confirmed:
        return StatusBadge.custom(
          label: 'Confirmed',
          color: OpnameTextStyles.success,
          background: AppColors.presentBg,
        );
      case OpnameStatus.draft:
        return StatusBadge.custom(
          label: 'Draft',
          color: AppColors.pending,
          background: AppColors.pendingBg,
        );
      case OpnameStatus.other:
        return StatusBadge.custom(
          label: 'Other',
          color: AppColors.textMuted,
          background: AppColors.neutralBg,
        );
    }
  }
}
