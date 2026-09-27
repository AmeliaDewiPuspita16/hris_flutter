import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';

/// satu baris riwayat pengajuan cuti/izin/lembur pada tab status.
class LeaveHistoryEntry {
  const LeaveHistoryEntry({
    required this.id,
    required this.type,
    required this.typeColor,
    required this.typeBackground,
    required this.date,
    required this.requestDate,
    required this.status,
    required this.note,
    this.reason,
    this.photoUrl,
  });

  final String id;
  final String type;
  final Color typeColor;
  final Color typeBackground;

  /// Tanggal siap-tampil, mis. "17–19 Jul 2026" (bisa berupa rentang, jam,
  /// dsb — lihat `PengajuanRepository._describeDraftDate`).
  final String date;

  /// Tanggal mulai pengajuan dalam bentuk [DateTime] asli, dipakai tab
  /// Ringkasan untuk menyaring riwayat bulan berjalan. [date] sengaja tidak
  /// diparse balik karena formatnya bebas (rentang, jam, dst).
  final DateTime requestDate;

  final AppStatus status;
  final String note;

  /// Alasan yang diisi user waktu submit — ditampilkan di detail view yang
  /// sama dari tab Ringkasan maupun tab Status.
  final String? reason;

  /// Lampiran foto/dokumen pendukung, kalau ada.
  final String? photoUrl;
}
