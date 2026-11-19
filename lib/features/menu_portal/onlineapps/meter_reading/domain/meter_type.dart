import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Jenis meter: listrik (kWh) atau air (m³)
///
/// Kode tak dikenal jatuh ke [other] - tetap tampil, dengan warna netral,
/// alih-alih menggugurkan barisnya.
enum MeterType {
  electricity('electricity', 'kWh'),
  water('water', 'm³'),
  other('other', '');

  const MeterType(this.code, this.unit);

  final String code;

  /// Satuan siap tampil. Kosong untuk [other].
  final String unit;

  static MeterType fromCode(String code) => switch (code) {
        'electricity' => MeterType.electricity,
        'water' => MeterType.water,
        _ => MeterType.other,
      };

  String get label => this == MeterType.other ? 'Meter' : unit;

  IconData get icon => switch (this) {
        MeterType.electricity => Icons.bolt_rounded,
        MeterType.water => Icons.water_drop_rounded,
        MeterType.other => Icons.speed_rounded,
      };
      
  Color get color => switch (this) {
        MeterType.electricity => AppColors.accent,
        MeterType.water => AppColors.inProgress,
        MeterType.other => AppColors.neutral,
      };

  Color get background => switch (this) {
        MeterType.electricity => AppColors.accentBg,
        MeterType.water => AppColors.inProgressBg,
        MeterType.other => AppColors.neutralBg,
      };
}
