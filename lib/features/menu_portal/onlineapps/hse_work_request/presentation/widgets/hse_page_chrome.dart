import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_formatter.dart';

/// Kerangka visual layar HSE Work Permit: latar mint bergambar
/// (`header-background.svg`, sama dengan header portal) yang memudar ke
/// warna halaman, ikon status bar gelap, dan Scaffold transparan di atasnya.
class HsePageBackdrop extends StatelessWidget {
  const HsePageBackdrop({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  static const _backgroundHeight = 300.0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            AppColors.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            AppColors.isDark ? Brightness.dark : Brightness.light,
      ),
      child: DecoratedBox(
        decoration: AppColors.portalBackdrop,
        child: Stack(
          children: [
            // Latar bergambar hanya untuk mode terang; mode gelap cukup
            // memakai gradien dari portalBackdrop.
            if (!AppColors.isDark) ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _backgroundHeight,
                child: SvgPicture.asset(
                  'assets/icons/header-background.svg',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
              Positioned(
                top: _backgroundHeight - 80,
                left: 0,
                right: 0,
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.bg.withValues(alpha: 0), AppColors.bg],
                    ),
                  ),
                ),
              ),
            ],
            Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: floatingActionButton,
              bottomNavigationBar: bottomNavigationBar,
              body: body,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol bulat putih berbayang tipis (kembali, filter, menu lainnya).
/// [showDot] memberi titik penanda, mis. filter sedang aktif.
class HseCircleButton extends StatelessWidget {
  const HseCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: AppColors.card,
            shape: const CircleBorder(),
            elevation: 1,
            shadowColor: Colors.black26,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox.square(
                dimension: 44,
                child: Icon(icon, size: 22, color: AppColors.primaryText),
              ),
            ),
          ),
          if (showDot)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.solid(AppColors.orange),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kartu putih bersudut besar dengan judul di dalamnya — dipakai bagian-
/// bagian layar detail dan form (Detail Pekerjaan, General Checklist, dst).
///
/// [icon] opsional menambah kotak ikon hijau di kiri judul; [trailing]
/// opsional di ujung kanan judul (mis. penghitung "3/8").
class HseSectionCard extends StatelessWidget {
  const HseSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    this.required = false,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;

  /// Tanda bintang merah di belakang judul.
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.presentBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primaryText),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: title,
                    children: [
                      if (required)
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.rejected),
                        ),
                    ],
                  ),
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: icon != null ? 14 : 10),
          child,
        ],
      ),
    );
  }
}

/// "26 Oct 2026 – 30 Oct 2026", atau satu tanggal bila sama.
String hseDateRange(DateTime start, DateTime end) {
  final a = DateFormatter.shortDateID(start);
  final b = DateFormatter.shortDateID(end);
  return a == b ? a : '$a – $b';
}

/// "EST • WWTP" — departemen dan section (bila ada).
String hseDepartmentLine(String department, String? section) => [
      department,
      if (section != null) section,
    ].where((s) => s.trim().isNotEmpty).join(' • ');
