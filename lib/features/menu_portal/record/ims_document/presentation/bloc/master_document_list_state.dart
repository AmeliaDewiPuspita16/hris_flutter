import '../../domain/master_document.dart';

enum MasterDocumentListStatus { initial, loading, success, failure }

/// Keadaan daftar dokumen master satu tab (Manual, SOP, dst).
class MasterDocumentListState {
  const MasterDocumentListState({
    this.status = MasterDocumentListStatus.initial,
    this.documents = const [],
    this.errorMessage,
  });

  final MasterDocumentListStatus status;
  final List<MasterDocument> documents;
  final String? errorMessage;

  MasterDocumentListState copyWith({
    MasterDocumentListStatus? status,
    List<MasterDocument>? documents,
    String? errorMessage,
  }) {
    return MasterDocumentListState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      errorMessage: errorMessage,
    );
  }
}
