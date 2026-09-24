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
// import '../../../gaji/presentation/gaji_screen.dart';
import '../../../notifikasi/domain/app_notification.dart';
import '../../../notifikasi/domain/notification_category.dart';
import '../../../notifikasi/domain/notification_demo_data.dart';
import '../../../notifikasi/presentation/screens/notifikasi_screen.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../shared/domain/role.dart';
import '../../domain/published_announcement.dart';
import '../../domain/home_demo_data.dart';
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
/// Home, Request (Pengajuan), Attendance (Absensi), dan Profile adalah
/// 4 tab UTAMA yang sejajar di bottom nav
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
  static const _homeTab = 0;
  static const _pengajuanTab = 1;
  static const _absensiTab = 2;
  static const _profilTab = 3;

  /// Indeks tab navigasi bawah. Tab 4 dipakai role HOD untuk Persetujuan.
  ///
  /// SEMENTARA: role HOD belum punya halaman Persetujuan sungguhan, jadi
  /// tab ini cuma menyalakan highlight di bottom nav tanpa konten baru.
  static const _approvalTabIndex = 4;

  int _activeTab = _homeTab;

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

  void _openTab(int index) => setState(() => _activeTab = index);

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotifikasiScreen(
          notifications: _notifications,
          onChanged: (updated) => setState(() => _notifications = updated),
        ),
      ),
    );
  }

  // void _openPayslip() {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(builder: (_) => const PayslipScreen()),
  //   );
  // }

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

  void _openApprovalNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotifikasiScreen(
          notifications: _notifications,
          onChanged: (updated) => setState(() => _notifications = updated),
          initialFilter: NotificationFilter.action,
        ),
      ),
    );
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
        // ServiceShortcut(
        //   icon: Icons.event_available_outlined,
        //   label: 'Leave',
        //   color: AppColors.primaryMid,
        //   background: AppColors.primaryLight,
        //   onTap: () => _openTab(_pengajuanTab),
        // ),
        // ServiceShortcut(
        //   icon: Icons.receipt_long_outlined,
        //   label: 'Payslip',
        //   color: AppColors.accent,
        //   background: AppColors.accentBg,
        //   onTap: _openPayslip,
        // ),
        // ServiceShortcut(
        //   icon: Icons.fingerprint,
        //   label: 'Attendance',
        //   color: AppColors.present,
        //   background: AppColors.presentBg,
        //   onTap: () => _openTab(_absensiTab),
        // ),
        // ServiceShortcut(
        //   icon: Icons.calendar_month_outlined,
        //   label: 'Schedule',
        //   color: AppColors.teal,
        //   background: AppColors.tealBg,
        //   onTap: () {},
        // ),
        // ServiceShortcut(
        //   icon: Icons.badge_outlined,
        //   label: 'Profile',
        //   color: AppColors.violet,
        //   background: AppColors.violetBg,
        //   onTap: () => _openTab(_profilTab),
        // ),
        ServiceShortcut(
          icon: Icons.description_outlined,
          label: 'Record',
          color: AppColors.primaryMid,
          background: AppColors.primaryLight,
          onTap: _openRecord,
        ),
        ServiceShortcut(
          icon: Icons.storage_outlined,
          label: 'Data',
          color: AppColors.accent,
          background: AppColors.accentBg,
          onTap: () {},
        ),
        ServiceShortcut(
          icon: Icons.apps_outlined,
          label: 'Online Apps',
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: _openOnlineApps,
        ),
        ServiceShortcut(
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
          color: AppColors.violet,
          background: AppColors.violetBg,
          onTap: () {},
        ),
        // if (_role == Role.hod)
        //   ServiceShortcut(
        //     icon: Icons.task_alt,
        //     label: 'Approvals',
        //     color: AppColors.primary,
        //     background: AppColors.primaryLight,
        //     onTap: _openApprovalTab,
        //   ),
        // if (_role == Role.admin)
        //   // SEMENTARA
        //   ServiceShortcut(
        //     icon: Icons.groups_outlined,
        //     label: 'Manage Team',
        //     color: AppColors.primaryMid,
        //     background: AppColors.primaryLight,
        //     onTap: _openKelolaTim,
        //   ),
      ];

  /// Index 4 (Approvals/Manage Team) masih kasus khusus: Manage Team
  /// (admin) tetap push halaman terpisah, Approvals (HOD) masih placeholder.
  void _handleTabChange(int index) {
    switch (index) {
      // SEMENTARA
      case _approvalTabIndex when _role == Role.admin:
        _openKelolaTim();
      default:
        setState(() => _activeTab = index);
    }
  }

  /// Index tab yang benar-benar ditampilkan di [IndexedStack]. Approvals
  /// (index 4, HOD) masih placeholder dan jatuh balik ke tampilan Home.
  int get _displayedTab => _activeTab > _profilTab ? _homeTab : _activeTab;

  @override
  Widget build(BuildContext context) {
    // Home dan Profile sama-sama punya header hijau yang naik sampai ke balik
    // status bar, jadi ikonnya harus terang. Request dan Attendance berlatar
    // terang di area itu, jadi ikonnya harus gelap supaya tetap kebaca.
    final hasDarkHeader =
        _displayedTab == _homeTab || _displayedTab == _profilTab;

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
      body: IndexedStack(
        index: _displayedTab,
        children: [
          _buildHomeTab(),
          PengajuanScreen(role: _role),
          const AbsensiScreen(),
          ProfilScreen(role: _role, user: widget.user),
        ],
      ),
      bottomNavigationBar: HomeBottomNav(
        role: _role,
        activeIndex: _activeTab,
        onChanged: _handleTabChange,
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
                onActionTap: () => _openTab(_absensiTab),
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
                onSeeAll: () => _openTab(_pengajuanTab),
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
