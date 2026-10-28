import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/announcement_repository.dart';
import '../../data/approvals_waiting_repository.dart';
import '../../domain/approvals_waiting_summary.dart';
import '../../../absensi/presentation/screens/absensi_screen.dart';
import '../../../absensi/data/absensi_repository.dart';
import '../../../kelola_tim/presentation/screens/kelola_tim_screen.dart';
import '../../../department_attendance/presentation/screens/department_attendance_screen.dart';
import '../../../leave_approval/data/leave_approval_repository.dart';
import '../../../leave_approval/domain/leave_approval_request.dart';
import '../../../leave_approval/domain/leave_approval_status.dart';
import '../../../leave_approval/presentation/screens/leave_approval_screen.dart';
import '../../../menu_portal/data_app/indent_vehicle/data/indent_vehicle_repository.dart';
import '../../../menu_portal/data_app/indent_vehicle/domain/indent_assign_result.dart';
import '../../../menu_portal/data_app/indent_vehicle/domain/indent_pending_item.dart';
import '../../../menu_portal/data_app/indent_vehicle/presentation/screens/indent_vehicle_screen.dart';
import '../../../menu_portal/data_app/indent_vehicle/presentation/widgets/indent_assign_sheet.dart';
import '../../../menu_portal/onlineapps/presentation/screens/online_apps_screen.dart';
import '../../../menu_portal/onlineapps/procurement/domain/pr_status.dart';
import '../../../menu_portal/onlineapps/procurement/presentation/screens/procurement_page.dart';
import '../../../menu_portal/onlineapps/work_order/est_request/presentation/screens/est_request_screen.dart';
import '../../../menu_portal/onlineapps/work_order/it_request/presentation/screens/it_request_screen.dart';
import '../../../menu_portal/record/presentation/screens/record_screen.dart';
import '../../../menu_portal/data_app/presentation/screens/data_screen.dart';
import '../../../notifikasi/domain/notification_category.dart';
import '../../../notifikasi/domain/notification_filter.dart';
import '../widgets/approval_summary_banner.dart';
import '../../../pengajuan/presentation/screens/pengajuan_screen.dart';
import '../../../overtime_request/presentation/screens/overtime_request_screen.dart';
import '../../../profil/presentation/screens/profil_screen.dart';
import '../../../gaji/presentation/screens/gaji_screen.dart';
import '../../../hris_menu/domain/hris_menu_config.dart';
import '../../../hris_menu/domain/hris_menu_item.dart';
import '../../../hris_menu/presentation/screens/hris_menu_screen.dart';
import '../../../notifikasi/domain/app_notification.dart';
import '../../../notifikasi/data/notification_inbox_repository.dart';
import '../../../notifikasi/domain/notification_demo_data.dart';
import '../../../notifikasi/presentation/notification_routes.dart';
import '../../../notifikasi/presentation/screens/notifikasi_screen.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../shared/domain/role.dart';
import '../../domain/attendance_status.dart';
import '../../domain/published_announcement.dart';
import '../../domain/home_demo_data.dart';
import '../../domain/main_tab.dart';
import '../../domain/service_shortcut.dart';
import '../widgets/activity_section.dart';
import '../widgets/announcement_detail_sheet.dart';
import '../widgets/announcement_section.dart';
import '../widgets/clock_status_card.dart';
import '../widgets/create_announcement_sheet.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/home_top_header.dart';
import '../widgets/layanan_section.dart';
// import '../widgets/pending_request_card.dart';
import '../widgets/saldo_section.dart';

