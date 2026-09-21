/// Contoh respons `GET /api/portal/apps/it_request` dan
/// `GET /api/portal/apps/it_request/{id}`, disalin dari dokumentasi endpoint.
///
/// Amplop daftar berbentuk `{data, summary, meta}` — `summary.awaiting_rating`
/// adalah jumlah request milik user yang sudah dikerjakan tapi belum diberi
/// rating, dihitung server atas SELURUH data (bukan cuma halaman yang
/// termuat). Itu satu-satunya sumber kebenaran untuk mengunci tombol
/// "+ Add Request" — bukan hasil hitung ulang di klien.
///
/// Tiap item juga membawa `requester`, `is_mine`, dan `can_rate` —
/// `can_rate` menggantikan tebakan `status.code == 'done' && rating == null`
/// yang dipakai sebelum field ini ada.
library;

Map<String, dynamic> itRequestListEnvelope({
  List<Map<String, dynamic>>? items,
  int awaitingRating = 0,
  int currentPage = 1,
  int lastPage = 1,
  int perPage = 20,
  int total = 2,
}) {
  return {
    'data': items ?? [itRequestListItem()],
    'summary': {'awaiting_rating': awaitingRating},
    'meta': {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
    },
  };
}

Map<String, dynamic> itRequestListItem({
  int id = 2395,
  String type = 'IT',
  String supportType = 'PERMINTAAN',
  String categoryCode = 'email_req',
  String categoryLabel = 'Email account',
  String description =
      'Tolong email rifki.a@biie.co.id diganti menjadi hse.admin@biie.co.id '
      'dan passwordnya di reset...',
  String approvalCode = 'approved',
  String approvalLabel = 'Approved',
  bool checked = true,
  String statusCode = 'finished',
  String statusLabel = 'Finished',
  int? rating = 5,
  String? imageUrl,
  String createdAt = '2026-08-26T11:11:13+07:00',
  int requesterId = 33,
  String requesterName = 'Admin CRS',
  String requesterDepartment = 'CRS',
  bool isMine = true,
  bool canRate = false,
}) {
  return {
    'id': id,
    'type': type,
    'support_type': supportType,
    'category': {'code': categoryCode, 'label': categoryLabel},
    'description': description,
    'approval': {'code': approvalCode, 'label': approvalLabel},
    'checking': {'checked': checked, 'label': checked ? 'Checked' : 'Belum'},
    'status': {'code': statusCode, 'label': statusLabel},
    'rating': rating,
    'image_url': imageUrl,
    'created_at': createdAt,
    'requester': {
      'id': requesterId,
      'name': requesterName,
      'department': requesterDepartment,
    },
    'is_mine': isMine,
    'can_rate': canRate,
  };
}

/// Detail id 2395: sudah selesai dan dinilai, tanpa needs/new_employee.
Map<String, dynamic> itRequestDetail({
  int id = 2395,
  String statusCode = 'finished',
  String statusLabel = 'Finished',
  int? rating = 5,
  bool canRate = false,
  int requesterId = 29,
  String requesterName = 'Frida Khaerani',
  String requesterDepartment = 'HR & GA',
  List<Map<String, dynamic>>? needs,
  Map<String, dynamic>? newEmployee,
  String? cancelReason,
  String? ratingComment = 'thank youu',
}) {
  return {
    ...itRequestListItem(
      id: id,
      statusCode: statusCode,
      statusLabel: statusLabel,
      rating: rating,
      canRate: canRate,
      requesterId: requesterId,
      requesterName: requesterName,
      requesterDepartment: requesterDepartment,
    ),
    'needs': needs ?? const [],
    'new_employee': newEmployee,
    'specified': {'application': null, 'username': null, 'other': null},
    'handling': {
      'work_by': 'Aditya Yudha Pratama',
      'note': 'Kak ini aku buat akun Rifki Ananta jadi inactive sementara, '
          'untuk HSE Admin kubuat jadi akun baru',
      'date_start': '2026-08-26',
      'date_end': '2026-08-28',
      'date_done': null,
      'result_image_url': 'http://127.0.0.1:8000/storage/gmo/it/img/1787719588.jpg',
    },
    'approved_at': '2026-08-26 11:11:39',
    'cancel_reason': cancelReason,
    'rating_comment': ratingComment,
  };
}
