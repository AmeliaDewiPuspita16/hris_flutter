import 'it_request_status.dart';

/// Satu permintaan IT/Media milik staff yang sedang login.
class ItRequestItem {
  const ItRequestItem({
    required this.id,
    required this.description,
    required this.date,
    required this.status,
    this.awaitingFeedback = false,
  });

  final String id;
  final String description;
  final String date;
  final ItRequestStatus status;

  /// True kalau tim IT sudah menyelesaikan permintaan ini (status
  /// [ItRequestStatus.completed]) tapi staff belum kasih rating/feedback.
  ///
  /// Selama masih ada satu saja request dengan flag ini bernilai true,
  /// tombol "+ Ajukan Request" disembunyikan — staff wajib menyelesaikan
  /// feedback dulu sebelum bisa mengajukan permintaan baru.
  final bool awaitingFeedback;

  ItRequestItem copyWith({bool? awaitingFeedback}) => ItRequestItem(
        id: id,
        description: description,
        date: date,
        status: status,
        awaitingFeedback: awaitingFeedback ?? this.awaitingFeedback,
      );
}
