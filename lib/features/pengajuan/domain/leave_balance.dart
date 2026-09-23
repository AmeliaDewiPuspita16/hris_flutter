import 'package:flutter/material.dart';

/// Ringkasan saldo satu jenis cuti/izin/lembur untuk pegawai yang login.
///
/// Untuk sementara datanya statis — lihat
/// `PengajuanRepository.fetchBalances`. Nanti kalau endpoint saldo HRIS
/// sudah tersedia, model ini yang diisi dari response-nya; bentuk field di
/// sini sengaja dibuat mendekati kebutuhan tampilan (bukan echo mentah dari
/// response) supaya `RingkasanTab` tidak perlu berubah saat itu terjadi.
class LeaveBalance {
  const LeaveBalance({
    required this.label,
    required this.used,
    required this.unit,
    required this.color,
    required this.background,
    this.total,
  });

  final String label;
  final num used;

  /// Null berarti akumulasi tanpa batas atas (mis. saldo lembur).
  final num? total;
  final String unit;
  final Color color;
  final Color background;

  num get remaining => total != null ? total! - used : used;

  /// Rasio pemakaian 0..1, atau null kalau tidak ada batas atas untuk dibagi.
  double? get usageRatio =>
      total != null ? (used / total!).clamp(0, 1).toDouble() : null;
}
