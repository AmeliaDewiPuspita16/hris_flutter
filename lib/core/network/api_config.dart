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

  /// Ganti password user yang sedang login. Body: `current_password`,
  /// `new_password` (min. 8 karakter, beda dari yang lama), dan
  /// `new_password_confirmation`. Berhasil: `data: null`. Password lama
  /// salah atau password baru tidak valid dibalas 422 dengan `errors`.
  static const String updatePassword = '/api/update_password';

  /// Cover kartu profil saat ini (`data.cover`) beserta daftar preset
  /// (`data.presets`) untuk layar "Change cover".
  static const String profileCover = '/api/profile_cover';

  /// Ganti cover, multipart dengan salah satu dari: `preset=<key>`,
  /// berkas `cover` (JPG/PNG, maks 6 MB, min 800x300 px), atau `keep=1`
  /// (atur ulang posisi gambar upload). Gambar boleh disertai
  /// `position[size|x|y]`. Responsnya `data.cover` yang baru.
  static const String updateProfileCover = '/api/update_profile_cover';

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

  /// EST Work Order — daftar semua request di path ini (`?mine=1`, `status`,
  /// `type`, `per_page`, `page`). Seperti [eprocurement], `summary` dan
  /// `meta` bersebelahan dengan `data`, jadi diambil lewat
  /// [ApiClient.getEnvelope].
  static const String estRequest = '/api/portal/apps/est_work_order';

  /// Detail satu WO (rencana kerja, laporan selesai, timeline progress).
  /// `data`-nya satu objek, jadi cukup [ApiClient.get].
  static String estRequestDetail(int id) => '$estRequest/$id';

  /// Antrean keputusan HOD (hanya role `hod`).
  static const String estRequestApprovals = '$estRequest/approvals';

  static String estRequestApprove(int id) => '$estRequest/$id/approve';
  static String estRequestReject(int id) => '$estRequest/$id/reject';

  /// Verifikasi + rating oleh requester untuk WO yang sudah selesai
  /// (`can_rate = true`). Body: `star` (1-5) dan `message` (wajib, maks 1000
  /// karakter). Setelah ini status WO menjadi `finished`.
  static String estRequestRating(int id) => '$estRequest/$id/rating';

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

  /// FCM token perangkat ini. POST `{token, platform}` setelah login dan
  /// tiap kali token dirotasi; DELETE `?token=` saat logout. Token disimpan
  /// server di tabel sendiri (project Firebase `biie-portal-hris`), terpisah
  /// dari `users.fcm_token` milik app lama.
  static const String deviceToken = '/api/portal/apps/device-token';

  /// Isi tab Notifications dari server (`?unread=1`, `module`, `per_page`,
  /// `page`). `summary.unread` dan `meta` bersebelahan dengan `data`, jadi
  /// diambil lewat [ApiClient.getEnvelope].
  static const String notifications = '/api/portal/apps/notifications';

  static const String notificationsReadAll = '$notifications/read-all';
  static String notificationRead(int id) => '$notifications/$id/read';

  /// DELETE — membuang satu entri dari tab Notifications (geser untuk hapus).
  static String notificationDetail(int id) => '$notifications/$id';
}
