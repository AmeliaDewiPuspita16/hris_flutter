import '../../domain/leave_approval_request.dart';

enum LeaveApprovalLoadStatus { initial, loading, success, failure }

/// Pesan sekali-tayang untuk ditampilkan sebagai SnackBar setelah sebuah
/// keputusan diproses.
///
/// Sengaja TANPA `==`: setiap instance baru dianggap kejadian baru, jadi
/// `BlocListener.listenWhen` cukup membandingkan identitas dan tidak menembak
/// ulang untuk state lain yang membawa feedback lama.
class LeaveApprovalFeedback {
  const LeaveApprovalFeedback(
    this.message, {
    this.isError = false,
    this.decided,
  });

  final String message;
  final bool isError;

  /// Pengajuan hasil keputusan yang berhasil; null kalau gagal. Dipakai
  /// pemanggil untuk menyinkronkan tempat lain (mis. notifikasi).
  final LeaveApprovalRequest? decided;
}

/// Keadaan halaman Leave Approvals.
class LeaveApprovalState {
  const LeaveApprovalState({
    this.status = LeaveApprovalLoadStatus.initial,
    this.items = const [],
    this.processingIds = const {},
    this.errorMessage,
    this.feedback,
  });

  final LeaveApprovalLoadStatus status;
  final List<LeaveApprovalRequest> items;

  /// Id pengajuan yang keputusannya sedang dikirim — tombolnya dinonaktifkan
  /// supaya tidak terkirim dua kali.
  final Set<String> processingIds;

  final String? errorMessage;
  final LeaveApprovalFeedback? feedback;

  /// Yang menunggu keputusan, terbaru di atas.
  List<LeaveApprovalRequest> get pending => items
      .where((r) => r.isPending)
      .toList()
    ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  /// Yang sudah diputuskan, keputusan terbaru di atas.
  List<LeaveApprovalRequest> get history => items
      .where((r) => !r.isPending)
      .toList()
    ..sort((a, b) => (b.decidedAt ?? b.submittedAt)
        .compareTo(a.decidedAt ?? a.submittedAt));

  int get pendingCount => items.where((r) => r.isPending).length;

  LeaveApprovalState copyWith({
    LeaveApprovalLoadStatus? status,
    List<LeaveApprovalRequest>? items,
    Set<String>? processingIds,
    String? errorMessage,
    LeaveApprovalFeedback? feedback,
  }) {
    return LeaveApprovalState(
      status: status ?? this.status,
      items: items ?? this.items,
      processingIds: processingIds ?? this.processingIds,
      // errorMessage sengaja tidak dipertahankan (pola sama dengan bloc
      // lain): hilang begitu ada state baru.
      errorMessage: errorMessage,
      feedback: feedback ?? this.feedback,
    );
  }
}
