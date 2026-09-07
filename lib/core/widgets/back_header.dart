import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Dipakai sebagai AppBar kustom di layar-layar sekunder (Payslip, Jadwal, dll).
class BackHeader extends StatelessWidget implements PreferredSizeWidget {
  const BackHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: InkWell(
              onTap: onBack,
              child: const Icon(Icons.arrow_back, size: 20, color: AppColors.primary),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(width: 20, child: trailing),
        ],
      ),
    );
  }
}