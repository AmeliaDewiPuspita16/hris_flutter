import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../shared/domain/role.dart';
import '../../../pengajuan/presentation/pengajuan_screen.dart';
import '../../../pengajuan/domain/leave_type.dart';
import '../../../absensi/presentation/absensi_screen.dart';
import '../../../profil/presentation/screens/profil_screen.dart';
import '../../../kelola_tim/presentation/screens/kelola_tim_screen.dart';

class _QuotaCard {
  const _QuotaCard(
      this.label, this.value, this.total, this.unit, this.color, this.bg);
  final String label;
  final num value;
  final num? total;
  final String unit;
  final Color color;
  final Color bg;
}

class _ServiceItem {
  const _ServiceItem(this.icon, this.label, this.onTap);
  final String icon;
  final String label;
  final VoidCallback onTap;
}

class _ActivityItem {
  const _ActivityItem(this.icon, this.title, this.desc, this.time, this.bg);
  final String icon;
  final String title;
  final String desc;
  final String time;
  final Color bg;
}

/// Padanan `function BerandaScreen(...)` di App.tsx.
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key, required this.role});

  final Role role;

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  int _activeTab = 0;

  void _openPengajuan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PengajuanScreen(role: widget.role)),
    );
  }

  void _openAbsensi() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AbsensiScreen()),
    );
  }

  void _openProfil() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfilScreen(role: widget.role)),
    );
  }

  void _openKelolaTim() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KelolaTimScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;

    final quotaCards = <_QuotaCard>[
      _QuotaCard('Cuti Tahunan', 8, 12, 'Hari', AppColors.primaryMid,
          AppColors.primaryLight),
      if (LeaveTypeX.showPersonalLembur(role))
        const _QuotaCard('Saldo Lembur', 14.5, null, 'Jam', Color(0xFF6B46C1),
            Color(0xFFFAF5FF))
      else
        const _QuotaCard('Cuti Pengganti', 3, 5, 'Hari', Color(0xFF2C7A7B),
            Color(0xFFE6FFFA)),
      const _QuotaCard('Cek Kesehatan', 1, 1, 'Kali', AppColors.pending,
          AppColors.pendingBg),
    ];

    final services = <_ServiceItem>[
      _ServiceItem('📋', 'Cuti & Izin', _openPengajuan),
      _ServiceItem('💰', 'Slip Gaji', () {}),
      _ServiceItem('📅', 'Absensi', () {}),
      _ServiceItem('🗓️', 'Jadwal', () {}),
      _ServiceItem('👤', 'Profil', _openProfil),
      if (role == Role.hod)
        _ServiceItem('✅', 'Persetujuan', () => setState(() => _activeTab = 4)),
      if (role == Role.admin)
        _ServiceItem('👥', 'Kelola Tim', _openKelolaTim), // SEMENTARA
    ];

    const activities = [
      _ActivityItem('✅', 'Cuti Tahunan Disetujui', '17–19 Jul 2025 · 3 hari',
          '2 jam lalu', AppColors.presentBg),
      _ActivityItem('⏳', 'Lembur Menunggu', '28 Jul · 18:30–20:45 WIB',
          'Kemarin', AppColors.pendingBg),
      _ActivityItem('💰', 'Slip Gaji Juli Tersedia', 'Rp 12.500.000',
          '1 hari lalu', AppColors.neutralBg),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopHeader(role: role),
              _PengajuanAktifCard(
                count: 2,
                desc: 'Lembur · Perjalanan Dinas',
                onTap: _openPengajuan,
              ),
              _SaldoSection(
                  quotaCards: quotaCards, onLihatSemua: _openPengajuan),
              _LayananSection(services: services),
              if (role == Role.hod)
                _TeamBanner(
                  icon: Icons.fact_check_outlined,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primaryLight,
                  title: '3 Pengajuan Perlu Ditinjau',
                  subtitle: 'Persetujuan tim menunggu Anda',
                  onTap: () => setState(() => _activeTab = 4),
                ),
              if (role == Role.admin)
                // SEMENTARA — lihat komentar TODO(konfirmasi-HRIS) di bagian import.
                _TeamBanner(
                  icon: Icons.groups_outlined,
                  iconColor: AppColors.primaryMid,
                  iconBg: AppColors.primaryLight,
                  title: 'Kelola Tim Departemen',
                  subtitle: '18 Pegawai · Update saldo cuti',
                  onTap: _openKelolaTim,
                ),
              _ActivitySection(activities: activities),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        role: role,
        active: _activeTab,
        // onChange: (i) => setState(() => _activeTab = i),
        onChange: (i) {
          if (i == 1) {
            _openPengajuan();
            return;
          }
          if (i == 2) {
            _openAbsensi();
            return;
          }
          if (i == 3) {
            _openProfil();
            return;
          }
          // SEMENTARA — lihat komentar TODO(konfirmasi-HRIS) di bagian import.
          if (i == 4 && role == Role.admin) {
            _openKelolaTim();
            return;
          }
          setState(() => _activeTab = i);
        },
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.role});
  final Role role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              role.initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, ${role.firstName} 👋', style: AppTextStyles.h3),
                const SizedBox(height: 2),
                Text(
                  role.demoUserTitle,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 20),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.accentLight, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card status pengajuan aktif — dipisah dari header (bukan lagi nested di
/// dalam gradient) supaya header cuma berisi identitas, sesuai referensi.
/// Card otomatis hilang kalau tidak ada pengajuan yang menunggu.
class _PengajuanAktifCard extends StatelessWidget {
  const _PengajuanAktifCard({
    required this.count,
    required this.desc,
    required this.onTap,
  });

  final int count;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pengajuan Menunggu',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Lihat',
                    style: TextStyle(
                        color: AppColors.primaryMid,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                Icon(Icons.chevron_right, size: 16, color: AppColors.primaryMid),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SaldoSection extends StatelessWidget {
  const _SaldoSection({required this.quotaCards, required this.onLihatSemua});
  final List<_QuotaCard> quotaCards;
  final VoidCallback onLihatSemua;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saldo Saya', style: AppTextStyles.sectionTitle),
                TextButton(
                  onPressed: onLihatSemua,
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text('Lihat Semua',
                      style: TextStyle(
                          color: AppColors.primaryMid,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: quotaCards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final q = quotaCards[i];
                return Container(
                  width: 120,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: q.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: q.color.withValues(alpha: 0.19)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.label.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: q.color,
                              letterSpacing: 0.3)),
                      const SizedBox(height: 6),
                      Text('${q.value}',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: q.color,
                              height: 1)),
                      const SizedBox(height: 2),
                      Text(
                        '${q.total != null ? 'dari ${q.total} ' : ''}${q.unit}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LayananSection extends StatelessWidget {
  const _LayananSection({required this.services});
  final List<_ServiceItem> services;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Layanan', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services.map((s) {
              return SizedBox(
                width: 72,
                child: InkWell(
                  onTap: s.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                              color: AppColors.neutralBg,
                              shape: BoxShape.circle),
                          child: Text(s.icon,
                              style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSub,
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TeamBanner extends StatelessWidget {
  const _TeamBanner({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.activities});
  final List<_ActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Aktivitas Terbaru', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          ...activities.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: a.bg,
                            borderRadius: BorderRadius.circular(10)),
                        child:
                            Text(a.icon, style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text)),
                            const SizedBox(height: 2),
                            Text(a.desc,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Text(a.time,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav(
      {required this.role, required this.active, required this.onChange});

  final Role role;
  final int active;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          activeIcon: Icon(Icons.description),
          label: 'Request'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.event_note_outlined),
          activeIcon: Icon(Icons.event_note),
          label: 'Attendance'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile'),
      if (role == Role.hod)
        const BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: 'Persetujuan'),
      if (role == Role.admin)
        const BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'Kelola Tim'),
    ];

    return BottomNavigationBar(
      currentIndex: active < items.length ? active : 0,
      onTap: onChange,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      selectedLabelStyle:
          const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500),
      backgroundColor: Colors.white,
      items: items,
    );
  }
}