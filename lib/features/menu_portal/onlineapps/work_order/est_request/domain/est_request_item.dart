import 'est_maintenance_plan.dart';
import 'est_request_status.dart';
import 'est_request_type.dart';
import 'est_work_detail.dart';

import 'est_maintenance_plan.dart';
import 'est_request_status.dart';
import 'est_request_type.dart';
import 'est_work_detail.dart';

/// Satu baris di tabel "EST Work Order" — daftar SEMUA request
class EstRequestItem {
  const EstRequestItem({
    required this.id,
    required this.requesterName,
    required this.department,
    required this.type,
    required this.location,
    required this.description,
    required this.date,
    required this.status,
    this.imageFileName,
    this.plan,
    this.workDetail,
    this.awaitingFeedback = false,
  });

  final String id;
  final String requesterName;
  final String department;
  final EstRequestType type;
  final String location;
  final String description;
  final String date;
  final EstRequestStatus status;

  /// Lampiran foto opsional saat mengajukan (field "Image" di form Add
  /// Request).
  final String? imageFileName;

  /// Terisi mulai status [EstRequestStatus.waitApprovalHod] ke atas.
  final EstMaintenancePlan? plan;

  /// Terisi mulai status [EstRequestStatus.waitVerifyUser] ke atas.
  final EstWorkDetail? workDetail;

  /// True kalau pekerjaan sudah diverifikasi requester (status
  /// [EstRequestStatus.completed]) tapi rating/feedback belum dikirim.
  ///
  /// Sama seperti pola di IT Request: selama masih ada satu saja request
  /// dengan flag ini true, tombol "+ Add Request" disembunyikan.
  final bool awaitingFeedback;

  EstRequestItem copyWith({
    EstRequestStatus? status,
    EstWorkDetail? workDetail,
    bool? awaitingFeedback,
  }) =>
      EstRequestItem(
        id: id,
        requesterName: requesterName,
        department: department,
        type: type,
        location: location,
        description: description,
        date: date,
        status: status ?? this.status,
        imageFileName: imageFileName,
        plan: plan,
        workDetail: workDetail ?? this.workDetail,
        awaitingFeedback: awaitingFeedback ?? this.awaitingFeedback,
      );
}
