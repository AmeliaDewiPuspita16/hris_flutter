import 'package:flutter/material.dart';

/// Bungkus elemen yang bisa ditekan dengan animasi fade (opacity) sebagai
/// umpan balik visual — memudar saat dihover (desktop/web) dan memudar
/// lagi saat ditekan, lalu kembali normal begitu dilepas.
///
/// Dipakai untuk tap-target custom yang punya [onTap] sendiri (kartu,
/// banner, tile menu). Untuk elemen yang tap-nya sudah ditangani widget
/// lain (mis. item di dalam [BottomNavigationBar] atau tombol Material),
/// pakai [HoverFade].
class TapFade extends StatefulWidget {
  const TapFade({
    super.key,
    required this.child,
    this.onTap,
    this.hoverOpacity = 0.75,
    this.pressedOpacity = 0.55,
    this.duration = const Duration(milliseconds: 120),
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Opacity saat kursor mouse berada di atas elemen (desktop/web).
  final double hoverOpacity;

  /// Opacity saat elemen ditekan (semua platform).
  final double pressedOpacity;

  final Duration duration;

  /// Radius area hover — pakai kalau elemen punya sudut membulat, supaya
  /// kursor "click" pas dengan bentuknya.
  final BorderRadius? borderRadius;

  @override
  State<TapFade> createState() => _TapFadeState();
}

class _TapFadeState extends State<TapFade> {
  bool _hovering = false;
  bool _pressing = false;

  double get _opacity {
    if (_pressing) return widget.pressedOpacity;
    if (_hovering) return widget.hoverOpacity;
    return 1;
  }

  void _setHovering(bool value) {
    if (_hovering != value) setState(() => _hovering = value);
  }

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _setHovering(true),
      onExit: (_) => _setHovering(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: enabled ? (_) => _setPressing(true) : null,
        onTapUp: enabled ? (_) => _setPressing(false) : null,
        onTapCancel: enabled ? () => _setPressing(false) : null,
        child: AnimatedScale(
          scale: _pressing ? 0.96 : (_hovering ? 1.03 : 1.0),
          duration: widget.duration,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Versi ringan [TapFade] untuk elemen yang tap-nya sudah ditangani widget
/// pembungkusnya (mis. [BottomNavigationBar] atau [ElevatedButton]) —
/// cuma menambah efek fade saat dihover, tanpa ikut menangkap gesture
/// supaya tidak bentrok dengan penanganan tap milik widget induk.
class HoverFade extends StatefulWidget {
  const HoverFade({
    super.key,
    required this.child,
    this.hoverOpacity = 0.7,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final double hoverOpacity;
  final Duration duration;

  @override
  State<HoverFade> createState() => _HoverFadeState();
}

class _HoverFadeState extends State<HoverFade> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.15 : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
