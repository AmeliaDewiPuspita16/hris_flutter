/// Contoh respons `GET /api/portal/hr_announcement`, mengikuti dokumentasi.
///
/// Perhatikan dua hal: amplopnya `{data, meta}` tanpa `status`, dan tiap
/// item berbentuk sama persis dengan `data` pada respons 201 saat menerbitkan.
Map<String, dynamic> announcementListEnvelope({
  List<Map<String, dynamic>>? items,
  int currentPage = 1,
  int lastPage = 1,
  int perPage = 20,
  int? total,
}) {
  final list = items ?? [announcementListItem()];
  return {
    'data': list,
    'meta': {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total ?? list.length,
    },
  };
}

Map<String, dynamic> announcementListItem({
  int id = 1,
  String title = 'Payroll cut-off pindah ke tanggal 23',
  String? body = 'Klaim lembur disetujui HOD sebelum 23 Sep, 17:00.',
  int departmentId = 8,
  String departmentName = 'HR & GA',
  String createdAt = '2026-09-16T10:30:29+07:00',
  List<Map<String, dynamic>>? photos,
}) =>
    {
      'id': id,
      'title': title,
      'body': body,
      'department': {'id': departmentId, 'name': departmentName},
      'posted_by': {'id': 22, 'name': 'Budi Hartono Hasibuan'},
      'created_at': createdAt,
      'photos': photos ??
          [
            {
              'id': 1,
              'url':
                  'https://biieportal.co.id/storage/hrga/announcements/s7CY.jpg',
              'file_name': 'poster1.jpg',
              'file_size': 2591,
            },
          ],
    };
