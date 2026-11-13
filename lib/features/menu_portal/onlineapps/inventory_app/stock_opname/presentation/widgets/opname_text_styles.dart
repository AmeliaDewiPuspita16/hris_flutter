import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_text_styles.dart';

/// Text styles the stock opname screens need on top of the portal's
/// [AppTextStyles]. They are getters (like the portal's) so they follow the
/// light / dark mode.
class OpnameTextStyles {
  OpnameTextStyles._();

  static TextStyle get title =>
      AppTextStyles.body.copyWith(fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle get bodyBold =>
      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600);

  static TextStyle get sectionLabel =>
      AppTextStyles.caption.copyWith(letterSpacing: 0.5);

  /// Large counted / system quantity.
  static TextStyle get quantity =>
      AppTextStyles.body.copyWith(fontSize: 30, fontWeight: FontWeight.w600);
}
