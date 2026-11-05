import 'observation_category.dart';
import 'observation_status.dart';

/// Satu baris observasi — gabungan kolom tabel web (No, Created Date,
/// Name - Dept, Category, Location, Relevant Dept, Description, Status) dan
/// isi PDF detail (Description Close, Close Date, Closed By, Image Finding,
/// Image Close).
class ObservationItem {
  const ObservationItem({
    required this.id,
    required this.createdDate,
    required this.reporterName,
    required this.reporterDept,
    required this.category,
    this.subCategory,
    required this.location,
    required this.relevantDept,
    required this.description,
    required this.status,
    required this.isFromMyDept,
    required this.isMine,
    this.canEdit = false,
    this.canDelete = false,
    this.canClose = false,
    this.imageRequiredToClose = false,
    this.findingImage,
    this.closeReason,
    this.closeDate,
    this.closedBy,
    this.closeImage,
  });

  /// Membaca satu objek temuan dari `GET /api/data/observation` (dan
  /// endpoint detail, bentuknya sama). Melempar [FormatException] bila
  /// `id` atau `date_finding` tidak bisa dibaca, supaya pemanggil bisa
  /// melewati baris yang rusak.
  factory ObservationItem.fromJson(Map<String, dynamic> json) {
    final id = _text(json['id']);
    final date = DateTime.tryParse(_text(json['date_finding']) ?? '');
    if (id == null || date == null) {
      throw FormatException('Observation tanpa id / date_finding: $json');
    }

    final status = _text(json['status'])?.toLowerCase() == 'closed'
        ? ObservationStatus.closed
        : ObservationStatus.open;

    return ObservationItem(
      id: id,
      createdDate: date,
      reporterName: _text(json['reporter_name']) ?? '-',
      reporterDept: _text(json['reporter_department']) ?? '-',
      category: _categoryFrom(_text(json['category'])),
      subCategory: _text(json['finding_category']),
      location: _text(json['location']) ?? '-',
      relevantDept: _text(json['relevant_department']) ?? '-',
      description: _text(json['description']) ?? '-',
      status: status,
      isFromMyDept: json['is_for_my_department'] == true,
      isMine: json['is_mine'] == true,
      canEdit: json['can_edit'] == true,
      canDelete: json['can_delete'] == true,
      canClose: json['can_close'] == true,
      imageRequiredToClose: json['image_required_to_close'] == true,
      findingImage: _text(json['image_finding_url']),
      closeReason: _text(json['reason_close']),
      closeDate: DateTime.tryParse(_text(json['date_close']) ?? ''),
      closedBy: _text(json['closed_by']),
      closeImage: _text(json['image_close_url']),
    );
  }

  final String id;
  final DateTime createdDate;
  final String reporterName;
  final String reporterDept;
  final ObservationCategory category;

  /// Mis. "Nearmiss" untuk "Safety (Nearmiss)"; null bila kategori tanpa
  /// sub-jenis.
  final String? subCategory;
  final String location;
  final String relevantDept;
  final String description;
  final ObservationStatus status;

  /// Ditujukan ke departemen user yang login (`is_for_my_department`).
  final bool isFromMyDept;

  /// Dibuat oleh user yang sedang login (`is_mine`).
  final bool isMine;

  /// Hak akses yang dihitung server (`can_edit`, `can_delete`, `can_close`):
  /// UI cukup mengikuti flag ini, tanpa logika izin sendiri.
  final bool canEdit;
  final bool canDelete;
  final bool canClose;

  /// Form Close wajib upload foto atau tidak (`image_required_to_close`).
  final bool imageRequiredToClose;

  /// Foto temuan / foto penutupan: URL (http...) atau path file lokal.
  final String? findingImage;
  final String? closeReason;
  final DateTime? closeDate;
  final String? closedBy;
  final String? closeImage;

  bool get isOpen => status == ObservationStatus.open;

  /// Punya setidaknya satu aksi ubah (Edit atau Delete).
  bool get canModify => canEdit || canDelete;

  /// "Safety (Nearmiss)" / "Quality".
  String get categoryLabel => subCategory == null
      ? category.label
      : '${category.label} ($subCategory)';

  /// Kolom "Name - Dept".
  String get reporter => '$reporterName - $reporterDept';

  ObservationItem copyWith({
    ObservationStatus? status,
    String? closeReason,
    DateTime? closeDate,
    String? closedBy,
    String? closeImage,
  }) {
    return ObservationItem(
      id: id,
      createdDate: createdDate,
      reporterName: reporterName,
      reporterDept: reporterDept,
      category: category,
      subCategory: subCategory,
      location: location,
      relevantDept: relevantDept,
      description: description,
      status: status ?? this.status,
      isFromMyDept: isFromMyDept,
      isMine: isMine,
      canEdit: canEdit,
      canDelete: canDelete,
      canClose: canClose,
      imageRequiredToClose: imageRequiredToClose,
      findingImage: findingImage,
      closeReason: closeReason ?? this.closeReason,
      closeDate: closeDate ?? this.closeDate,
      closedBy: closedBy ?? this.closedBy,
      closeImage: closeImage ?? this.closeImage,
    );
  }

  /// Angka maupun teks diterima (id dari server berupa int, di aplikasi
  /// dipakai sebagai String). Teks kosong dianggap tidak ada.
  static String? _text(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// Mencocokkan nama kategori dari server dengan enum, tanpa peduli
  /// huruf besar/kecil. Kategori yang belum dikenal dianggap Quality
  /// supaya satu baris aneh tidak menjatuhkan seluruh daftar.
  static ObservationCategory _categoryFrom(String? value) {
    final key = value?.toLowerCase();
    for (final c in ObservationCategory.values) {
      if (c.label.toLowerCase() == key) return c;
    }
    return ObservationCategory.quality;
  }
}
