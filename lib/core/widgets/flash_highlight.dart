import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Membungkus satu kartu/baris daftar dan membuatnya berkedip hijau satu kali
/// (menyala, bertahan sebentar, lalu memudar pelan) saat [active] — penanda "ini request yang tadi kamu tap di notifikasi".
///
/// Begitu muncul di layar, kartunya juga di-scroll ke area yang terlihat
/// (kalau sudah ada di pohon widget; daftar malas hanya membangun yang dekat
/// layar, jadi daftar panjang sebaiknya menaikkan item ini ke atas dulu).
///
/// Pasang `key: ValueKey(id)` pada pemanggilan, supaya efeknya menempel ke
/// item yang benar dan tidak berpindah ke item lain saat daftar berubah
/// urutan.
///
/// Efeknya hanya digambar sebagai lapisan di atas [child] dan tidak
/// menangkap sentuhan, jadi kartu tetap bisa ditekan seperti biasa.
class FlashHighlight extends StatefulWidget {
  const FlashHighlight({
    super.key,
    required this.active,
    required this.child,
    this.borderRadius = 12,
  });

  /// True = kedipkan. Efek hanya diputar sekali, saat widget ini pertama
  /// muncul dengan nilai true atau berganti dari false ke true.
  final bool active;
  final Widget child;
  final double borderRadius;

  @override
  State<FlashHighlight> createState() => _FlashHighlightState();
}

class _FlashHighlightState extends State<FlashHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _play();
  }

  @override
  void didUpdateWidget(FlashHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _play();
  }

  Future<void> _play() async {
    // Tunggu animasi pindah halaman selesai, kalau tidak kedipnya terjadi
    // sebelum layar terlihat jelas.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.3,
    );
    if (!mounted) return;

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Susunan widget dibuat tetap (child selalu anak pertama Stack) supaya
    // state kartu tidak ikut dibuat ulang saat efek mulai/berhenti.
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // Satu kedipan panjang: menyala cepat (0-20%), bertahan penuh
        // (20-55%), lalu memudar pelan (55-100%).
        final t = _controller.value;
        final pulse = t < 0.2
            ? Curves.easeOut.transform(t / 0.2)
            : t < 0.55
                ? 1.0
                : 1 - Curves.easeInOut.transform((t - 0.55) / 0.45);

        return Stack(
          // passthrough: ukuran dan batas lebar kartu persis seperti tanpa
          // pembungkus ini.
          fit: StackFit.passthrough,
          children: [
            child!,
            if (_controller.isAnimating)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primaryText.withValues(alpha: 0.12 * pulse),
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(
                        color: AppColors.primaryText.withValues(alpha: pulse),
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
