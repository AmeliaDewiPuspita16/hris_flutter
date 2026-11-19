import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../../core/theme/app_colors.dart';
import 'opname_text_styles.dart';

/// Top bar of the stock opname screens: back arrow, centered title and
/// optional [actions]. (The portal's BackHeader only fits a tiny trailing
/// widget, and the camera toggle is a full icon button.)
class OpnameAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OpnameAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            AppColors.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            AppColors.isDark ? Brightness.dark : Brightness.light,
      ),
      leading: IconButton(
        tooltip: 'Back',
        icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
        onPressed: onBack ?? () => Navigator.maybePop(context),
      ),
      title: Text(title, style: OpnameTextStyles.bodyBold),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }
}
