import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Kerangka halaman daftar kategori Menu Portal (Records, Data, Online
/// Apps): header
/// bergambar di atas, lalu [children] (kartu kategori) berjarak 12px.
/// Header ikut tergulir bersama daftar.
class PortalCategoryPage extends StatelessWidget {
  const PortalCategoryPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.illustrationAsset = folderIllustration,
    this.sectionLabel,
  });

  static const folderIllustration =
      'assets/icons/header-folder-illustration.svg';
  static const monitorIllustration =
      'assets/icons/header-monitor-illustration.svg';
  static const laptopIllustration =
      'assets/icons/header-laptop-illustration.svg';
  static const carIllustration = 'assets/icons/header-car-illustration.svg';

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// SVG hiasan di kanan header.
  final String illustrationAsset;

  /// Label kecil huruf kapital di atas daftar, mis. "ECOSYSTEM". Null =
  /// tanpa label.
  final String? sectionLabel;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Header terang, jadi ikon status bar harus gelap — sama dengan
      // `BackHeader`.
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            AppColors.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            AppColors.isDark ? Brightness.dark : Brightness.light,
      ),
      child: DecoratedBox(
        decoration: AppColors.portalBackdrop,
        child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            PortalHeader(
              title: title,
              subtitle: subtitle,
              illustrationAsset: illustrationAsset,
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 4, 16, 24 + MediaQuery.paddingOf(context).bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sectionLabel case final label?)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 10),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    children[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Kerangka layar modul (Document File, Procurement, dst): [PortalHeader]
/// ikut tergulir ke atas sampai hilang, lalu [body] mengisi layar penuh.
/// Bagian atas [body] (kolom search, chip tab) jadi terlihat "menempel" di
/// bawah status bar, sementara daftar di dalamnya tetap bisa digulir.
///
/// Daftar di dalam [body] tidak boleh memakai `ScrollController` sendiri —
/// harus `PrimaryScrollController` bawaan supaya geraknya terhubung dengan
/// header (aturan `NestedScrollView`). Paginasi cukup lewat
/// `NotificationListener<ScrollNotification>`.
class PortalModulePage extends StatefulWidget {
  const PortalModulePage({
    super.key,
    this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.illustrationAsset,
    required this.body,
    this.floatingActionButton,
  });

  final String? eyebrow;
  final String title;
  final String subtitle;
  final String illustrationAsset;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  State<PortalModulePage> createState() => _PortalModulePageState();
}

class _PortalModulePageState extends State<PortalModulePage> {
  /// Jarak gulir header sampai penutup status bar tampil penuh.
  static const _statusBarFadeDistance = 24.0;

  final _outerController = ScrollController();

  @override
  void dispose() {
    _outerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

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
        child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: widget.floatingActionButton,
        body: Stack(
          children: [
            // Area gulir dimulai di bawah status bar supaya [body] berhenti
            // tepat di bawahnya. Latar header tetap tergambar sampai ke balik
            // status bar lewat `backgroundBleed` + `Clip.none`.
            Padding(
              padding: EdgeInsets.only(top: topInset),
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: NestedScrollView(
                  controller: _outerController,
                  clipBehavior: Clip.none,
                  headerSliverBuilder: (context, _) => [
                    SliverToBoxAdapter(
                      child: PortalHeader(
                        eyebrow: widget.eyebrow,
                        title: widget.title,
                        subtitle: widget.subtitle,
                        illustrationAsset: widget.illustrationAsset,
                        backgroundBleed: topInset,
                        onBack: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                  body: widget.body,
                ),
              ),
            ),
            // Penutup status bar: transparan saat header utuh, lalu
            // menebal begitu header mulai tergulir supaya teks header tidak
            // terlihat lewat di balik jam/baterai.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topInset,
              child: IgnorePointer(
                child: ListenableBuilder(
                  listenable: _outerController,
                  builder: (context, _) {
                    final offset = _outerController.hasClients
                        ? _outerController.offset
                        : 0.0;
                    final opacity =
                        (offset / _statusBarFadeDistance).clamp(0.0, 1.0);
                    return ColoredBox(
                      color: AppColors.bg.withValues(alpha: opacity),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Pembungkus tiap tab di dalam `IndexedStack` pada [PortalModulePage].
///
/// `NestedScrollView` menggerakkan SEMUA daftar yang memakai
/// PrimaryScrollController-nya, termasuk tab yang sedang tersembunyi. Jadi
/// hanya tab [active] yang diberi controller itu; tab lain dilepas.
///
/// Semua tab — aktif atau tidak — harus selalu dibungkus widget ini, supaya
/// bentuk pohon widgetnya tetap sama dan state tab tidak dibuat ulang saat
/// pindah tab.
class PortalTabScrollScope extends StatelessWidget {
  const PortalTabScrollScope({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = PrimaryScrollController.maybeOf(context);
    if (active && controller != null) {
      return PrimaryScrollController(controller: controller, child: child);
    }
    return PrimaryScrollController.none(child: child);
  }
}

/// Latar `header-background.svg` sampai ke balik status bar, tombol kembali
/// bulat, label kecil opsional ([eyebrow]), judul besar + keterangan, dan
/// ilustrasi di kanan. Dipakai [PortalCategoryPage] dan juga layar modul
/// seperti IT Request.
///
/// Tidak mengatur gaya status bar sendiri — layar pemakainya yang membungkus
/// dengan `AnnotatedRegion` (lihat [PortalCategoryPage]).
class PortalHeader extends StatelessWidget {
  const PortalHeader({
    super.key,
    this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.illustrationAsset,
    required this.onBack,
    this.backgroundBleed = 0,
  });

  /// Label kecil huruf kapital di atas judul, mis. "IT REQUEST".
  final String? eyebrow;
  final String title;
  final String subtitle;
  final String illustrationAsset;
  final VoidCallback onBack;

  /// Seberapa jauh latar digambar melewati sisi atas header — dipakai
  /// [PortalModulePage], yang meletakkan header di bawah status bar tapi
  /// latarnya tetap harus sampai ke balik status bar.
  final double backgroundBleed;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Latar bergambar hanya untuk mode terang; mode gelap memakai
        // [AppColors.portalBackdrop] milik halaman.
        if (!AppColors.isDark) ...[
        Positioned(
          top: -backgroundBleed,
          left: 0,
          right: 0,
          bottom: 0,
          child: SvgPicture.asset('assets/icons/header-background.svg',
              fit: BoxFit.cover),
        ),
        // Memudarkan ujung bawah latar ke warna halaman supaya sambungannya
        // ke daftar tidak terlihat sebagai garis.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 40,
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
        Positioned(
          right: 4,
          bottom: 12,
          child: SvgPicture.asset(
            illustrationAsset,
            width: 150,
            // Mode gelap: warna SVG disesuaikan (putih -> permukaan gelap).
            colorMapper:
                AppColors.isDark ? const _DarkIllustrationMapper() : null,
            // Latar & judul tetap terbaca untuk pembaca layar; ilustrasi
            // hanya hiasan.
            excludeFromSemantics: true,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackButton(onTap: onBack),
              const SizedBox(height: 18),
              if (eyebrow case final eyebrow?) ...[
                Text(
                  eyebrow,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              // Sisakan ruang untuk ilustrasi di kanan.
              FractionallySizedBox(
                widthFactor: 0.6,
                child: Text(
                  subtitle,
                  style: AppTextStyles.bodyMuted
                      .copyWith(fontSize: 12.5, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      elevation: 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: 38,
          child:
              Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.text),
        ),
      ),
    );
  }
}

/// Menyesuaikan warna ilustrasi SVG untuk mode gelap tanpa mengubah gambarnya:
/// putih/krem/abu muda jadi permukaan gelap kehijauan, warna pastel diperdalam,
/// dan warna yang terlalu gelap diterangkan sedikit supaya tetap terlihat.
class _DarkIllustrationMapper extends ColorMapper {
  const _DarkIllustrationMapper();

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    final hsl = HSLColor.fromColor(color);
    final l = hsl.lightness;
    final Color out;
    if (hsl.saturation < 0.3 && l > 0.78) {
      out = Color.lerp(AppColors.card, AppColors.primaryLight, 0.6)!;
    } else if (l > 0.72) {
      out = hsl.withLightness(l - 0.28).toColor();
    } else if (l < 0.28) {
      out = hsl.withLightness(0.4).toColor();
    } else {
      return color;
    }
    return out.withValues(alpha: color.a);
  }
}
