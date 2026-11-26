import 'package:material_ui/material_ui.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/json_value.dart';
import '../../../core/widgets/status_badge.dart';
import 'duration_type.dart';
import 'leave_request_draft.dart';
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
    this.isDraft = false,
    this.draft,
    this.canEdit = false,
    this.isUrgent = false,
    this.source,
    this.dateLabel,
    this.timeRange,
    this.days,
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

    final rawType = textOrNull(json['type']) ?? 'Leave';
    final leaveType = LeaveTypeX.fromApiName(rawType);

    final code = textOrNull(json['status_code']);
    final label = textOrNull(json['status_label']);
    final mapped = _mapStatus(code, label);
    final isDraft = code?.toUpperCase() == 'DR';
    final reason = textOrNull(json['description']);
    final isHour = _boolOf(json['is_hour']);
    final startTime = isHour ? _timeOf(json['start_time']) : null;
    final endTime = isHour ? _timeOf(json['end_time']) : null;
    final isUrgent = _boolOf(json['is_urgent']);

    return LeaveHistoryEntry(
      // Server mengirim `id` asli; fallback hanya untuk respons lama tanpa id.
      id: textOrNull(json['id']) ?? 'LV-$index-${json['start_date']}',
      // Jenis yang dikenal memakai label aplikasi supaya filter jenis di tab
      // Status cocok; yang belum dikenal tampil apa adanya.
      type: leaveType?.label ?? rawType,
      typeColor: leaveType?.color ?? const Color(0xFF607D8B),
      typeBackground: leaveType?.background ?? const Color(0xFFECEFF1),
      date: _describeRange(start, end, startTime: startTime, endTime: endTime),
      requestDate: start,
      status: mapped.status,
      statusLabel: mapped.label,
      note: mapped.note,
      reason: reason,
      isUrgent: isUrgent,
      source: textOrNull(json['source']),
      canEdit: _boolOf(json['can_edit']),
      dateLabel: _describeRange(start, end),
      timeRange: startTime != null && endTime != null
          ? '${_hhmm(startTime)}–${_hhmm(endTime)}'
          : null,
      days: _numOrNull(json['days']),
      isDraft: isDraft,
      draft: isDraft && leaveType != null
          ? LeaveRequestDraft(
              leaveType: leaveType,
              durationType: isHour ? DurationType.half : DurationType.full,
              startDate: start,
              endDate: end,
              date: start,
              startTime: startTime,
              endTime: endTime,
              reason: reason,
              isUrgent: isUrgent,
            )
          : null,
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
      case 'VO':
        // Kode standar dokumen ERP "Voided" (dibatalkan). Dibuat netral supaya
        // tidak keliru tampil sebagai Approved/Rejected.
        return (
          status: AppStatus.neutral,
          label: 'Void',
          note: 'Voided',
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

  static String _describeRange(
    DateTime start,
    DateTime end, {
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    final from = DateFormatter.shortDateID(start);
    final isSameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final label = isSameDay ? from : '$from – ${DateFormatter.shortDateID(end)}';

    // Cuti per jam (Half Day): tampilkan jamnya, mis. "29 Okt 2025 · 08:00–12:00".
    if (startTime == null || endTime == null) return label;
    return '$label · ${_hhmm(startTime)}–${_hhmm(endTime)}';
  }

  static String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static double? _numOrNull(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static bool _boolOf(Object? v) => v == true || v == 1 || v == '1';

  /// "08:00" / "08:00:00" -> [TimeOfDay]; null bila kosong atau tidak valid.
  static TimeOfDay? _timeOf(Object? v) {
    if (v is! String) return null;
    final parts = v.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  final String id;
  final String type;
  final Color typeColor;
  final Color typeBackground;

  /// Tanggal siap-tampil, mis. "17–19 Jul 2026" atau, untuk cuti per jam,
  /// "17 Des 2026 · 07:00–12:00".
  final String date;

  /// Tanggal saja tanpa jam (untuk layar detail); null = pakai [date].
  final String? dateLabel;

  /// Rentang jam cuti per jam, mis. "07:00–12:00"; null untuk Full Day.
  final String? timeRange;

  /// Lama pengajuan dalam hari (`days`, mis. 0.5 untuk setengah hari).
  final double? days;

  String get dateOnly => dateLabel ?? date;

  /// "0.5 day", "1 day", "5 days"; null bila server tidak mengirim `days`.
  String? get durationLabel {
    final d = days;
    if (d == null) return null;
    final text = d == d.roundToDouble() ? d.toInt().toString() : d.toString();
    return '$text ${d > 1 ? 'days' : 'day'}';
  }

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

  /// true = draft: belum dirilis, masih bisa diedit lalu di-submit dari tab
  /// Status.
  final bool isDraft;

  /// Isian form asli untuk draft, dipakai untuk mengisi ulang form saat Edit.
  /// Null untuk pengajuan yang sudah dirilis.
  final LeaveRequestDraft? draft;

  /// `can_edit` dari server: boleh diedit/dirilis oleh user.
  final bool canEdit;

  /// Pengajuan ditandai mendesak (`is_urgent`).
  final bool isUrgent;

  /// Asal data dari server: `leave_request` (cuti) atau `leave_permission`
  /// (izin, dinas luar, MC, dst.). Null untuk entri lokal / respons lama.
  final String? source;

  /// Draft yang boleh diedit/dirilis: tombol Edit & Submit tampil.
  bool get canEditDraft => isDraft && canEdit;
}
