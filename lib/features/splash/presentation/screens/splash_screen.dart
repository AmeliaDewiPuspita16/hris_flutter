import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Layar pembuka, animasi bertahap (total ±2,4 detik):
///
///  1. ornamen latar memudar masuk
///  2. cahaya (glow) di belakang logo menyala
///  3. logo muncul: zoom + fade, lalu "disapu" terungkap dari kiri ke kanan
///  4. tagline naik dari bawah
///  5. indikator loading memudar masuk
///
/// Murni tampilan — layar ini tidak menavigasi ke mana pun. AuthGate yang
/// menggantinya begitu status sesi diketahui dan [displayDuration] terlewati.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Lama splash ditahan sebelum AuthGate boleh berpindah halaman.
  /// Dinaikkan dari 2 detik supaya seluruh animasi sempat selesai.
  static const displayDuration = Duration(milliseconds: 2600);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _ornament;
  late final Animation<double> _glow;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoReveal;
  late final Animation<double> _tagline;
  late final Animation<double> _loading;

  /// Animasi yang berjalan di rentang [begin, end] dari total durasi.
  Animation<double> _stage(double begin, double end, Curve curve) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: curve),
    );
  }

  @override
  void initState() {
    super.initState();

    // Latar hijau gelap — ikon status bar dibuat terang agar tetap terbaca.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _ornament = _stage(0.00, 0.30, Curves.easeOut);
    _glow = _stage(0.05, 0.45, Curves.easeOut);
    _logoFade = _stage(0.08, 0.38, Curves.easeOut);
    _logoScale = _stage(0.08, 0.45, Curves.easeOutBack);
    _logoReveal = _stage(0.20, 0.62, Curves.easeInOutCubic);
    _tagline = _stage(0.55, 0.80, Curves.easeOutCubic);
    _loading = _stage(0.70, 0.95, Curves.easeOut);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: FadeTransition(
                opacity: _ornament,
                child: Image.asset(
                  'assets/images/ornament_top_left.png',
                  width: 160,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: FadeTransition(
                opacity: _ornament,
                child: Image.asset(
                  'assets/images/ornament_bottom_left.png',
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned.fill(
              // Stack memberi constraint longgar ke child yang tidak
              // Positioned dan menempelkannya di kiri-atas — dibungkus
              // Positioned.fill supaya Column di dalamnya kembali melebar
              // penuh dan bisa nge-center kontennya secara horizontal.
              child: SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _AnimatedBrand(
                      glow: _glow,
                      fade: _logoFade,
                      scale: _logoScale,
                      reveal: _logoReveal,
                      tagline: _tagline,
                    ),
                    const Spacer(flex: 2),
                    FadeTransition(
                      opacity: _loading,
                      child: const _LoadingIndicator(),
                    ),
                    const SizedBox(height: 48),
                    FadeTransition(
                      opacity: _loading,
                      child: Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo + cahaya di belakangnya + tagline.
class _AnimatedBrand extends StatelessWidget {
  const _AnimatedBrand({
    required this.glow,
    required this.fade,
    required this.scale,
    required this.reveal,
    required this.tagline,
  });

  final Animation<double> glow;
  final Animation<double> fade;
  final Animation<double> scale;
  final Animation<double> reveal;
  final Animation<double> tagline;

  /// Lebar tepi lembut penyapu, sebagai pecahan lebar logo.
  static const double _softEdge = 0.35;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Cahaya lembut di belakang logo.
            AnimatedBuilder(
              animation: glow,
              builder: (context, _) => Opacity(
                opacity: glow.value,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.20),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                // Logo "disapu" terungkap dari kiri ke kanan. dstIn: bagian
                // logo hanya terlihat di mana gradien masknya masih putih.
                child: AnimatedBuilder(
                  animation: reveal,
                  builder: (context, child) => ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) {
                      final t = reveal.value * (1 + _softEdge);
                      final solidUntil = (t - _softEdge).clamp(0.0, 1.0);
                      final fadeUntil = t.clamp(0.0, 1.0);
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: const [
                          Colors.white,
                          Colors.white,
                          Color(0x00FFFFFF),
                          Color(0x00FFFFFF),
                        ],
                        stops: [0, solidUntil, fadeUntil, 1],
                      ).createShader(bounds);
                    },
                    child: child,
                  ),
                  child: Image.asset(
                    'assets/images/logo_white.png',
                    width: 200,
                    fit: BoxFit.contain,
                    // Logo sumbernya kecil (142 px); tanpa ini tepinya pecah
                    // saat diperbesar ke 200 dp.
                    filterQuality: FilterQuality.high,
                    semanticLabel: 'Logo Bintan Industrial Estate',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: tagline,
          builder: (context, child) => Opacity(
            opacity: tagline.value,
            child: Transform.translate(
              offset: Offset(0, (1 - tagline.value) * 16),
              child: child,
            ),
          ),
          child: Text(
            'At The Forefront, From The Seafront',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              letterSpacing: 0.4,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}

/// Spinner dan teks "Memuat..." di bagian bawah.
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading...',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
