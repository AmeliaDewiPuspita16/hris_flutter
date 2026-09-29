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

  bool get isPending => status == LeaveApprovalStatus.pending;

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
