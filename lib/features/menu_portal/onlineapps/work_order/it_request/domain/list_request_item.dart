import 'list_request_status.dart';

/// Satu baris di tab "List Request" — daftar SEMUA permintaan (bukan cuma
/// milik sendiri), makanya menyertakan nama & departemen requester.
class ListRequestItem {
  const ListRequestItem({
    required this.id,
    required this.requesterName,
    required this.department,
    required this.description,
    required this.status,
    required this.date,
  });

  final String id;
  final String requesterName;
  final String department;
  final String description;
  final ListRequestStatus status;
  final String date;
}