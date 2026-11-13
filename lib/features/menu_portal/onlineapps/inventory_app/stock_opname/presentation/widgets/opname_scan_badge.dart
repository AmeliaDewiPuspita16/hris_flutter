import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';

/// A primary circle with a scan icon inside a card-colored ring. Used as the
/// round scan button on the stock opname start screen.
class OpnameScanBadge extends StatelessWidget {
  const OpnameScanBadge({super.key, this.onTap, this.size = 80});

  final VoidCallback? onTap;

  /// Diameter of the primary circle (excluding the ring).
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: Colors.black38,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: size / 2,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
