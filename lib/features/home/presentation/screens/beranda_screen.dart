import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../absensi/presentation/absensi_screen.dart';
import '../../../kelola_tim/presentation/screens/kelola_tim_screen.dart';
import '../../../pengajuan/presentation/pengajuan_screen.dart';
import '../../../profil/presentation/screens/profil_screen.dart';
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

/// Halaman Beranda. Isinya berbeda-beda menurut [role].
///
/// Layar ini hanya merangkai section; tampilan tiap section ada di
/// `presentation/widgets/` dan datanya di `domain/home_demo_data.dart`.
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key, required this.role});

  final Role role;

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  /// Indeks tab navigasi bawah. Tab 4 dipakai role HOD untuk Persetujuan.
  static const _approvalTabIndex = 4;

  int _activeTab = 0;

  Role get _role => widget.role;

  void _openPengajuan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PengajuanScreen(role: _role)),
    );
  }

  void _openAbsensi() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AbsensiScreen()),
    );
  }

  void _openProfil() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfilScreen(role: _role)),
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
          label: 'Cuti & Izin',
          color: AppColors.primaryMid,
          background: AppColors.primaryLight,
          onTap: _openPengajuan,
        ),
        ServiceShortcut(
          icon: Icons.receipt_long_outlined,
          label: 'Slip Gaji',
          color: AppColors.accent,
          background: AppColors.accentBg,
          onTap: () {},
        ),
        ServiceShortcut(
          icon: Icons.fingerprint,
          label: 'Absensi',
          color: AppColors.present,
          background: AppColors.presentBg,
          onTap: _openAbsensi,
        ),
        ServiceShortcut(
          icon: Icons.calendar_month_outlined,
          label: 'Jadwal',
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: () {},
        ),
        ServiceShortcut(
          icon: Icons.badge_outlined,
          label: 'Profil',
          color: AppColors.violet,
          background: AppColors.violetBg,
          onTap: _openProfil,
        ),
        if (_role == Role.hod)
          ServiceShortcut(
            icon: Icons.task_alt,
            label: 'Persetujuan',
            color: AppColors.primary,
            background: AppColors.primaryLight,
            onTap: _openApprovalTab,
          ),
        if (_role == Role.admin)
          // SEMENTARA
          ServiceShortcut(
            icon: Icons.groups_outlined,
            label: 'Kelola Tim',
            color: AppColors.primaryMid,
            background: AppColors.primaryLight,
            onTap: _openKelolaTim,
          ),
      ];

  /// Tab selain Home membuka halaman lain, jadi indeks aktifnya tidak berubah.
  void _handleTabChange(int index) {
    switch (index) {
      case 1:
        _openPengajuan();
      case 2:
        _openAbsensi();
      case 3:
        _openProfil();
      // SEMENTARA
      case _approvalTabIndex when _role == Role.admin:
        _openKelolaTim();
      default:
        setState(() => _activeTab = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Header hijau tua mengisi area status bar, jadi ikon jam/sinyal/baterai
      // harus terang supaya tetap terbaca.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      // Beige hangat, sama dengan halaman Login — kartu putih jadi lebih
      // menonjol dibanding di atas AppColors.bg yang nyaris seputih kartunya.
      backgroundColor: AppColors.bgWarm,
      // top: false — HomeTopHeader yang mengurus jarak aman atas sendiri
      // supaya warna hijaunya tidak terpotong garis putih di atas.
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeTopHeader(role: _role),
              ClockStatusCard(
                status: HomeDemoData.todayAttendance,
                date: DateTime.now(),
                onActionTap: _openAbsensi,
              ),
              PendingRequestCard(
                count: 2,
                description: 'Lembur · Perjalanan Dinas',
                onTap: _openPengajuan,
              ),
              SaldoSection(
                balances: HomeDemoData.quotaBalancesFor(_role),
                onSeeAll: _openPengajuan,
              ),
              LayananSection(services: _buildServices()),
              if (_role == Role.hod)
                TeamBanner(
                  icon: Icons.fact_check_outlined,
                  iconColor: AppColors.primary,
                  iconBackground: AppColors.primaryLight,
                  title: '3 Pengajuan Perlu Ditinjau',
                  subtitle: 'Persetujuan tim menunggu Anda',
                  onTap: _openApprovalTab,
                ),
              if (_role == Role.admin)
                // SEMENTARA
                TeamBanner(
                  icon: Icons.groups_outlined,
                  iconColor: AppColors.primaryMid,
                  iconBackground: AppColors.primaryLight,
                  title: 'Kelola Tim Departemen',
                  subtitle: '18 Pegawai · Update saldo cuti',
                  onTap: _openKelolaTim,
                ),
              const ActivitySection(
                activities: HomeDemoData.recentActivities,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        role: _role,
        activeIndex: _activeTab,
        onChanged: _handleTabChange,
      ),
    );
  }
}
