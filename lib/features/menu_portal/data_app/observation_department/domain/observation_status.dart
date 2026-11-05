import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Kolom "Status" di tabel web: badge merah OPEN / hijau CLOSE.
enum ObservationStatus {
  open,
  closed;

  String get label => switch (this) {
        ObservationStatus.open => 'Open',
        ObservationStatus.closed => 'Closed',
      };

  Color get color => switch (this) {
        ObservationStatus.open => AppColors.rejected,
        ObservationStatus.closed => AppColors.primaryMidText,
      };

  Color get background => switch (this) {
        ObservationStatus.open => AppColors.rejectedBg,
        ObservationStatus.closed => AppColors.primaryLight,
      };
}
