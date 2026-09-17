/// satu permintaan yang menunggu keputusan (approve/reject) tim IT
class ApproveRequestItem {
  const ApproveRequestItem({
    required this.id,
    required this.requesterName,
    required this.department,
    required this.description,
  });

  final String id;
  final String requesterName;
  final String department;
  final String description;
}