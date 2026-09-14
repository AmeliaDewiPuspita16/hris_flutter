import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // Scaffold menyediakan ruang setinggi preferredSize + padding atas untuk
    // appBar, tapi tidak menggeser isinya. Tanpa inset ini, isi header naik
    // ke balik notch / Dynamic Island. AppBar bawaan Flutter melakukan hal
    // yang sama di dalamnya.
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Header ini putih, jadi ikon status bar harus gelap. Layar yang
      // memakainya biasanya dibuka dari Beranda yang menyetel ikon terang —
      // tanpa ini, jam dan baterai jadi putih di atas putih.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        height: preferredSize.height + topInset,
        padding: EdgeInsets.fromLTRB(20, topInset, 20, 0),
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
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(width: 20, child: trailing),
          ],
        ),
      ),
    );
  }
}