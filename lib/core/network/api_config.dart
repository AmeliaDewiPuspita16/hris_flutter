/// Alamat backend BIIE Portal beserta path endpoint-nya.
///
/// Base URL bisa ditimpa saat build tanpa mengubah kode, berguna untuk
/// menunjuk ke server staging atau ke IP lokal saat pengembangan:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
/// ```
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://biieportal.co.id',
    // defaultValue: 'http://127.0.0.1:8000',
  );

  /// Batas tunggu satu request sebelum dianggap gagal.
  static const Duration timeout = Duration(seconds: 20);

  static const String login = '/api/login';
  static const String logout = '/api/logout';

  /// Ganti foto profil milik user yang sedang login. Multipart dengan satu
  /// field berkas `avatar` (jpeg/jpg/png, maks 1024 KB). Responsnya
  /// berbentuk sama dengan login: `access_token`, `token_type`, `user`.
  static const String uploadProfile = '/api/upload_profile';

  /// Daftar departemen aktif — dipakai buat ngisi dropdown, misalnya di
  /// form pengumuman. Server yang urus filter `is_active` dan urutannya.
  static const String department = '/api/data/department';

  /// Menerbitkan pengumuman HR. Perlu izin `hr-announcement-post`, yang
  /// dimiliki role `hrga` dan `admin`. Dikirim sebagai multipart karena
  /// menerima lampiran `photos[]`.
  static const String hrAnnouncement = '/api/portal/hr_announcement';

  /// Procurement Monitoring. Daftar PR di path ini, detail satu PR di
  /// `$eprocurement/{id}`.
  ///
  /// Endpoint daftarnya menaruh `summary` dan `meta` bersebelahan dengan
  /// `data`, jadi harus diambil lewat [ApiClient.getEnvelope], bukan
  /// `getList`.
  static const String eprocurement = '/api/portal/apps/eprocurement';

  /// Keputusan atasan atas satu PR, dikirim dengan POST ke
  /// `$eprocurement/{id}/approve`, `/revision`, atau `/reject`.
  ///
  /// Body berisi `comments`: opsional untuk approve, wajib untuk revision
  /// dan reject
  static String eprocurementAction(int id, String action) =>
      '$eprocurement/$id/$action';

  /// IT/Media Request — riwayat permintaan milik user sendiri. Daftar di
  /// path ini, detail satu request di `$itRequest/{id}`.
  ///
  /// Sama seperti [eprocurement], endpoint daftarnya menaruh `summary` dan
  /// `meta` bersebelahan dengan `data`, jadi harus diambil lewat
  /// [ApiClient.getEnvelope].
  static const String itRequest = '/api/portal/apps/it_request';

  /// Daftar driver untuk dropdown Asign Vehicle (role admin driver).
  /// Responnya array polos, bukan amplop {data: ...}
  static const String indentDrivers = '/api/indent/admin/list_driver';

  /// Daftar SEMUA indent (semua user) untuk tab "List of User Requests"
  /// Respons dibungkus {message, status, data: [...]} dengan 'status
  /// berupa angka 200 (bukan kata 'success')
  static const String indent = '/api/indent';

  static const String indentMyList = '/api/indent/list';

  /// Buat indent baru, atau perbarui yang ada bila `id_recuitment` dikirim.
  static const String indentStore = '/api/indent/vehicle/store';

  /// Untuk request yang sudah selesai, dan user mharus memberikan feedback
  static const String indentStoreRating = '/api/indent/vehicle/store_rating';

  /// Request yang menunggu keputusan atasan (hanya role `hod`).
  static const String indentHodList = '/api/list_hod_approve';
  static const String indentHodApprove = '/api/indent/vehicle/approve_hod';
  static const String indentHodReject = '/api/indent/vehicle/reject_hod';

  /// Request yang menunggu admin driver menetapkan kendaraan (tab Pending
  /// Vehicle Assigment). ISinya bergantung role pemanggil: untuk
  /// 'driver-admin' berisi request yang lolos HOD tapi belum diproses; untuk
  /// role lain bentuknya sama tapi isinya lain (atau kosong). Respons
  /// `{data: [...], admin: bool}` - ambil lewat [ApiClient.getEnvelope].
  static const String indentAdminList = '/api/indent/admin/list';

  /// Admin menetapkan kendaraan + driver ('status: 1') atau membatalkan
  /// ('status: 5').
  static const String indentAdminApprove = '/api/admin_indent/approve';

  // --------------------------------- HRIS ----------------------------

  /// HRIS attendance. satu endpoint dua pemakai: 'today_schedule' untuk
  /// kartu jam kerja di BEranda, sedangkan 'month/summary/days' itu untuk
  /// layar Log Absensi (belum disambungkan)
  static const String attendance = '/api/portal/apps/hris/attendance';

  /// Jadwal shift per bulan (`?month=YYYY-MM`): satu entri per tanggal,
  /// termasuk tanggal yang belum terjadi. Dipakai Log Absensi untuk mengisi
  /// jadwal di tanggal yang belum punya realisasi kehadiran
  static const String shift = '/api/portal/apps/hris/shift';

  /// HRIS status pengajuan cuti milik user yang login (tab Status di layar
  /// Pengajuan). `data` berupa list, jadi diambil lewat [ApiClient.getList].
  static const String leaveStatus = '/api/portal/apps/hris/leave/status';

  /// Realisasi lembur per bulan (`?month=YYYY-MM`): total jam + menit lembur
  /// per tanggal, dihitung dari check-in/out absensi. Dipakai Log Absensi
  /// dan, nanti, tab Summary di Overtime Request.
  static const String overtime = '/api/portal/apps/hris/overtime';

  // ------------------------------ Notifications ------------------------

  /// Ringkasan jumlah approval yang masih menunggu, dipecah per modul
  /// (`it_request`, `est_work_order`, `indent_vehicle`, `eprocurement`) —
  /// dipakai banner "Approvals waiting" di Beranda. Leave TIDAK termasuk di
  /// sini; jumlahnya dari [leaveStatus]/`LeaveApprovalRepository` sendiri.
  static const String approvalsWaiting =
      '/api/portal/apps/notifications/approvals-waiting';
}
