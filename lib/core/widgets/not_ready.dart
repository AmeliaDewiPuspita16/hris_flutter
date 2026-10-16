import 'package:flutter/material.dart';

/// Menandai item menu yang fiturnya belum siap: tampil redup dan tidak bisa
/// disentuh, tanpa label apa pun.
///
/// Aturannya sama dengan item `isReady: false` di menu HRIS (opacity 0,45 dan
/// tap dimatikan), cuma tanpa teks "Soon". Dipakai tile Menu Portal (Record,
/// Data, Online Apps); kalau [isReady] true, [child] ditampilkan apa adanya.
class NotReady extends StatelessWidget {
  const NotReady({super.key, required this.isReady, required this.child});

  /// Opacity item yang belum siap — sama dengan menu HRIS.
  static const dimOpacity = 0.45;

  final bool isReady;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isReady) return child;
    return Opacity(
      opacity: dimOpacity,
      child: IgnorePointer(child: child),
    );
  }
}
