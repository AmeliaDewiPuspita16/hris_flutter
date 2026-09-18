import 'progress_state.dart';

/// Rincian di dalam sebuah [DocumentStage] — dipakai tahap "PR Approval"
/// yang menurunkan lagi jadi HOD / Under Review / DGM / Finance / GM.
class DocumentSubStep {
  const DocumentSubStep({
    required this.label,
    required this.state,
    this.note,
  });

  /// Ex: "HOD".
  final String label;

  /// Ex: "Menunggu persetujuan". Null bila tahap ini belum punya kabar apa pun.
  final String? note;

  final ProgressState state;
}

/// Satu tahap di "Progress Dokumen": PR Approval -> Vendor Tally ->
/// Purchase Order -> Goods Receipt.
///
/// Bentuknya berbeda dari [ApprovalStep] (bertingkat, bukan bernomor), jadi
/// dimodelkan terpisah alih-alih dipaksa jadi satu model dengan field
/// nullable yang cuma kepakai di salah satu timeline.
class DocumentStage {
  const DocumentStage({
    required this.title,
    required this.statusLabel,
    required this.state,
    this.subSteps = const [],
  });

  /// Ex: "PR Approval".
  final String title;

  /// Ex: "Sedang Berjalan", "Belum dibuat", "Belum ada".
  final String statusLabel;

  final ProgressState state;
  final List<DocumentSubStep> subSteps;
}
