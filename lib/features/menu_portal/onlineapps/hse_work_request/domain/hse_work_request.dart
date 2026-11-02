import '../../../../../core/utils/json_value.dart';
import 'hse_request_category.dart';
import 'hse_request_status.dart';

/// Satu permit HSE dari `/api/portal/apps/hse_permit` — dipakai daftar,
/// detail, dan balasan store/approve/reject/close (bentuknya sama).
///
/// Item di daftar hanya berisi field ringkas: checklist, [documents], dan
/// [closing] kosong di sana, baru terisi dari `GET /hse_permit/{id}`.
class HseWorkRequest {
  const HseWorkRequest({
    required this.id,
    this.idRegister,
    this.requester,
    required this.pic,
    this.departmentId,
    required this.department,
    this.section,
    required this.category,
    this.categoryLabel,
    required this.location,
    required this.materials,
    this.vendor,
    required this.totalWorkers,
    required this.dateStart,
    required this.dateEnd,
    this.acknowledgeBy,
    this.approvalBy,
    this.status = HseRequestStatus.onWaiting,
    this.statusLabel,
    this.isMine = false,
    this.canDelete = false,
    this.canClose = false,
    this.createdAt,
    this.generalChecklist = const [],
    this.otherGeneralChecklist,
    this.typeOfWorks = const [],
    this.otherTypeOfWork,
    this.ppe = const [],
    this.otherPpe,
    this.documents = const {},
    this.closing,
  });

  final int id;

  /// Nomor register, mis. "HSE/REG/2026/11/001".
  final String? idRegister;

  /// Nama user yang mengajukan (bisa beda dari [pic]).
  final String? requester;

  final String pic;
  final int? departmentId;
  final String department;

  /// Hanya terisi untuk departemen EST.
  final String? section;

  final HseRequestCategory category;

  /// Label kategori dari server, mis. "Routine (maintenance, repair)".
  final String? categoryLabel;

  final String location;
  final String materials;
  final String? vendor;
  final int totalWorkers;
  final DateTime dateStart;
  final DateTime dateEnd;

  /// Nama yang acknowledge. Null selama belum sampai tahap itu.
  final String? acknowledgeBy;

  /// Nama approver akhir. Null selama belum di-approve.
  final String? approvalBy;

  final HseRequestStatus status;

  /// Status lengkap dari server, mis. "Waiting Approval HSE" — lebih
  /// rinci dari [status] yang hanya 4 macam.
  final String? statusLabel;

  final bool isMine;

  /// Pemilik dan status masih waiting.
  final bool canDelete;

  /// Pemilik dan status on_progress.
  final bool canClose;

  final DateTime? createdAt;

  final List<String> generalChecklist;
  final String? otherGeneralChecklist;
  final List<String> typeOfWorks;
  final String? otherTypeOfWork;
  final List<String> ppe;
  final String? otherPpe;

  /// URL dokumen per field (`jsa`, `timeline`, `soft_drawing`). Field yang
  /// belum ada / belum boleh dilihat tidak dimasukkan.
  final Map<String, String> documents;

  final HsePermitClosing? closing;

  /// Label status yang ditampilkan: versi server bila ada.
  String get displayStatus => statusLabel ?? status.label;

  factory HseWorkRequest.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! num) {
      throw FormatException('Permit HSE tanpa id: $json');
    }

    final start = dateOrNull(json['date_start']) ?? DateTime.now();
    final end = dateOrNull(json['date_end']) ?? start;
    final docs = json['documents'];
    final closing = json['closing'];

    return HseWorkRequest(
      id: id.toInt(),
      idRegister: textOrNull(json['id_register']),
      requester: textOrNull(json['requester']),
      pic: '${json['pic'] ?? ''}',
      departmentId: json['department_id'] is num
          ? (json['department_id'] as num).toInt()
          : null,
      department: '${json['department'] ?? ''}',
      section: textOrNull(json['section']),
      category: HseRequestCategoryX.fromApi(textOrNull(json['category'])),
      categoryLabel: textOrNull(json['category_label']),
      location: '${json['location'] ?? ''}',
      materials: '${json['materials'] ?? ''}',
      vendor: textOrNull(json['vendor']),
      totalWorkers: json['total_workers'] is num
          ? (json['total_workers'] as num).toInt()
          : int.tryParse('${json['total_workers']}') ?? 0,
      dateStart: start,
      dateEnd: end,
      acknowledgeBy: textOrNull(json['acknowledge_by']),
      approvalBy: textOrNull(json['approval_by']),
      status: HseRequestStatusX.fromApi(textOrNull(json['status'])),
      statusLabel: textOrNull(json['status_label']),
      isMine: json['is_mine'] == true,
      canDelete: json['can_delete'] == true,
      canClose: json['can_close'] == true,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      generalChecklist: _stringList(json['general_checklist']),
      otherGeneralChecklist: textOrNull(json['other_general_checklist']),
      typeOfWorks: _stringList(json['type_of_works']),
      otherTypeOfWork: textOrNull(json['other_type_of_work']),
      ppe: _stringList(json['ppe']),
      otherPpe: textOrNull(json['other_ppe']),
      documents: {
        if (docs is Map)
          for (final entry in docs.entries)
            if (textOrNull(entry.value) != null)
              '${entry.key}': entry.value as String,
      },
      closing: closing is Map<String, dynamic>
          ? HsePermitClosing.fromJson(closing)
          : null,
    );
  }

  static List<String> _stringList(dynamic value) =>
      (value is List ? value : const [])
          .map((e) => '$e')
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
}

