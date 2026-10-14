import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/json_value.dart';
import '../../../core/widgets/status_badge.dart';
import 'leave_type.dart';

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
    this.statusLabel,
    this.reason,
    this.photoUrl,
  });

  /// Memetakan satu item `data` dari `GET .../hris/leave/status`.
  ///
  /// Contoh item:
  /// ```json
  /// { "type": "Cuti Tahunan", "start_date": "2026-08-26",
  ///   "end_date": "2026-08-28", "description": "Pulang kampung",
  ///   "status_code": "CO", "status_label": "Disetujui" }
  /// ```
  ///
  /// Respons tidak punya `id`, jadi [id] dibuat dari [index] + tanggal mulai.
  /// Mengembalikan null bila `start_date` kosong/tidak valid — baris tanpa
  /// tanggal tidak bisa ditampilkan ataupun diurutkan.
  static LeaveHistoryEntry? fromApi(
    Map<String, dynamic> json, {
    required int index,
  }) {
    final start = dateOrNull(json['start_date']);
    if (start == null) return null;
    final end = dateOrNull(json['end_date']) ?? start;

    final rawType = textOrNull(json['type']) ?? 'Cuti';
    final leaveType = LeaveTypeX.fromApiName(rawType);

    final code = textOrNull(json['status_code']);
    final label = textOrNull(json['status_label']);
    final mapped = _mapStatus(code, label);

    return LeaveHistoryEntry(
      id: 'LV-$index-${json['start_date']}',
      // Jenis yang dikenal memakai label aplikasi supaya filter jenis di tab
      // Status cocok; yang belum dikenal tampil apa adanya.
      type: leaveType?.label ?? rawType,
      typeColor: leaveType?.color ?? const Color(0xFF607D8B),
      typeBackground: leaveType?.background ?? const Color(0xFFECEFF1),
      date: _describeRange(start, end),
      requestDate: start,
      status: mapped.status,
      statusLabel: mapped.label,
      note: mapped.note,
      reason: textOrNull(json['description']),
    );
  }

  /// Kode status HRIS → [AppStatus] + teks tampilan (bahasa Inggris, sama
  /// seperti sisa layar Pengajuan).
  ///
  /// Teks SENGAJA tidak diambil dari `status_label` server, karena server
  /// mengirimnya berbahasa Indonesia ("Disetujui").
  ///
  /// Kode yang artinya sudah pasti (dari dokumen/jawaban vendor):
  /// - `CO` Complete → Approved
  /// - `OEZ_RELEASE` Release: pengajuan baru disubmit, menunggu persetujuan
  ///   → Pending
  /// - `DR` Draft: belum disubmit, jadi bukan "pending" → netral, "Draft"
  ///
  /// Kode penolakan belum diketahui. Kode lain sengaja dibuat netral dengan
  /// teks mentah dari server, supaya tidak keliru tampil sebagai
  /// Approved/Rejected. Tambahkan case baru di sini setelah ada jawaban
  /// vendor.
  static ({AppStatus status, String label, String note}) _mapStatus(
    String? code,
    String? label,
  ) {
    switch (code?.toUpperCase()) {
      case 'CO':
        return (
          status: AppStatus.present,
          label: 'Approved',
          note: 'Approved',
        );
      case 'OEZ_RELEASE':
        return (
          status: AppStatus.pending,
          label: 'Pending',
          note: 'Waiting for approval',
        );
      case 'DR':
        return (
          status: AppStatus.neutral,
          label: 'Draft',
          note: 'Draft, not submitted yet',
        );
    }

    final raw = label ?? code ?? '-';
    return (status: AppStatus.neutral, label: raw, note: raw);
  }

  static String _describeRange(DateTime start, DateTime end) {
    final from = DateFormatter.shortDateID(start);
    final isSameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (isSameDay) return from;

    return '$from – ${DateFormatter.shortDateID(end)}';
  }

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

  /// Teks badge pengganti label bawaan [status] (yang berbahasa Indonesia:
  /// "Disetujui"/"Menunggu"). Dari HRIS selalu terisi berbahasa Inggris,
  /// mis. "Approved", "Pending", "Draft"; null berarti pakai label bawaan.
  final String? statusLabel;

  final String note;

  /// Alasan yang diisi user waktu submit — ditampilkan di detail view yang
  /// sama dari tab Ringkasan maupun tab Status.
  final String? reason;

  /// Lampiran foto/dokumen pendukung, kalau ada.
  final String? photoUrl;
}
