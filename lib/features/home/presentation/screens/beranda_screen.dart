import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../absensi/presentation/absensi_screen.dart';
import '../../../kelola_tim/presentation/screens/kelola_tim_screen.dart';
import '../../../pengajuan/presentation/pengajuan_screen.dart';
import '../../../profil/presentation/screens/profil_screen.dart';
import '../../../gaji/presentation/gaji_screen.dart';
import '../../../notifikasi/domain/app_notification.dart';
import '../../../notifikasi/domain/notification_demo_data.dart';
import '../../../notifikasi/presentation/screens/notifikasi_screen.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../shared/domain/role.dart';
import '../../domain/announcement.dart';
import '../../domain/home_demo_data.dart';
import '../../domain/service_shortcut.dart';
import '../widgets/activity_section.dart';
import '../widgets/announcement_section.dart';
import '../widgets/clock_status_card.dart';
import '../widgets/create_announcement_sheet.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/home_top_header.dart';
import '../widgets/layanan_section.dart';
import '../widgets/pending_request_card.dart';
import '../widgets/saldo_section.dart';
import '../widgets/team_banner.dart';

/// Halaman Beranda + shell navigasi utama.
///
/// Home, Request (Pengajuan), Attendance (Absensi), dan Profile adalah
/// 4 tab UTAMA yang sejajar di bottom nav
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key, required this.role, this.user});

  final Role role;

  /// Pengguna yang sedang masuk, diteruskan ke header Beranda dan Profil.
  /// Null berarti belum ada sesi — keduanya jatuh ke data demo.
  final AuthUser? user;

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

  /// Sama seperti notifikasi — dipegang di sini supaya pengumuman baru dari
  /// HR Publisher langsung kelihatan begitu modal ditutup.
  List<Announcement> _announcements = HomeDemoData.initialAnnouncements();

  Role get _role => widget.role;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

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

  void _openPayslip() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PayslipScreen()),
    );
  }

  void _openKelolaTim() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KelolaTimScreen()),
    );
  }

  Future<void> _openCreateAnnouncement() async {
    final created = await showModalBottomSheet<Announcement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateAnnouncementSheet(),
    );

    if (created == null || !mounted) return;
    setState(() => _announcements = [created, ..._announcements]);
  }

  void _openApprovalTab() => setState(() => _activeTab = _approvalTabIndex);

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
          onTap: () => _openTab(_absensiTab),
        ),
        ServiceShortcut(
          icon: Icons.storage_outlined,
          label: 'Data',
          color: AppColors.accent,
          background: AppColors.accentBg,
          onTap: () => _openTab(_absensiTab),
        ),
        ServiceShortcut(
          icon: Icons.apps_outlined,
          label: 'Online Apps',
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: () => _openTab(_absensiTab),
        ),
        ServiceShortcut(
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
          color: AppColors.violet,
          background: AppColors.violetBg,
          onTap: () => _openTab(_absensiTab),
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
              PendingRequestCard(
                count: 2,
                description: 'Overtime · Business Trip',
                onTap: () => _openTab(_pengajuanTab),
              ),
              LayananSection(services: _buildServices()),
              SaldoSection(
                balances: HomeDemoData.quotaBalancesFor(_role),
                onSeeAll: () => _openTab(_pengajuanTab),
              ),
              AnnouncementSection(
                announcements: _announcements,
                // Izin hr-announcement-post: role hrga dan admin. Selama
                // belum ada sesi (mis. saat pratinjau), jatuh ke role demo.
                canCreate: widget.user?.canPublishAnnouncement ??
                    (_role == Role.hrPublisher),
                onCreateTap: _openCreateAnnouncement,
              ),
              if (_role == Role.hod)
                TeamBanner(
                  icon: Icons.fact_check_outlined,
                  iconColor: AppColors.primary,
                  iconBackground: AppColors.primaryLight,
                  title: '3 Requests Need Review',
                  subtitle: 'Team approvals are waiting for you',
                  onTap: _openApprovalTab,
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
