import '../../../core/utils/date_formatter.dart';
import '../../pengajuan/domain/leave_type.dart';
import 'leave_approval_status.dart';

/// Satu pengajuan bawahan yang masuk ke HOD untuk diputuskan.
///
/// Ini sisi approver dari pengajuan yang di sisi pegawai disimpan sebagai
/// `LeaveHistoryEntry`. Modelnya sengaja dipisah karena kebutuhannya beda:
/// approver perlu tahu SIAPA pemohonnya (nama, departemen, sisa saldo) dan
/// siapa/kapan/kenapa keputusan diambil, sedangkan riwayat pegawai tidak.
///
/// Mencakup semua jenis di [LeaveType] — Annual Leave, Permission, Off in
/// Lieu, Overtime, dan Medical Check — sesuai baris "approval" pada
/// requirement HRIS (Leave approval, Off in lieu approval, Overtime approval).
///
/// Untuk keperluan layar Approvals, jenis-jenis itu dikelompokkan jadi dua
/// kategori: Overtime ([isOvertime]) dan Leave (semua selain overtime).
class LeaveApprovalRequest {
  const LeaveApprovalRequest({
    required this.id,
    required this.requesterName,
    required this.department,
    required this.position,
    required this.type,
    required this.startDate,
    required this.durationLabel,
    required this.submittedAt,
    this.endDate,
    this.timeLabel,
    this.reason,
    this.attachmentName,
    this.balanceInfo,
    this.status = LeaveApprovalStatus.pending,
    this.decidedBy,
    this.decidedAt,
    this.decisionNote,
  });

  final String id;
  final String requesterName;
  final String department;
  final String position;
  final LeaveType type;

  final DateTime startDate;

  /// Null untuk pengajuan satu hari (izin, lembur, dst).
  final DateTime? endDate;

  /// Jam atau bagian hari, mis. "18:30–21:00" (lembur) atau "Morning" (izin
  /// setengah hari). Null untuk pengajuan hari penuh.
  final String? timeLabel;

  /// Siap tampil, mis. "3 days", "Half day", "2h 30m".
  final String durationLabel;

  final String? reason;
  final String? attachmentName;

  /// Sisa saldo pemohon untuk jenis ini, membantu HOD memutuskan,
  /// mis. "8 of 12 days left".
  final String? balanceInfo;

  final DateTime submittedAt;

  final LeaveApprovalStatus status;

  /// Terisi setelah diputuskan.
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? decisionNote;

