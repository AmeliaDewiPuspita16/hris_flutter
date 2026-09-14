import 'package:flutter/material.dart';

/// Satu kartu saldo di bagian "Saldo Saya".
class QuotaBalance {
  const QuotaBalance({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.background,
    this.total,
  });

  final String label;
  final num value;

  /// Kuota maksimum. Null kalau saldo tidak punya batas, mis. saldo lembur.
  final num? total;

  final String unit;
  final Color color;
  final Color background;

  /// Teks di bawah angka, mis. "dari 12 Hari" atau cukup "Jam".
  String get caption => total != null ? 'dari $total $unit' : unit;
}
