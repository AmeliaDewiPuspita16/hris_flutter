import 'it_request_status.dart';
import 'request_category.dart';
import 'support_type.dart';

/// Satu permintaan IT/Media.
///
/// Sebelumnya kelas ini cuma dipakai untuk riwayat milik staff yang login
/// (makanya belum ada [requesterName]/[department]). Sekarang tab "Form IT
/// & Media" menampilkan SEMUA permintaan — sama seperti tab "All Request"
/// di EST Request — jadi field itu ditambahkan di sini.
class ItRequestItem {
  const ItRequestItem({
    required this.id,
    required this.requesterName,
    required this.department,
    required this.category,
    required this.supportType,
    required this.description,
    required this.date,
    required this.status,
    this.awaitingFeedback = false,
  });

  final String id;
  final String requesterName;
  final String department;
  final RequestCategory category;
  final SupportType supportType;
  final String description;
  final String date;
  final ItRequestStatus status;

  /// True kalau permintaan ini sudah selesai (status
  /// [ItRequestStatus.completed]) tapi belum dikasih rating/feedback.
  ///
  /// SEMENTARA: sama seperti gate serupa di `EstRequestScreen`, flag ini
  /// dicek lintas SEMUA permintaan (bukan cuma yang diajukan staff yang
  /// sedang login) karena belum ada pemetaan identitas user ke data demo
  /// ini — tinggal disaring per requester nanti kalau sudah terhubung ke
  /// akun asli.
  final bool awaitingFeedback;

  ItRequestItem copyWith({
    ItRequestStatus? status,
    bool? awaitingFeedback,
  }) =>
      ItRequestItem(
        id: id,
        requesterName: requesterName,
        department: department,
        category: category,
        supportType: supportType,
        description: description,
        date: date,
        status: status ?? this.status,
        awaitingFeedback: awaitingFeedback ?? this.awaitingFeedback,
      );
}
