import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tekan back dua kali untuk keluar aplikasi, seperti aplikasi pada umumnya.
///
/// Back pertama memunculkan petunjuk "Press back again to exit"; back kedua
/// dalam [window] menutup aplikasi. Pasang di layar akar (route paling
/// bawah) — layar lain yang dibuka di atasnya tetap kembali seperti biasa,
/// karena widget ini hanya terpicu saat route-nya teratas.
///
/// [onBack] dipanggil lebih dulu; kembalikan `true` bila back sudah
/// ditangani (mis. pindah ke tab Home) sehingga hitungan keluar diulang.
class DoubleBackToExit extends StatefulWidget {
  const DoubleBackToExit({
    super.key,
    required this.child,
    this.onBack,
    this.window = const Duration(seconds: 2),
    this.message = 'Press back again to exit',
  });

  final Widget child;
  final bool Function()? onBack;
  final Duration window;
  final String message;

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastPressedAt;

  void _handleBack() {
    if (widget.onBack?.call() ?? false) {
      _lastPressedAt = null;
      return;
    }

    final now = DateTime.now();
    final last = _lastPressedAt;
    if (last != null && now.difference(last) <= widget.window) {
      SystemNavigator.pop();
      return;
    }

    _lastPressedAt = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.message),
          duration: widget.window,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: widget.child,
    );
  }
}
