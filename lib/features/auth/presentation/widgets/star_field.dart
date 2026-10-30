import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Langit berbintang untuk latar halaman login mode gelap.
///
/// Dilukis dengan [CustomPainter] (tanpa aset gambar), jadi tajam di semua
/// ukuran layar. Posisi bintang diacak dengan seed tetap — tiap kali halaman
/// dibuka susunannya sama, tidak "meloncat" saat rebuild.
///
/// Bintang berkedip pelan. Animasi dimatikan otomatis kalau pengguna
/// menyalakan "reduce motion" / "remove animations" di pengaturan sistem.
///
/// Taruh di belakang konten, misalnya:
/// `Positioned.fill(child: IgnorePointer(child: StarField()))`.
class StarField extends StatefulWidget {
  const StarField({
    super.key,
    this.count = 70,
    this.seed = 7,
    this.color = const Color(0xFFDDEFE4),
  });

  /// Jumlah bintang.
  final int count;

  /// Seed pengacak. Ganti kalau ingin susunan bintang yang berbeda.
  final int seed;

  /// Warna bintang (putih kehijauan supaya senada dengan palet portal).
  final Color color;

  @override
  State<StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<StarField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  late final List<_Star> _stars = _generate(widget.count, widget.seed);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static List<_Star> _generate(int count, int seed) {
    final rnd = math.Random(seed);
    return List.generate(count, (_) {
      // Sebagian besar kecil; sedikit yang besar dan berpendar.
      final size = rnd.nextDouble();
      final radius = size > 0.92
          ? 1.7 + rnd.nextDouble() * 0.5
          : 0.6 + rnd.nextDouble() * 0.7;
      return _Star(
        dx: rnd.nextDouble(),
        dy: 0.10 + rnd.nextDouble() * 0.78, // hindari tepi atas & dasar
        radius: radius,
        alpha: 0.30 + rnd.nextDouble() * 0.55,
        phase: rnd.nextDouble() * math.pi * 2,
        // Kelipatan bulat supaya putaran animasi menyambung mulus.
        speed: 1 + rnd.nextInt(3),
        glow: size > 0.92,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _StarPainter(
          stars: _stars,
          color: widget.color,
          animation: _controller,
        ),
      ),
    );
  }
}

class _Star {
  const _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.alpha,
    required this.phase,
    required this.speed,
    required this.glow,
  });

  final double dx;
  final double dy;
  final double radius;
  final double alpha;
  final double phase;
  final int speed;
  final bool glow;
}

class _StarPainter extends CustomPainter {
  _StarPainter({
    required this.stars,
    required this.color,
    required Animation<double> animation,
  })  : _animation = animation,
        super(repaint: animation);

  final List<_Star> stars;
  final Color color;
  final Animation<double> _animation;

  final Paint _dot = Paint();
  final Paint _halo = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  @override
  void paint(Canvas canvas, Size size) {
    final t = _animation.value;

    for (final s in stars) {
      // Di bagian atas (di belakang form) bintang dibuat lebih redup supaya
      // tidak mengganggu bacaan; makin ke bawah makin terang.
      final yFade = 0.40 + 0.60 * _smoothstep(0.35, 0.70, s.dy);

      // Kedipan: 0.55 .. 1.0
      final twinkle =
          0.775 + 0.225 * math.sin(math.pi * 2 * (t * s.speed) + s.phase);

      final a = (s.alpha * yFade * twinkle).clamp(0.0, 1.0);
      final center = Offset(s.dx * size.width, s.dy * size.height);

      if (s.glow) {
        _halo.color = color.withValues(alpha: a * 0.35);
        canvas.drawCircle(center, s.radius * 3.2, _halo);
      }
      _dot.color = color.withValues(alpha: a);
      canvas.drawCircle(center, s.radius, _dot);
    }
  }

  static double _smoothstep(double e0, double e1, double x) {
    final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  // Posisi/ukuran bintang tidak pernah berubah; yang berubah hanya kedipan,
  // dan itu sudah dipicu lewat `repaint: animation`.
  @override
  bool shouldRepaint(covariant _StarPainter old) =>
      old.stars != stars || old.color != color;
}