  /// One row of `GET /api/portal/apps/hris/leave/approvals` — a leave
  /// request or, with `category: overtime` and type "Overtime", an overtime
  /// request.
  ///
  /// HRIS has no "approved by": for a decided request [decidedBy] and
  /// [decidedAt] are whoever changed it last, often HR staff.
  factory LeaveApprovalRequest.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'approved' => LeaveApprovalStatus.approved,
      'voided' => LeaveApprovalStatus.voided,
      _ => LeaveApprovalStatus.pending,
    };
    final start = DateTime.parse(json['start_date'] as String);
    final endRaw = json['end_date'] as String?;
    final nik = json['nik'] as String?;
    final updatedAt = json['updated_at'] as String?;
    final description = (json['description'] as String?)?.trim();
    final startTime = json['start_time'] as String?;
    final endTime = json['end_time'] as String?;
    final hours = (json['hours'] as num?)?.toDouble();

    return LeaveApprovalRequest(
      id: json['id'] as String,
      requesterName: (json['requester_name'] as String?) ?? '-',
      department: (json['department'] as String?) ?? '-',
      // HRIS leave rows carry no job title; the NIK identifies the person.
      position: nik == null ? '-' : 'NIK $nik',
      // Unknown HRIS leave names fall back to Permission rather than failing.
      type: LeaveTypeX.fromApiName((json['type'] as String?) ?? '') ??
          LeaveType.izin,
      startDate: start,
      endDate: endRaw == null ? null : DateTime.parse(endRaw),
      timeLabel: startTime == null || endTime == null
          ? null
          : '$startTime–$endTime',
      // Overtime is claimed in hours, leave in days.
      durationLabel: hours != null
          ? _hoursLabel(hours)
          : _durationLabel((json['days'] as num?)?.toDouble()),
      reason: (description == null || description.isEmpty) ? null : description,
      submittedAt: DateTime.parse(json['submitted_at'] as String).toLocal(),
      status: status,
      decidedBy: status == LeaveApprovalStatus.pending
          ? null
          : json['updated_by'] as String?,
      decidedAt: status == LeaveApprovalStatus.pending || updatedAt == null
          ? null
          : DateTime.parse(updatedAt).toLocal(),
    );
  }

  /// 3 -> "3h", 3.5 -> "3h 30m".
  static String _hoursLabel(double hours) {
    final minutes = (hours * 60).round();
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  static String _durationLabel(double? days) {
    if (days == null) return '-';
    if (days == 0.5) return 'Half day';
    if (days == 1) return '1 day';
    final text = days == days.roundToDouble()
        ? days.toInt().toString()
        : days.toString();
    return '$text days';
  }

  bool get isPending => status == LeaveApprovalStatus.pending;

  /// Kategori approval: overtime vs semua jenis cuti/izin lainnya.
  ///
  /// SEMENTARA diturunkan dari [type]. Saat approval overtime punya model
  /// dan sumber datanya sendiri (realisasi lembur dari absensi), getter ini
  /// cukup diganti tanpa menyentuh layar.
  bool get isOvertime => type == LeaveType.lembur;

  String get dateLabel {
    final start = DateFormatter.shortDateID(startDate);
    final end = endDate;
    if (end == null) return start;

    final sameDay = end.year == startDate.year &&
        end.month == startDate.month &&
        end.day == startDate.day;
    if (sameDay) return start;

    return '$start – ${DateFormatter.shortDateID(end)}';
  }

  /// Satu baris ringkasan, dipakai juga sebagai isi notifikasi.
  String get summaryLine {
    final time = timeLabel == null ? '' : ' · $timeLabel';
    return '${type.label} · $dateLabel$time · $durationLabel';
  }

  /// Inisial 2 huruf untuk avatar.
  String get initials {
    final parts = requesterName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  // ── Kaitan dengan tab Notifications ────────────────────────────────
  // Notifikasi keputusan Leave dibangun dari data ini (lihat
  // `NotificationDemoData`) dengan id turunan, supaya keputusan di halaman
  // Leave Approvals dan di tab Notifications bisa saling disinkronkan.

  static const _notificationPrefix = 'n-leave-';

  String get notificationId => '$_notificationPrefix$id';

  /// Kebalikan [notificationId]; null kalau [notificationId] bukan
  /// notifikasi Leave.
  static String? idFromNotificationId(String notificationId) {
    if (!notificationId.startsWith(_notificationPrefix)) return null;
    return notificationId.substring(_notificationPrefix.length);
  }

  LeaveApprovalRequest copyWith({
    LeaveApprovalStatus? status,
    String? decidedBy,
    DateTime? decidedAt,
    String? decisionNote,
  }) {
    return LeaveApprovalRequest(
      id: id,
      requesterName: requesterName,
      department: department,
      position: position,
      type: type,
      startDate: startDate,
      endDate: endDate,
      timeLabel: timeLabel,
      durationLabel: durationLabel,
      reason: reason,
      attachmentName: attachmentName,
      balanceInfo: balanceInfo,
      submittedAt: submittedAt,
      status: status ?? this.status,
      decidedBy: decidedBy ?? this.decidedBy,
      decidedAt: decidedAt ?? this.decidedAt,
      decisionNote: decisionNote ?? this.decisionNote,
    );
  }
}
