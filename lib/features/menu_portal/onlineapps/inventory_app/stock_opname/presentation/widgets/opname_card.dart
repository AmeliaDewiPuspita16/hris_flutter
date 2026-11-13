import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';

/// Bordered card used by the stock opname screens. Unlike the portal's
/// [AppCard], it has default padding, an ink ripple, and a [borderColor].
class OpnameCard extends StatelessWidget {
  const OpnameCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Defaults to [AppColors.border].
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor ?? AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
