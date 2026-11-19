import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Gives the stock opname screens the button and input look they were
/// designed with (filled primary buttons, outlined secondary buttons, filled
/// inputs). The portal theme does not define these, so the look is scoped to
/// the opname screens instead of changing the whole portal.
///
/// Open every opname screen with [opnameRoute] so sheets and dialogs started
/// from it inherit the same theme.
class OpnameTheme extends StatelessWidget {
  const OpnameTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.card,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          border: inputBorder,
          enabledBorder: inputBorder,
          focusedBorder: inputBorder.copyWith(
            borderSide: BorderSide(color: AppColors.primaryText, width: 1.5),
          ),
          errorBorder: inputBorder.copyWith(
            borderSide: BorderSide(color: AppColors.rejected),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(46),
            textStyle: AppTextStyles.buttonText,
            elevation: 0,
            shape: shape,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryText,
            minimumSize: const Size.fromHeight(46),
            textStyle: AppTextStyles.buttonText,
            side: BorderSide(color: AppColors.primaryText),
            shape: shape,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Route that opens a stock opname screen inside [OpnameTheme].
Route<T> opnameRoute<T>(Widget page) =>
    MaterialPageRoute<T>(builder: (_) => OpnameTheme(child: page));
