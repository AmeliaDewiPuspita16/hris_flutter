/// Fixture kontrak respons EST Project Monitoring, disusun dari key yang
/// dibaca `fromJson` di aplikasi DW (belum ada respons hasil tangkapan).
const Map<String, dynamic> estNotClockedOutJson = {
  'id': 7,
  'name': 'Budi',
  'clock_in': '07:30',
};

const Map<String, dynamic> estExecutiveProjectJson = {
  'id': 1,
  'name': 'Proyek Alpha',
  'job_number': 'JOB-001',
  'location': 'Batam',
  'budget_hours': 1500,
  'used_hours': 750.5,
  'remaining_hours': 749.5,
  'progress_percent': 50,
  'status': 'active',
  'start_date': '2026-01-01',
  'target_end_date': '2026-12-31',
  'session_status': 'open',
  'session_id': 9,
  'session_opened_at': '2026-10-30 07:00:00',
  'not_clocked_out': 1,
  'not_clocked_out_list': [estNotClockedOutJson],
};

const Map<String, dynamic> estExecutiveProjectMinimalJson = {
  'id': 2,
  'name': 'Proyek Beta',
  'location': 'Jakarta',
  'budget_hours': 0,
  'used_hours': 10,
  'remaining_hours': 0,
  'progress_percent': 0,
  'status': 'active',
  'start_date': '2026-02-01',
  'target_end_date': '2026-06-30',
};

const Map<String, dynamic> estExecutiveDashboardJson = {
  'summary': {
    'active_projects': 2,
    'total_worker_today': 30,
    'hours_used_pct': 42,
  },
  'projects': [estExecutiveProjectJson, estExecutiveProjectMinimalJson],
};

const Map<String, dynamic> estMandorJson = {
  'id': 5,
  'name': 'Siti Aminah',
  'is_substitute': true,
  'assignment_id': 33,
  'substitute_for': {'id': 4, 'name': 'Joko Widodo'},
};

const Map<String, dynamic> estExecProjectFullJson = {
  'data': {
    'id': 1,
    'mandors': [estMandorJson],
    'avg_hours_per_day': 12.5,
    'estimated_days_left': 20,
    'closed_at': '2026-12-31',
  },
};

const Map<String, dynamic> estProjectWorkerJson = {
  'worker_id': 11,
  'name': 'Andi Pratama',
  'nik': '3171000000000001',
  'photo': 'https://example.com/a.jpg',
  'clock_in': '07:05',
  'clock_out': '16:00',
  'is_clocked_in': true,
  'hours_today': 8.5,
  'attendance_condition': 2,
  'is_substitute': true,
  'substitute_for': {'name': 'Rudi'},
  'assignment_id': 44,
};

const Map<String, dynamic> estEmployeeMandorJson = {
  'id': 5,
  'name': 'Siti Aminah',
  'email': 'siti@example.com',
  'phone': '08123456789',
};

const Map<String, dynamic> estAvailableWorkerJson = {
  'id': 21,
  'name': 'Dewi',
  'nik': '3171000000000002',
  'skills': 'Welder',
  'placement': 'Proyek Alpha',
};