/// Halaman Beranda + shell navigasi utama.
///
/// Empat tab di bottom nav ([MainTab]): Home, HRIS (menu fitur kepegawaian),
/// Notifications, dan Profile. Request (Pengajuan) dan Attendance (Absensi)
/// bukan lagi tab — keduanya dibuka lewat push dari menu HRIS atau dari
/// kartu di Beranda.
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({
    super.key,
    required this.role,
    this.user,
    this.announcementRepository,
    this.leaveApprovalRepository,
    this.approvalsWaitingRepository,
  });

  final Role role;

  /// Pengguna yang sedang masuk, diteruskan ke header Beranda dan Profil.
  /// Null berarti belum ada sesi — keduanya jatuh ke data demo.
  final AuthUser? user;

  /// Boleh diisi manual di test; kalau tidak, diambil dari
  /// RepositoryProvider terdekat.
  final AnnouncementRepository? announcementRepository;

  /// Sumber data Leave Approvals. Dipegang di sini (satu instance) supaya
  /// badge di Beranda/menu HRIS dan halaman approval membaca data yang
  /// sama. Diisi manual di test; kalau tidak, dibuat dari [ApiClient].
  final LeaveApprovalRepository? leaveApprovalRepository;

  /// Ringkasan approval menunggu untuk IT/EST/Indent Vehicle/eProcurement
  /// (banner "Approvals waiting"). Diisi manual di test; kalau tidak, dibuat
  /// dari [ApiClient].
  final ApprovalsWaitingRepository? approvalsWaitingRepository;

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  MainTab _activeTab = MainTab.home;

  /// Filter awal tab Notifications. [_notificationFilterToken] dinaikkan
  /// tiap kali kita ingin tab itu melompat ke [_notificationFilter] (mis.
  /// dari banner "Approvals waiting"), karena tab-nya sendiri tidak dibuat
  /// ulang saat berpindah.
  NotificationFilter _notificationFilter = NotificationFilter.all;
  int _notificationFilterToken = 0;

  /// Daftar notifikasi dipegang di sini, bukan di NotifikasiScreen, supaya
  /// titik penanda di lonceng tetap benar setelah layar itu ditutup.
  List<AppNotification> _notifications = NotificationDemoData.initial();

  /// Request indent yang menunggu kendaraan (dari server), dipegang supaya
  /// sheet Assign bisa dibuka dengan data lengkapnya. Kosong untuk akun yang
  /// bukan admin driver — server yang menentukan.
  Map<String, IndentPendingItem> _pendingAssignments = {};

  /// id indent yang sedang dikirim ke server, supaya Assign tidak terkirim
  /// dua kali.
  final Set<String> _assigningIds = {};

  static const _assignNotificationPrefix = 'n-indent-assign-';

  /// Pengumuman dari server. Dipegang di sini, bukan di AnnouncementSection,
  /// supaya pengumuman yang baru diterbitkan langsung kelihatan begitu modal
  /// ditutup tanpa perlu mengambil ulang seluruh daftar.
  List<PublishedAnnouncement> _announcements = const [];
  bool _loadingAnnouncements = true;
  String? _announcementsError;

  /// Jadwal & absensi hari ini dari server. Null selama belum berhasil dimuat.
  AttendanceStatus? _todayAttendance;
  bool _loadingAttendance = true;
  String? _attendanceError;

  /// Repository approval Leave — satu instance untuk seluruh Beranda.
  late final LeaveApprovalRepository _leaveApprovalRepository =
      widget.leaveApprovalRepository ??
          LeaveApprovalRepository(apiClient: ApiClient());

  /// Jumlah pengajuan Leave yang menunggu keputusan HOD, dibaca dari
  /// [_leaveApprovalRepository] (BUKAN dihitung dari notifikasi).
  int _leaveApprovalCount = 0;

  /// Repository ringkasan approval IT/EST/Indent Vehicle/eProcurement.
  ///
  /// Fallback-nya SENGAJA lewat [RepositoryProvider] ([context.read]), BUKAN
  /// `ApprovalsWaitingRepository(apiClient: ApiClient())` — endpoint ini
  /// butuh token login. [ApiClient] baru yang dibuat langsung di sini tidak
  /// pernah di-setToken, jadi requestnya terkirim tanpa Authorization dan
  /// gagal diam-diam (balik ke [ApprovalsWaitingSummary.empty], semua
  /// kategori kelihatan 0 walau di server datanya ada).
  late final ApprovalsWaitingRepository _approvalsWaitingRepository =
      widget.approvalsWaitingRepository ??
          context.read<ApprovalsWaitingRepository>();

  /// Ringkasan approval menunggu dari [_approvalsWaitingRepository]. Leave
  /// TIDAK termasuk di sini — itu [_leaveApprovalCount] sendiri.
  ApprovalsWaitingSummary _approvalsWaiting = ApprovalsWaitingSummary.empty;
  bool _loadingApprovalsWaiting = true;

  Role get _role => widget.role;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _loadLeaveApprovalCount();
    _loadTodayAttendance();
    _loadApprovalsWaiting();
    _loadPendingAssignments();
    _loadServerNotifications();
  }

  /// Notifikasi IT Request, EST, Indent Vehicle, dan eProcurement dari
  /// server (`GET /api/portal/apps/notifications`). Yang lokal (assign,
  /// Leave) dipertahankan; yang dari server diganti seluruhnya.
  ///
  /// Lewat [context.read], bukan instance baru, karena endpoint ini butuh
  /// token login (lihat [_approvalsWaitingRepository]).
  Future<void> _loadServerNotifications() async {
    try {
      final page =
          await context.read<NotificationInboxRepository>().fetchLatest();
      if (!mounted) return;

      setState(() {
        _notifications = [
          for (final n in _notifications)
            if (!n.isFromServer) n,
          ...page.items,
        ];
      });
    } catch (e, stack) {
      AppLogger.error('Notifikasi server gagal dimuat', e, stack);
    }
  }

  Future<void> _refreshNotifications() => Future.wait([
        _loadServerNotifications(),
        _loadPendingAssignments(),
      ]);

  /// Perubahan baca/hapus pada notifikasi server diteruskan ke backend.
  /// Gagal cukup dicatat — tampilan lokal tidak dibatalkan, dan pemuatan
  /// berikutnya akan menyamakan lagi dengan server.
  Future<void> _syncServerNotifications(
    Map<String, AppNotification> before,
    List<AppNotification> updated,
  ) async {
    final repository = context.read<NotificationInboxRepository>();
    final remaining = {for (final n in updated) n.id};

    final newlyRead = [
      for (final n in updated)
        if (n.serverId != null && n.isRead && before[n.id]?.isRead == false)
          n.serverId!,
    ];
    final removed = [
      for (final n in before.values)
        if (n.serverId != null && !remaining.contains(n.id)) n.serverId!,
    ];

    try {
      // Lebih dari satu sekaligus = tombol "tandai semua dibaca".
      if (newlyRead.length > 1) {
        await repository.markAllRead();
      } else {
        for (final id in newlyRead) {
          await repository.markRead(id);
        }
      }
      for (final id in removed) {
        await repository.delete(id);
      }
    } catch (e, stack) {
      AppLogger.error('Status notifikasi gagal dikirim ke server', e, stack);
    }
  }

  /// Notifikasi server di-tap: buka halaman modulnya, lalu muat ulang
  /// karena status request bisa berubah di sana.
  Future<void> _openNotification(AppNotification notification) async {
    final link = notification.link;
    if (link == null) return;
    final screen = NotificationRoutes.screenFor(link);
    if (screen == null) return;

    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    _refreshNotifications();
    _loadApprovalsWaiting();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _loadingAnnouncements = true;
      _announcementsError = null;
    });

    try {
      final published = await (widget.announcementRepository ??
              context.read<AnnouncementRepository>())
          .fetchAnnouncements();

      if (!mounted) return;
      setState(() {
        _announcements = published;
        _loadingAnnouncements = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _announcementsError = e.message;
        _loadingAnnouncements = false;
      });
    }
  }

  Future<void> _loadTodayAttendance() async {
    setState(() {
      _loadingAttendance = true;
      _attendanceError = null;
    });

    try {
      final status = await context.read<AbsensiRepository>().fetchToday();

      if (!mounted) return;
      setState(() {
        _todayAttendance = status;
        _loadingAttendance = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _attendanceError = e.message;
        _loadingAttendance = false;
      });
    }
  }

  void _openTab(MainTab tab) {
    setState(() => _activeTab = tab);
    // Data assign bisa berubah sejak Beranda dibuka (request baru lolos HOD).
    if (tab == MainTab.notifications) _refreshNotifications();
  }

  void _openPayslip() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PayslipScreen()),
    );
  }

  /// Leave Request / Pengajuan — dibuka lewat push dari menu HRIS atau
  /// "See all" di saldo Beranda.
  void _openLeaveRequest() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PengajuanScreen(role: _role)),
    );
  }

  /// Overtime Request — dibuka lewat push dari menu HRIS.
  void _openOvertimeRequest() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OvertimeRequestScreen()),
    );
  }

  /// Log Absensi — dibuka lewat push dari menu HRIS atau kartu jam kerja.
  void _openAttendance() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AbsensiScreen()),
    );
  }

  void _openKelolaTim() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KelolaTimScreen()),
    );
  }

  void _openDepartmentAttendance() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DepartmentAttendanceScreen()),
    );
  }

  Future<void> _openCreateAnnouncement() async {
    final created = await showModalBottomSheet<PublishedAnnouncement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateAnnouncementSheet(),
    );

    if (created == null || !mounted) return;
    setState(() => _announcements = [created, ..._announcements]);
  }

  Future<void> _loadLeaveApprovalCount() async {
    // Belum ada endpoint Leave Approvals: jumlahnya tetap 0 supaya banner
    // dan badge tidak menampilkan data dummy (FeatureFlags.leaveApproval).
    if (!FeatureFlags.leaveApproval) return;

    try {
      final count = await _leaveApprovalRepository.fetchPendingCount();
      if (!mounted) return;
      setState(() => _leaveApprovalCount = count);
    } catch (e, stack) {
      AppLogger.error('Jumlah leave approval gagal dimuat', e, stack);
    }
  }

  /// Halaman Leave Approvals sungguhan (khusus HRIS/Leave, terpisah dari
  /// tab Notifications). Dipakai menu HRIS dan tag "Leave" di banner.
  void _openLeaveApproval() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeaveApprovalScreen(
          repository: _leaveApprovalRepository,
          onPendingCountChanged: (count) {
            if (mounted) setState(() => _leaveApprovalCount = count);
          },
          onDecided: _syncLeaveNotification,
        ),
      ),
    );
  }

  /// Keputusan diambil di halaman Leave Approvals → notifikasi Leave yang
  /// sama ikut turun dari "Action" supaya tidak tertinggal menggantung.
  void _syncLeaveNotification(LeaveApprovalRequest request) {
    final decision = request.status == LeaveApprovalStatus.approved
        ? NotificationDecision.approved
        : NotificationDecision.rejected;

    setState(() {
      _notifications = [
        for (final n in _notifications)
          n.id == request.notificationId
              ? n.copyWith(decision: decision, isRead: true)
              : n,
      ];
    });
  }

  /// Kebalikannya: keputusan diambil langsung dari tab Notifications →
  /// diteruskan ke repository approval, supaya badge dan halaman Leave
  /// Approvals tidak berbeda dengan yang tampil di sana.
  void _onNotificationsChanged(List<AppNotification> updated) {
    final before = {for (final n in _notifications) n.id: n};
    setState(() => _notifications = updated);
    _syncServerNotifications(before, updated);

    for (final n in updated) {
      final requestId = LeaveApprovalRequest.idFromNotificationId(n.id);
      final decision = n.decision;
      if (requestId == null || decision == null) continue;
      // Sudah diputuskan sebelumnya (dan sudah tersinkron) — lewati.
      if (before[n.id]?.decision != null) continue;

      _pushLeaveDecision(requestId, decision);
    }
  }

  Future<void> _pushLeaveDecision(
    String requestId,
    NotificationDecision decision,
  ) async {
    try {
      await _leaveApprovalRepository.decide(
        requestId,
        decision: decision == NotificationDecision.approved
            ? LeaveApprovalDecision.approve
            : LeaveApprovalDecision.reject,
      );
    } catch (e, stack) {
      AppLogger.error('Keputusan dari notifikasi gagal disinkronkan', e, stack);
    }
    await _loadLeaveApprovalCount();
  }

  /// Memuat request indent yang menunggu kendaraan
  /// (`GET /api/indent/admin/list`) dan menjadikannya notifikasi bertipe
  /// assign di tab Action. Untuk akun yang bukan admin driver server
  /// membalas tanpa data, jadi tidak ada notifikasi yang ditambahkan.
  ///
  /// Gagal memuat tidak mengganggu notifikasi lain: cukup dicatat.
  Future<void> _loadPendingAssignments() async {
    try {
      final items =
          await context.read<IndentVehicleRepository>().fetchPendingAssignments();
      if (!mounted) return;

      setState(() {
        final previous = {
          for (final n in _notifications)
            if (n.actionType == NotificationActionType.assign) n.id: n,
        };

        _pendingAssignments = {for (final item in items) item.id: item};
        _notifications = [
          for (final item in items)
            _assignNotification(
              item,
              previous['$_assignNotificationPrefix${item.id}'],
            ),
          for (final n in _notifications)
            if (n.actionType != NotificationActionType.assign) n,
        ];
      });
    } catch (e, stack) {
      AppLogger.error('Daftar assign gagal dimuat', e, stack);
    }
  }

  /// Notifikasi assign untuk satu request. Waktu dan status baca dari
  /// pemuatan sebelumnya ([previous]) dipertahankan supaya tidak "baru lagi"
  /// setiap kali daftar dimuat ulang — server belum mengirim waktu request.
  AppNotification _assignNotification(
    IndentPendingItem item,
    AppNotification? previous,
  ) {
    return AppNotification(
      id: '$_assignNotificationPrefix${item.id}',
      category: NotificationCategory.indentVehicle,
      title: 'Assign vehicle for ${item.name}',
      body: '${item.destination} · ${item.date} · ${item.timeRange} · '
          '${item.withDriver ? 'With driver' : 'No driver'}',
      createdAt: previous?.createdAt ?? DateTime.now(),
      isRead: previous?.isRead ?? false,
      requiresDecision: true,
      actionType: NotificationActionType.assign,
      refId: item.id,
    );
  }

  /// Tombol "Assign" di notifikasi: buka sheet pilih plat & driver, kirim ke
  /// server, lalu tandai notifikasinya selesai. Gagal -> notifikasi tetap
  /// menunggu supaya admin bisa mencoba lagi.
  Future<void> _assignFromNotification(AppNotification notification) async {
    final item = _pendingAssignments[notification.refId];
    if (item == null || _assigningIds.contains(item.id)) return;

    final result = await showModalBottomSheet<IndentAssignResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IndentAssignSheet(item: item),
    );
    if (result == null || !mounted) return;

    _assigningIds.add(item.id);
    try {
      await context.read<IndentVehicleRepository>().assignByAdmin(
            id: item.id,
            plateNumber: result.plateNumber,
            driverId: result.driverId,
            driverName: result.driver,
          );
      if (!mounted) return;

      setState(() {
        _pendingAssignments = Map.of(_pendingAssignments)..remove(item.id);
        _notifications = [
          for (final n in _notifications)
            n.id == notification.id
                ? n.copyWith(
                    decision: NotificationDecision.approved,
                    isRead: true,
                  )
                : n,
        ];
      });

      final driverText = result.driver == null ? '' : ' · ${result.driver}';
      _showSnack(
        'Vehicle ${result.plateNumber}$driverText '
        'assigned to ${item.name}',
      );
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e, stack) {
      AppLogger.error('Assign dari notifikasi gagal tak terduga', e, stack);
      _showSnack('An unexpected error occurred. Please try again.');
    } finally {
      _assigningIds.remove(item.id);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadApprovalsWaiting() async {
    try {
      final summary = await _approvalsWaitingRepository.fetchSummary();
      if (!mounted) return;
      setState(() {
        _approvalsWaiting = summary;
        _loadingApprovalsWaiting = false;
      });
    } catch (e, stack) {
      AppLogger.error('Ringkasan approvals waiting gagal dimuat', e, stack);
      if (!mounted) return;
      setState(() => _loadingApprovalsWaiting = false);
    }
  }

  /// Dipanggil saat tab Home ditarik ke bawah (pull-to-refresh). Keempat
  /// permintaan independen, jadi dijalankan bersamaan alih-alih berurutan.
  /// Setiap _load... sudah menangani error-nya sendiri, jadi di sini cukup
  /// ditunggu semuanya selesai.
  Future<void> _refreshHome() => Future.wait([
        _loadAnnouncements(),
        _loadTodayAttendance(),
        _loadLeaveApprovalCount(),
        _loadApprovalsWaiting(),
        _loadPendingAssignments(),
        _loadServerNotifications(),
      ]);

  int get _itApprovalCount => _approvalsWaiting.itRequest;
  int get _estApprovalCount => _approvalsWaiting.estWorkOrder;
  int get _indentVehicleApprovalCount => _approvalsWaiting.indentVehicle;
  int get _eprocurementApprovalCount => _approvalsWaiting.eprocurement;

  /// Pindah ke tab Notifications dengan filter "Action" (yang menunggu
  /// keputusan — semua modul). Dipakai badan banner "Approvals waiting" di
  /// Beranda. Approval Leave punya halaman sendiri: [_openLeaveApproval].
  void _openApprovalNotifications() {
    setState(() {
      _notificationFilter = NotificationFilter.action;
      _notificationFilterToken++;
      _activeTab = MainTab.notifications;
    });
    _loadPendingAssignments();
  }

  void _openItApproval() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ItRequestScreen(initialTab: ItRequestTab.approve),
      ),
    );
  }

  /// EST: buka EstRequestScreen langsung di tab Approve HOD (tab 1), pola
  /// yang sama dengan IT di atas. `isHod` memakai default layar (true);
  /// pemetaan role HOD yang asli masih SEMENTARA di sana.
  void _openEstApproval() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EstRequestScreen(initialTabIndex: 1),
      ),
    );
  }

  /// Indent Vehicle: buka halamannya langsung di tab Supervisor Approval.
  /// Banner Approvals waiting hanya tampil untuk HOD, yang memang berhak atas
  /// tab itu (kalau tidak, layar otomatis jatuh ke List of User Requests).
  void _openIndentVehicleApproval() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const IndentVehicleScreen(initialTab: IndentTab.supervisorApproval),
      ),
    );
  }

  /// eProcurement: buka Procurement Monitoring dengan chip "HOD"
  /// (`pending_hod`) sudah aktif, bukan ke tab Notifications.
  void _openEprocurementApproval() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProcurementPage(
          initialStatusCode: PrStatusCode.pendingHod.code,
        ),
      ),
    );
  }

  /// Menu utama "Online Apps" — dipush sebagai halaman baru, bukan tab,
  /// jadi bottom nav Beranda tidak ikut tampil di sana.
  void _openOnlineApps() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnlineAppsScreen()),
    );
  }

  void _openRecord() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RecordScreen()),
    );
  }

  void _openData() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DataScreen()),
    );
  }

  List<ServiceShortcut> _buildServices() => [
        ServiceShortcut(
          icon: Icons.description_outlined,
          label: 'Record',
          subtitle: 'Documents & Archive',
          color: AppColors.primaryMid,
          background: AppColors.primaryLight,
          featured: true,
          onTap: _openRecord,
        ),
        ServiceShortcut(
          icon: Icons.storage_outlined,
          label: 'Data',
          subtitle: 'Database & Files',
          color: AppColors.accent,
          background: AppColors.accentBg,
          onTap: _openData,
        ),
        ServiceShortcut(
          icon: Icons.apps_outlined,
          label: 'Online Apps',
          subtitle: 'Web Services',
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: _openOnlineApps,
        ),
        // Pengganti kartu Dashboard: pindah ke tab HRIS (bukan push halaman
        // baru), supaya hanya ada satu instance menu HRIS.
        ServiceShortcut(
          icon: Icons.grid_view_outlined,
          label: 'HRIS',
          subtitle: 'Employee Services',
          color: AppColors.violet,
          background: AppColors.violetBg,
          onTap: () => _openTab(MainTab.hris),
        ),
      ];

  /// Item menu HRIS. Daftar, aturan visibilitas, dan status "siap/belum"
  /// tiap item ada di [HrisMenuConfig]; di sini hanya menyambungkan
  /// navigasinya.
  List<HrisMenuItem> _buildHrisMenu() => HrisMenuConfig.items(
        onAttendance: _openAttendance,
        onLeaveRequest: _openLeaveRequest,
        onOvertimeRequest: _openOvertimeRequest,
        onEmployeeInfo: () => _openTab(MainTab.profile),
        onPayslip: _openPayslip,
        onManageTeam: _openKelolaTim,
        // Item ini "Leave Approvals", jadi badge-nya cuma approval Leave —
        // bukan jumlah semua modul.
        onDepartmentAttendance: _openDepartmentAttendance,
        onApprovals: _openLeaveApproval,
        approvalCount: _leaveApprovalCount,
      );

  @override
  Widget build(BuildContext context) {
    // Home, HRIS, dan Profile berheader hijau yang naik sampai ke balik
    // status bar, jadi ikonnya harus terang. Notifications berheader putih,
    // jadi ikonnya harus gelap supaya tetap kebaca.
    final hasDarkHeader = _activeTab != MainTab.notifications;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hasDarkHeader
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      // Warna dasar ikut tab Home (dipakai saat transisi); tiap tab lain
      // membungkus kontennya sendiri dengan warna latarnya masing-masing.
      backgroundColor: AppColors.bg,
      // Urutan children HARUS sama dengan urutan nilai [MainTab].
      body: IndexedStack(
        index: _activeTab.index,
        children: [
          _buildHomeTab(),
          HrisMenuScreen(
            items: _buildHrisMenu(),
            menuContext: HrisMenuContext(role: _role, user: widget.user),
          ),
          NotifikasiScreen(
            notifications: _notifications,
            onChanged: _onNotificationsChanged,
            onAssign: _assignFromNotification,
            onOpen: _openNotification,
            onRefresh: _refreshNotifications,
            initialFilter: _notificationFilter,
            filterRequestToken: _notificationFilterToken,
            showBack: false,
          ),
          ProfilScreen(role: _role, user: widget.user),
        ],
      ),
      bottomNavigationBar: HomeBottomNav(
        activeTab: _activeTab,
        unreadCount: _unreadCount,
        onChanged: _openTab,
      ),
    );
  }

  Widget _buildHomeTab() {
    return ColoredBox(
      color: AppColors.bg,
      // top: false — HomeTopHeader yang mengurus jarak aman atas sendiri
      // supaya warna hijaunya tidak terpotong garis putih di atas.
      child: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refreshHome,
          color: AppColors.primary,
          child: SingleChildScrollView(
            // Tanpa ini, tarikan ke bawah tidak terdeteksi saat kontennya
            // lebih pendek dari tinggi layar (mis. layar besar atau role
            // dengan sedikit menu) karena tidak ada overscroll untuk ditarik.
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeTopHeader(
                  role: _role,
                  user: widget.user,
                ),
                ClockStatusCard(
                  status: _todayAttendance,
                  isLoading: _loadingAttendance,
                  errorMessage: _attendanceError,
                  date: DateTime.now(),
                  onActionTap: _openAttendance,
                  onRetry: _loadTodayAttendance,
                ),
                // Shortcut approval hanya untuk HOD (role `hod`). Selama belum
                // ada sesi (mis. saat pratinjau), jatuh ke role demo.
                if (widget.user?.isHod ?? (_role == Role.hod))
                ApprovalSummaryBanner(
                  isLoading: _loadingApprovalsWaiting,
                  leaveCount: _leaveApprovalCount,
                  itCount: _itApprovalCount,
                  estCount: _estApprovalCount,
                  indentVehicleCount: _indentVehicleApprovalCount,
                  eprocurementCount: _eprocurementApprovalCount,
                  onTapAll: _openApprovalNotifications,
                  onTapLeave: _openLeaveApproval,
                  onTapIt: _openItApproval,
                  onTapEst: _openEstApproval,
                  onTapIndentVehicle: _openIndentVehicleApproval,
                  onTapEprocurement: _openEprocurementApproval,
                ),
                //PendingRequestCard(
                //  count: 2,
                //  description: 'Overtime · Business Trip',
                //  onTap: () => _openTab(_pengajuanTab),
                //),
                LayananSection(services: _buildServices()),
                SaldoSection(
                  balances: HomeDemoData.quotaBalancesFor(_role),
                  onSeeAll: _openLeaveRequest,
                ),
                AnnouncementSection(
                  announcements: _announcements,
                  isLoading: _loadingAnnouncements,
                  errorMessage: _announcementsError,
                  onRetry: _loadAnnouncements,
                  onTapAnnouncement: (announcement) =>
                      AnnouncementDetailSheet.show(context, announcement),
                  // Izin hr-announcement-post: role hrga dan admin. Selama
                  // belum ada sesi (mis. saat pratinjau), jatuh ke role demo.
                  canCreate: widget.user?.canPublishAnnouncement ??
                      (_role == Role.hrPublisher),
                  onCreateTap: _openCreateAnnouncement,
                ),
                // Redup + "Soon" sampai API aktivitas ada (data masih demo).
                // Aktifkan lewat FeatureFlags.recentActivity.
                ActivitySection(
                  activities: HomeDemoData.recentActivities(),
                  enabled: FeatureFlags.recentActivity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
