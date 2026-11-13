import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../../core/theme/app_colors.dart';

/// Soft green gradient header of the stock opname start screen. It extends
/// under the status bar, so the status bar height is added to the top padding.
class OpnameHeroHeader extends StatelessWidget {
  const OpnameHeroHeader({
    super.key,
    required this.child,
    this.height,
    this.padding = const EdgeInsets.fromLTRB(24, 28, 24, 64),
  });

  final Widget child;

  /// Total height including the status bar; null follows the content.
  final double? height;

  /// Content padding, excluding the status bar height.
  final EdgeInsets padding;

  /// Status bar style for screens that use this header.
  static SystemUiOverlayStyle get overlayStyle => SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            AppColors.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            AppColors.isDark ? Brightness.dark : Brightness.light,
      );

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      height: height,
      padding: padding.copyWith(top: padding.top + topInset),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryLight, AppColors.bg],
        ),
      ),
      child: child,
    );
  }
}
