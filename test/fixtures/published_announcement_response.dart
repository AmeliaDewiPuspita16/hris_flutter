/// Contoh respons 201 dari `POST /api/portal/hr_announcement`, mengikuti
/// dokumentasi API. Perhatikan: tidak ada `code` maupun `status` di sini —
/// amplopnya berbeda dari `POST /api/login`.
Map<String, dynamic> publishAnnouncementEnvelope() => {
      'message': 'Pengumuman berhasil diterbitkan.',
      'data': publishAnnouncementData(),
    };

Map<String, dynamic> publishAnnouncementData() => {
      'id': 1,
      'title': 'Payroll cut-off pindah ke tanggal 23',
      'body': 'Klaim lembur disetujui HOD sebelum 23 Sep, 17:00.',
      'department': {'id': 8, 'name': 'HR & GA'},
      'posted_by': {'id': 22, 'name': 'Budi Hartono Hasibuan'},
      'created_at': '2026-09-16T10:30:29+07:00',
      'photos': [
        {
          'id': 1,
          'url': 'http://127.0.0.1:8000/storage/announcements/s7CY.jpg',
          'file_name': 'poster1.jpg',
        },
        {
          'id': 2,
          'url': 'http://127.0.0.1:8000/storage/announcements/YJ6o.png',
          'file_name': 'poster2.png',
        },
      ],
    };
