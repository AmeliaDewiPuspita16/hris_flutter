import 'package:material_ui/material_ui.dart';

/// Membuat [child] muncul dari bawah sambil memudar masuk.
///
/// Dipakai di LoginScreen supaya form tidak muncul tiba-tiba setelah splash.
/// [delay] mengatur urutan: header dulu, lalu form, lalu footer.
class LoginEntrance extends StatefulWidget {
  const LoginEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 650),
    this.offsetY = 48,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Jarak awal (piksel) di bawah posisi akhir.
  final double offsetY;

  @override
  State<LoginEntrance> createState() => _LoginEntranceState();
}

class _LoginEntranceState extends State<LoginEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curve.value) * widget.offsetY),
          child: child,
        ),
      ),
    );
  }
}
