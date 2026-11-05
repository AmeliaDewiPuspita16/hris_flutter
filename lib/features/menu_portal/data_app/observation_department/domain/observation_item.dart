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
    this.findingImage,
    this.closeReason,
    this.closeDate,
    this.closedBy,
    this.closeImage,
  });

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

  /// Dilaporkan oleh departemen user yang login — penentu baris ini masuk
  /// tab "My Dept Open" dan boleh di-Close (tabel "Request Table - OPEN
  /// Observations from Your Department" di web).
  final bool isFromMyDept;

  /// Foto temuan / foto penutupan: URL (http...) atau path file lokal.
  final String? findingImage;
  final String? closeReason;
  final DateTime? closeDate;
  final String? closedBy;
  final String? closeImage;

  bool get isOpen => status == ObservationStatus.open;
  bool get canClose => isOpen && isFromMyDept;

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
      findingImage: findingImage,
      closeReason: closeReason ?? this.closeReason,
      closeDate: closeDate ?? this.closeDate,
      closedBy: closedBy ?? this.closedBy,
      closeImage: closeImage ?? this.closeImage,
    );
  }
}