/// Data penutupan permit (status Done).
class HsePermitClosing {
  const HsePermitClosing({
    this.description,
    this.evidenceUrl,
    this.closedAt,
  });

  final String? description;
  final String? evidenceUrl;
  final DateTime? closedAt;

  factory HsePermitClosing.fromJson(Map<String, dynamic> json) {
    return HsePermitClosing(
      description: textOrNull(json['description']),
      evidenceUrl: textOrNull(json['evidence_url']),
      closedAt: DateTime.tryParse('${json['closed_at'] ?? ''}'),
    );
  }
}

/// Isian form "Add Permit Request" yang siap dikirim ke `POST /hse_permit`.
class HsePermitDraft {
  const HsePermitDraft({
    required this.pic,
    required this.departmentId,
    this.section,
    required this.categoryCode,
    required this.location,
    required this.materials,
    this.vendor,
    required this.totalWorkers,
    required this.dateStart,
    required this.dateEnd,
    required this.generalChecklist,
    this.otherGeneralChecklist,
    required this.typeOfWorks,
    this.otherTypeOfWork,
    required this.ppe,
    this.otherPpe,
    this.documents = const {},
  });

  final String pic;
  final int departmentId;
  final String? section;
  final String categoryCode;
  final String location;
  final String materials;
  final String? vendor;
  final int totalWorkers;
  final DateTime dateStart;
  final DateTime dateEnd;
  final List<String> generalChecklist;
  final String? otherGeneralChecklist;
  final List<String> typeOfWorks;
  final String? otherTypeOfWork;
  final List<String> ppe;
  final String? otherPpe;

  /// Path berkas PDF per field dokumen (`jsa`, `timeline`, `soft_drawing`).
  /// Hanya untuk NON-RUTIN.
  final Map<String, String> documents;

  /// Field multipart. Array dikirim berindeks (`ppe[0]`, `ppe[1]`, …) —
  /// dibaca Laravel sebagai array yang sama dengan `ppe[]`, tapi muat di
  /// `Map<String, String>` milik `ApiClient.postMultipart`.
  Map<String, String> toFields() {
    String? clean(String? v) => v == null || v.trim().isEmpty ? null : v.trim();

    return {
      'pic': pic.trim(),
      'department_id': '$departmentId',
      if (clean(section) != null) 'section': clean(section)!,
      'category': categoryCode,
      'location': location.trim(),
      'materials': materials.trim(),
      if (clean(vendor) != null) 'vendor': clean(vendor)!,
      'total_workers': '$totalWorkers',
      'date_start': _isoDate(dateStart),
      'date_end': _isoDate(dateEnd),
      for (var i = 0; i < generalChecklist.length; i++)
        'general_checklist[$i]': generalChecklist[i],
      if (clean(otherGeneralChecklist) != null)
        'other_general_checklist': clean(otherGeneralChecklist)!,
      for (var i = 0; i < typeOfWorks.length; i++)
        'type_of_works[$i]': typeOfWorks[i],
      if (clean(otherTypeOfWork) != null)
        'other_type_of_work': clean(otherTypeOfWork)!,
      for (var i = 0; i < ppe.length; i++) 'ppe[$i]': ppe[i],
      if (clean(otherPpe) != null) 'other_ppe': clean(otherPpe)!,
    };
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
