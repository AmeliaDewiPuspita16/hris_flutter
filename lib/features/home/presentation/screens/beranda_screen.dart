import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/announcement_repository.dart';
import '../../../absensi/presentation/screens/absensi_screen.dart';
import '../../../kelola_tim/presentation/screens/kelola_tim_screen.dart';
import '../../../menu_portal/onlineapps/presentation/screens/online_apps_screen.dart';
import '../../../menu_portal/onlineapps/work_order/est_request/domain/est_request_demo_data.dart';
import '../../../menu_portal/onlineapps/work_order/est_request/domain/est_request_status.dart';
import '../../../menu_portal/onlineapps/work_order/it_request/domain/approve_request_demo_data.dart';
import '../../../menu_portal/onlineapps/work_order/it_request/presentation/screens/it_request_screen.dart';
import '../../../menu_portal/record/presentation/screens/record_screen.dart';
import '../../../notifikasi/domain/notification_filter.dart';
import '../widgets/approval_summary_banner.dart';
import '../../../pengajuan/presentation/screens/pengajuan_screen.dart';
import '../../../profil/presentation/screens/profil_screen.dart';
import '../../../gaji/presentation/gaji_screen.dart';
import '../../../hris_menu/domain/hris_menu_config.dart';
import '../../../hris_menu/domain/hris_menu_item.dart';
import '../../../hris_menu/presentation/screens/hris_menu_screen.dart';
import '../../../notifikasi/domain/app_notification.dart';
import '../../../notifikasi/domain/notification_category.dart';
import '../../../notifikasi/domain/notification_demo_data.dart';
import '../../../notifikasi/presentation/screens/notifikasi_screen.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../shared/domain/role.dart';
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
import '../widgets/team_banner.dart';

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
  });

  final Role role;

  /// Pengguna yang sedang masuk, diteruskan ke header Beranda dan Profil.
  /// Null berarti belum ada sesi — keduanya jatuh ke data demo.
  final AuthUser? user;

  /// Boleh diisi manual di test; kalau tidak, diambil dari
  /// RepositoryProvider terdekat.
  final AnnouncementRepository? announcementRepository;

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

  /// Pengumuman dari server. Dipegang di sini, bukan di AnnouncementSection,
  /// supaya pengumuman yang baru diterbitkan langsung kelihatan begitu modal
  /// ditutup tanpa perlu mengambil ulang seluruh daftar.
  List<PublishedAnnouncement> _announcements = const [];
  bool _loadingAnnouncements = true;
  String? _announcementsError;

  Role get _role => widget.role;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
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

  void _openTab(MainTab tab) => setState(() => _activeTab = tab);

  /// Lonceng di header Beranda = jalan pintas ke tab Notifications.
  void _openNotifications() {
    setState(() {
      _notificationFilter = NotificationFilter.all;
      _notificationFilterToken++;
      _activeTab = MainTab.notifications;
    });
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

  /// SEMENTARA: belum ada halaman approval Leave sungguhan (beda dari IT
  /// yang sudah punya tab Approve Request) — dihitung dari notifikasi
  /// kategori Leave yang masih butuh keputusan, supaya angkanya tetap
  /// sinkron dengan yang muncul di tab "Action" Notifications, sampai ada
  /// API approval Leave sungguhan.
  int get _leaveApprovalCount => _notifications
      .where((n) => n.category == NotificationCategory.leave && n.needsAction)
      .length;

  int get _itApprovalCount => ApproveRequestDemoData.items().length;

  /// Dianggap "butuh approval HOD" kalau statusnya [EstRequestStatus.
  /// waitApprovalHosd] — belum ada tab Approve Request sungguhan untuk EST
  /// seperti IT, jadi ini juga masih perkiraan dari data demo.
  int get _estApprovalCount => EstRequestDemoData.items()
      .where((r) => r.status == EstRequestStatus.waitApprovalHod)
      .length;

  /// Pindah ke tab Notifications dengan filter "Action" (yang menunggu
  /// keputusan). Dipakai banner Beranda dan item "Approvals" di menu HRIS.
  void _openApprovalNotifications() {
    setState(() {
      _notificationFilter = NotificationFilter.action;
      _notificationFilterToken++;
      _activeTab = MainTab.notifications;
    });
  }

  void _openItApproval() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ItRequestScreen(initialTabIndex: 1),
      ),
    );
  }

  /// SEMENTARA: EST belum punya tab Approve Request sendiri seperti IT
  /// (menu EST Request baru sisi requester) — untuk sekarang jatuh ke
  /// Notifications juga, sama seperti Leave.
  void _openEstApproval() => _openApprovalNotifications();

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
          onTap: () {},
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
        onEmployeeInfo: () => _openTab(MainTab.profile),
        onPayslip: _openPayslip,
        onManageTeam: _openKelolaTim,
        onApprovals: _openApprovalNotifications,
        approvalCount:
            _leaveApprovalCount + _itApprovalCount + _estApprovalCount,
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
            onChanged: (updated) => setState(() => _notifications = updated),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeTopHeader(
                role: _role,
                user: widget.user,
                unreadCount: _unreadCount,
                onNotificationTap: _openNotifications,
              ),
              ClockStatusCard(
                status: HomeDemoData.todayAttendance,
                date: DateTime.now(),
                onActionTap: _openAttendance,
              ),
              // SEMENTARA: tanpa gerbang role dulu (lihat catatan di
              // ApprovalSummaryBanner) — dulu ini TeamBanner di bawah Main
              // Menu, dipindah ke sini (pola awal HRIS: di bawah header, di
              // atas Main Menu) sekaligus digabung 3 modul.
              ApprovalSummaryBanner(
                leaveCount: _leaveApprovalCount,
                itCount: _itApprovalCount,
                estCount: _estApprovalCount,
                onTapAll: _openApprovalNotifications,
                onTapLeave: _openApprovalNotifications,
                onTapIt: _openItApproval,
                onTapEst: _openEstApproval,
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
              if (_role == Role.admin)
                // SEMENTARA
                TeamBanner(
                  icon: Icons.groups_outlined,
                  iconColor: AppColors.primaryMid,
                  iconBackground: AppColors.primaryLight,
                  title: 'Manage Department Team',
                  subtitle: '18 employees · Update leave balance',
                  onTap: _openKelolaTim,
                ),
              const ActivitySection(
                activities: HomeDemoData.recentActivities,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
