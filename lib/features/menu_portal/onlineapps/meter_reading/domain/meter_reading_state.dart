import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';

/// Apakah meter ini sudah dicatat untuk periodenya.
///
/// Di web: badge periode hijau bercentang = [recorded], kuning bertanda
/// seru = [pending].
enum MeterReadingState {
  recorded('recorded', 'Recorded'),
  pending('pending', 'Not recorded');

  const MeterReadingState(this.code, this.label);

  final String code;
  final String label;

  /// Kode tak dikenal jatuh ke [pending] — lebih baik mengaku belum dicatat
  /// daripada mengaku sudah (pola sama dengan `ApprovalState.fromCode`).
  static MeterReadingState fromCode(String code) => switch (code) {
        'recorded' => MeterReadingState.recorded,
        _ => MeterReadingState.pending,
      };

  Color get color => switch (this) {
        MeterReadingState.recorded => AppColors.present,
        MeterReadingState.pending => AppColors.accent,
      };

  Color get background => switch (this) {
        MeterReadingState.recorded => AppColors.presentBg,
        MeterReadingState.pending => AppColors.accentBg,
      };

  IconData get icon => switch (this) {
        MeterReadingState.recorded => Icons.check_circle_rounded,
        MeterReadingState.pending => Icons.error_rounded,
      };
}
