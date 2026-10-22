import '../../../domain/purchase_requisition.dart';

enum PrDetailStatus { initial, loading, success, failure }

/// Pesan singkat hasil sebuah aksi, untuk ditampilkan sekali sebagai snackbar.
///
/// Dibandingkan lewat identitas objek (bukan isi), jadi dua pesan yang
/// bunyinya sama tetap dianggap dua kejadian berbeda.
class PrActionFeedback {
  const PrActionFeedback(this.message, {this.isError = false});

  final String message;
  final bool isError;
}

/// Keadaan layar detail PR.
class PrDetailState {
  const PrDetailState({
    this.status = PrDetailStatus.initial,
    this.requisition,
    this.errorMessage,
    this.isSubmitting = false,
    this.feedback,
  });

  final PrDetailStatus status;

  /// Terisi hanya setelah rinciannya berhasil diambil. Kepala layar sebelum
  /// itu digambar dari ringkasan yang sudah dibawa dari daftar.
  final PurchaseRequisition? requisition;

  final String? errorMessage;

  /// True selama approve/revisi/reject sedang dikirim ke server.
  final bool isSubmitting;

  /// Hasil aksi terakhir. Hanya ada disatu state; state berikutnya
  /// membersihkannya lagi (lihat [copyWith]).
  final PrActionFeedback? feedback;

  /// [feedback] sengaja TIDAK dibawa dari state lama: pesan hanya berlaku
  /// untuk satu perpindahan state, supaya tidak muncul dua kali
  PrDetailState copyWith({
    PrDetailStatus? status,
    PurchaseRequisition? requisition,
    String? errorMessage,
    bool? isSubmitting,
    PrActionFeedback? feedback,
  }) {
    return PrDetailState(
      status: status ?? this.status,
      requisition: requisition ?? this.requisition,
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      feedback: feedback,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrDetailState &&
          other.status == status &&
          identical(other.requisition, requisition) &&
          other.errorMessage == errorMessage &&
          other.isSubmitting == isSubmitting &&
          identical(other.feedback, feedback);

  @override
  int get hashCode => Object.hash(status, requisition, errorMessage, isSubmitting, feedback);

  @override
  String toString() =>
      'PrDetailState(${status.name}, submitting: $isSubmitting,  error: $errorMessage)';
}
