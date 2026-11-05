import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Kategori temuan — sama dengan pilihan filter "Category" di web.
enum ObservationCategory {
  quality,
  health,
  safety,
  environment,
  security;

  String get label => switch (this) {
        ObservationCategory.quality => 'Quality',
        ObservationCategory.health => 'Health',
        ObservationCategory.safety => 'Safety',
        ObservationCategory.environment => 'Environment',
        ObservationCategory.security => 'Security',
      };

  IconData get icon => switch (this) {
        ObservationCategory.quality => Icons.verified_outlined,
        ObservationCategory.health => Icons.favorite_border_rounded,
        ObservationCategory.safety => Icons.health_and_safety_outlined,
        ObservationCategory.environment => Icons.eco_outlined,
        ObservationCategory.security => Icons.shield_outlined,
      };

  Color get color => switch (this) {
        ObservationCategory.quality => AppColors.itRequest,
        ObservationCategory.health => AppColors.pink,
        ObservationCategory.safety => AppColors.orange,
        ObservationCategory.environment => AppColors.teal,
        ObservationCategory.security => AppColors.violet,
      };

  Color get background => switch (this) {
        ObservationCategory.quality => AppColors.itRequestBg,
        ObservationCategory.health => AppColors.pinkBg,
        ObservationCategory.safety => AppColors.orangeBg,
        ObservationCategory.environment => AppColors.tealBg,
        ObservationCategory.security => AppColors.violetBg,
      };

  /// Hanya Safety yang punya sub-jenis di data web: "Safety (Nearmiss)" dan
  /// "Safety (Unsafe condition)". Daftar ini perlu dicocokkan dengan pilihan
  /// asli di form Add web.
  List<String> get subCategories => switch (this) {
        ObservationCategory.safety => const ['Nearmiss', 'Unsafe condition'],
        _ => const [],
      };
}
