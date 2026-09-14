import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../absensi/presentation/absensi_screen.dart';
import '../../../kelola_tim/presentation/screens/kelola_tim_screen.dart';
import '../../../pengajuan/presentation/pengajuan_screen.dart';
import '../../../profil/presentation/screens/profil_screen.dart';
import '../../../gaji/presentation/gaji_screen.dart';
import '../../../shared/domain/role.dart';
import '../../domain/home_demo_data.dart';
import '../../domain/service_shortcut.dart';
import '../widgets/activity_section.dart';
import '../widgets/clock_status_card.dart';
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
  const BerandaScreen({super.key, required this.role});

  final Role role;

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

  Role get _role => widget.role;

  void _openTab(int index) => setState(() => _activeTab = index);

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

  void _openApprovalTab() => setState(() => _activeTab = _approvalTabIndex);

  List<ServiceShortcut> _buildServices() => [
        ServiceShortcut(
          icon: Icons.event_available_outlined,
          label: 'Leave',
          color: AppColors.primaryMid,
          background: AppColors.primaryLight,
          onTap: () => _openTab(_pengajuanTab),
        ),
        ServiceShortcut(
          icon: Icons.receipt_long_outlined,
          label: 'Payslip',
          color: AppColors.accent,
          background: AppColors.accentBg,
          onTap: _openPayslip,
        ),
        ServiceShortcut(
          icon: Icons.fingerprint,
          label: 'Attendance',
          color: AppColors.present,
          background: AppColors.presentBg,
          onTap: () => _openTab(_absensiTab),
        ),
        ServiceShortcut(
          icon: Icons.calendar_month_outlined,
          label: 'Schedule',
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: () {},
        ),
        ServiceShortcut(
          icon: Icons.badge_outlined,
          label: 'Profile',
          color: AppColors.violet,
          background: AppColors.violetBg,
          onTap: () => _openTab(_profilTab),
        ),
        if (_role == Role.hod)
          ServiceShortcut(
            icon: Icons.task_alt,
            label: 'Approvals',
            color: AppColors.primary,
            background: AppColors.primaryLight,
            onTap: _openApprovalTab,
          ),
        if (_role == Role.admin)
          // SEMENTARA
          ServiceShortcut(
            icon: Icons.groups_outlined,
            label: 'Manage Team',
            color: AppColors.primaryMid,
            background: AppColors.primaryLight,
            onTap: _openKelolaTim,
          ),
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
    // Ikon status bar terang cuma dibutuhkan waktu tab Home aktif, karena
    // cuma header Home yang gradiennya naik sampai ke balik status bar.
    // Tab lain (Request/Attendance/Profile) latar depannya putih/terang,
    // jadi ikon status bar harus gelap supaya kebaca.
    final isHomeTab = _displayedTab == _homeTab;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isHomeTab
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
      backgroundColor: AppColors.bgWarm,
      body: IndexedStack(
        index: _displayedTab,
        children: [
          _buildHomeTab(),
          PengajuanScreen(role: _role),
          const AbsensiScreen(),
          ProfilScreen(role: _role),
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
      color: AppColors.bgWarm,
      // top: false — HomeTopHeader yang mengurus jarak aman atas sendiri
      // supaya warna hijaunya tidak terpotong garis putih di atas.
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeTopHeader(role: _role),
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
              SaldoSection(
                balances: HomeDemoData.quotaBalancesFor(_role),
                onSeeAll: () => _openTab(_pengajuanTab),
              ),
              LayananSection(services: _buildServices()),
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
