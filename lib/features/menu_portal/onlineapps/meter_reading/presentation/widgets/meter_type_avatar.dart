import 'package:flutter/material.dart';

import '../../domain/meter_type.dart';

/// Ikon bulat jenis meter — bolt kuning untuk listrik, tetes biru untuk
/// air. Berwarna penuh (gradasi + bayangan halus) supaya jenis meter
/// langsung terbaca sekilas, tanpa badge teks.
class MeterTypeAvatar extends StatelessWidget {
  const MeterTypeAvatar({
    super.key,
    required this.type,
    this.size = 40,
    this.soft = false,
  });

  /// Latar pucat + ikon berwarna, tanpa gradasi dan bayangan — lebih tenang
  /// untuk daftar yang berisi banyak avatar.
  final bool soft;

  final MeterType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = type.color;
    final deep = Color.lerp(base, Colors.black, 0.18)!;

    if (soft) {
      return Semantics(
        label: type.label,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: base.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(size * 0.32),
          ),
          child: Icon(type.icon, size: size * 0.52, color: base),
        ),
      );
    }

    return Semantics(
      label: type.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, deep],
          ),
          borderRadius: BorderRadius.circular(size * 0.32),
          boxShadow: [
            BoxShadow(
              color: base.withValues(alpha: 0.32),
              blurRadius: size * 0.25,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: Icon(type.icon, size: size * 0.54, color: Colors.white),
      ),
    );
  }
}
