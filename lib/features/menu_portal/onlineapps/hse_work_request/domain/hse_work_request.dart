import '../../../../../core/utils/json_value.dart';
import 'hse_request_category.dart';
import 'hse_request_status.dart';

/// Satu permit HSE Work Request, baik hasil GET list/detail dari server
/// maupun draft yang sedang diisi user di form Add Request.
///
/// fromJson]/[toJson] ditulis dengan asumsi untuk REST API — sesuaikan nama field-nya
/// begitu endpoint ada
class HseWorkRequest {
  const HseWorkRequest({
    this.id,
    this.idRegister,
    required this.pic,
    required this.department,
    required this.category,
    required this.location,
    required this.materials,
    this.vendor,
    required this.totalWorkers,
    required this.dateStart,
    required this.dateEnd,
    this.generalChecklist = const [],
    this.otherGeneralChecklist,
    this.typeOfWorks = const [],
    this.otherTypeOfWork,
    this.ppe = const [],
    this.otherPpe,
    this.acknowledgeBy,
    this.approvalBy,
    this.status = HseRequestStatus.onWaiting,
  });

  /// Null selama draft belum pernah disubmit ke server.
  final int? id;

  /// Nomor register, mis. "HSE/REG/2026/09/017". Diterbitkan server —
  /// null selama draft.
  final String? idRegister;

  final String pic;
  final String department;
  final HseRequestCategory category;
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

  /// Nama HOD yang acknowledge. Null selama masih "Waiting Acknowledge".
  final String? acknowledgeBy;

  /// Nama approver akhir. Null selama belum sampai tahap approval.
  final String? approvalBy;

  final HseRequestStatus status;

  HseWorkRequest copyWith({
    int? id,
    String? idRegister,
    String? pic,
    String? department,
    HseRequestCategory? category,
    String? location,
    String? materials,
    String? vendor,
    int? totalWorkers,
    DateTime? dateStart,
    DateTime? dateEnd,
    List<String>? generalChecklist,
    String? otherGeneralChecklist,
    List<String>? typeOfWorks,
    String? otherTypeOfWork,
    List<String>? ppe,
    String? otherPpe,
    String? acknowledgeBy,
    String? approvalBy,
    HseRequestStatus? status,
  }) {
    return HseWorkRequest(
      id: id ?? this.id,
      idRegister: idRegister ?? this.idRegister,
      pic: pic ?? this.pic,
      department: department ?? this.department,
      category: category ?? this.category,
      location: location ?? this.location,
      materials: materials ?? this.materials,
      vendor: vendor ?? this.vendor,
      totalWorkers: totalWorkers ?? this.totalWorkers,
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      generalChecklist: generalChecklist ?? this.generalChecklist,
      otherGeneralChecklist: otherGeneralChecklist ?? this.otherGeneralChecklist,
      typeOfWorks: typeOfWorks ?? this.typeOfWorks,
      otherTypeOfWork: otherTypeOfWork ?? this.otherTypeOfWork,
      ppe: ppe ?? this.ppe,
      otherPpe: otherPpe ?? this.otherPpe,
      acknowledgeBy: acknowledgeBy ?? this.acknowledgeBy,
      approvalBy: approvalBy ?? this.approvalBy,
      status: status ?? this.status,
    );
  }

  /// Draft kosong untuk membuka form Add Request.
  factory HseWorkRequest.empty() => HseWorkRequest(
        pic: '',
        department: '',
        category: HseRequestCategory.rutin,
        location: '',
        materials: '',
        totalWorkers: 0,
        dateStart: DateTime.now(),
        dateEnd: DateTime.now(),
      );

  factory HseWorkRequest.fromJson(Map<String, dynamic> json) {
    final start = dateOrNull(json['date_start']) ?? DateTime.now();
    final end = dateOrNull(json['date_end']) ?? start;

    return HseWorkRequest(
      id: json['id'] is int ? json['id'] as int : intOr(json['id'], 0),
      idRegister: textOrNull(json['id_register']),
      pic: '${json['pic'] ?? ''}',
      department: '${json['department'] ?? ''}',
      category: HseRequestCategoryX.fromApi(textOrNull(json['category'])),
      location: '${json['location'] ?? ''}',
      materials: '${json['materials'] ?? ''}',
      vendor: textOrNull(json['vendor']),
      totalWorkers: intOr(json['total_workers'], 0),
      dateStart: start,
      dateEnd: end,
      generalChecklist: _stringList(json['general_checklist']),
      otherGeneralChecklist: textOrNull(json['other_general_checklist']),
      typeOfWorks: _stringList(json['type_of_works']),
      otherTypeOfWork: textOrNull(json['other_type_of_work']),
      ppe: _stringList(json['ppe']),
      otherPpe: textOrNull(json['other_ppe']),
      acknowledgeBy: textOrNull(json['acknowledge_by']),
      approvalBy: textOrNull(json['approval_by']),
      status: HseRequestStatusX.fromApi(textOrNull(json['status'])),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'pic': pic,
        'department': department,
        'category': category.toApi(),
        'location': location,
        'materials': materials,
        if (vendor != null && vendor!.isNotEmpty) 'vendor': vendor,
        'total_workers': totalWorkers,
        'date_start': _isoDate(dateStart),
        'date_end': _isoDate(dateEnd),
        'general_checklist': generalChecklist,
        if (otherGeneralChecklist != null && otherGeneralChecklist!.isNotEmpty)
          'other_general_checklist': otherGeneralChecklist,
        'type_of_works': typeOfWorks,
        if (otherTypeOfWork != null && otherTypeOfWork!.isNotEmpty)
          'other_type_of_work': otherTypeOfWork,
        'ppe': ppe,
        if (otherPpe != null && otherPpe!.isNotEmpty) 'other_ppe': otherPpe,
      };

  static List<String> _stringList(dynamic value) =>
      (value as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
