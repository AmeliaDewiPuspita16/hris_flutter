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
  const _QuotaCard(this.label, this.value, this.suffix, this.pct);

  final String label;
  final String value;

  /// Teks setelah angka, mis. "/12 days", "of 5.0", "hrs this month".
  final String suffix;

  /// 0..1 untuk progress bar. null = progress bar disembunyikan.
  final double? pct;
}

class _ServiceItem {
  const _ServiceItem(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _AnnouncementItem {
  const _AnnouncementItem(this.icon, this.iconBg, this.tag, this.tagColor,
      this.tagBg, this.title, this.desc, this.time);
  final IconData icon;
  final Color iconBg;
  final String tag;
  final Color tagColor;
  final Color tagBg;
  final String title;
  final String desc;
  final String time;
}

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

  // void _paySlip() {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(builder: (_) => const Payslip()),
  //   );
  // }

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

  void _onNewAnnouncement() {}

  @override
  Widget build(BuildContext context) {
    final role = widget.role;

    final quotaCards = <_QuotaCard>[
      const _QuotaCard('Annual Leave', '7.5', '/12 days', 0.62),
      if (LeaveTypeX.showPersonalLembur(role))
        const _QuotaCard('Overtime', '18', 'hrs this month', 0.75)
      else
        const _QuotaCard('Off in Lieu', '2', 'days', 0.4),
      const _QuotaCard('Medical Check', '2.4', 'of 5.0', 0.48),
    ];

    final services = <_ServiceItem>[
      _ServiceItem(
          Icons.description_outlined, 'Leave & Permission', _openPengajuan),
      _ServiceItem(Icons.receipt_long_outlined, 'Pay Slip', () {}),
      _ServiceItem(Icons.access_time_outlined, 'Attendance', _openAbsensi),
      _ServiceItem(Icons.calendar_month_outlined, 'Schedule', () {}),
      _ServiceItem(Icons.person_outline, 'Profile', _openProfil),
      if (role == Role.hod)
        _ServiceItem(Icons.check_circle_outline, 'Approval',
            () => setState(() => _activeTab = 4)),
      if (role == Role.admin)
        _ServiceItem(
            Icons.groups_outlined, 'Manage Team', _openKelolaTim), // SEMENTARA
      if (role == Role.hrPublisher)
        _ServiceItem(Icons.campaign_outlined, 'Publish',
            _onNewAnnouncement), // TODO(fitur-publish-announcement)
    ];

    const announcements = [
      _AnnouncementItem(
        Icons.campaign_outlined,
        AppColors.primaryLight,
        'HR',
        AppColors.primaryMid,
        AppColors.primaryLight,
        'Payroll cut-off moves to the 23rd',
        'Overtime claims must be approved by your supervisor before 23 Sep, 17:00.',
        'Yesterday',
      ),
      _AnnouncementItem(
        Icons.local_hospital_outlined,
        AppColors.pendingBg,
        'Clinic',
        AppColors.pending,
        AppColors.pendingBg,
        'Annual medical check-up now open',
        'Booking for your check-up is open until the end of the month.',
        '2 days ago',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopHeader(role: role),
              Transform.translate(
                offset: const Offset(0, -34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AttendanceCard(checkIn: role.demoCheckIn),
                    if (role == Role.hod)
                      _AlertCard(
                        title: 'Approval inbox',
                        subtitle: 'Overtime · Annual leave · Off in lieu',
                        count: 2,
                        onTap: () => setState(() => _activeTab = 4),
                      ),
                    if (role == Role.admin)
                      _AlertCard(
                        title: 'Manage Team',
                        subtitle: '18 employees · leave balance needs review',
                        count: 3,
                        onTap: _openKelolaTim,
                      ),
                    _SaldoSection(
                        quotaCards: quotaCards, onLihatSemua: _openPengajuan),
                    _LayananSection(services: services),
                    _AnnouncementSection(
                      announcements: announcements,
                      onNewAnnouncement:
                          role == Role.hrPublisher ? _onNewAnnouncement : null,
                    ),
                  ],
                ),
              ),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 46),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text('Hi, ${role.firstName} 👋', style: AppTextStyles.h3),
                    const SizedBox(height: 2),
                    Text(
                      role.demoUserTitle,
                      style: const TextStyle(
                          color: AppColors.bannerAccent,
                          fontWeight: FontWeight.w500,
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
          const SizedBox(height: 14),
          // dummy — nanti diganti tanggal hari ini beneran (DateTime.now()).
          Text(
            'Monday, 8 September 2026',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Kartu status absensi — READ ONLY. Sumber datanya mesin fingerprint
class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.checkIn, this.checkOut});

  final String checkIn;
  final String? checkOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _AttendanceColumn(
                    label: 'Check In',
                    time: checkIn,
                    recorded: true,
                  ),
                ),
                Container(width: 1, height: 34, color: AppColors.border),
                const SizedBox(width: 12),
                Expanded(
                  child: _AttendanceColumn(
                    label: 'Check Out',
                    time: checkOut ?? 'Not recorded yet',
                    recorded: checkOut != null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 9),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: AppColors.textMuted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Recorded automatically by the fingerprint device · '
                    'Gate A. Attendance is not taken through this app.',
                    style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceColumn extends StatelessWidget {
  const _AttendanceColumn(
      {required this.label, required this.time, required this.recorded});

  final String label;
  final String time;
  final bool recorded;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: recorded ? AppColors.moduleTealBg : AppColors.neutralBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.fingerprint,
              size: 18,
              color: recorded ? AppColors.moduleTealIcon : AppColors.neutral),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.3)),
              const SizedBox(height: 1),
              Text(time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: recorded ? AppColors.text : AppColors.neutral)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kartu "perlu tindakan" — Approval inbox (HOD) / Manage Team (Admin).
class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.moduleCoralBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.moduleCoralIcon.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.fact_check_outlined,
                    size: 18, color: AppColors.moduleCoralIcon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.moduleCoralIcon)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textSub)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.rejected,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$count',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Balance', style: AppTextStyles.sectionTitle),
              TextButton(
                onPressed: onLihatSemua,
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('Request',
                    style: TextStyle(
                        color: AppColors.primaryMid,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < quotaCards.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _BalanceCard(card: quotaCards[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.card});
  final _QuotaCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.2)),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: card.value,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text)),
                TextSpan(
                    text: ' ${card.suffix}',
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted)),
              ],
            ),
          ),
          if (card.pct != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: card.pct!.clamp(0, 1),
                minHeight: 4,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.primaryMid),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LayananSection extends StatelessWidget {
  const _LayananSection({required this.services});
  final List<_ServiceItem> services;

  static const List<({Color bg, Color icon})> _moduleColors = [
    (bg: AppColors.moduleTealBg, icon: AppColors.moduleTealIcon),
    (bg: AppColors.moduleCoralBg, icon: AppColors.moduleCoralIcon),
    (bg: AppColors.moduleBlueBg, icon: AppColors.moduleBlueIcon),
    (bg: AppColors.modulePurpleBg, icon: AppColors.modulePurpleIcon),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Services', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: services.asMap().entries.map((entry) {
              final s = entry.value;
              // "Publish" dapat treatment emas (accent), dipakai terbatas —
              // sisanya cycle lewat 4 warna module Portal biar konsisten.
              final isPublish = s.label == 'Publish';
              final module = isPublish
                  ? (
                      bg: AppColors.accentLight.withValues(alpha: 0.25),
                      icon: AppColors.accent
                    )
                  : _moduleColors[entry.key % _moduleColors.length];

              return SizedBox(
                width: 68,
                child: InkWell(
                  onTap: s.onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: module.bg,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(s.icon, size: 22, color: module.icon),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                            height: 1.25),
                      ),
                    ],
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

class _AnnouncementSection extends StatelessWidget {
  const _AnnouncementSection({
    required this.announcements,
    this.onNewAnnouncement,
  });

  final List<_AnnouncementItem> announcements;
  final VoidCallback? onNewAnnouncement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Announcements', style: AppTextStyles.sectionTitle),
              if (onNewAnnouncement != null)
                TextButton.icon(
                  onPressed: onNewAnnouncement,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: const Icon(Icons.add, size: 14, color: Colors.white),
                  label: const Text('New',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...announcements.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: a.iconBg,
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(a.icon, size: 18, color: a.tagColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: a.tagBg,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(a.tag,
                                      style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: a.tagColor)),
                                ),
                                const SizedBox(width: 6),
                                Text(a.time,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(a.title,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text)),
                            const SizedBox(height: 2),
                            Text(a.desc,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    height: 1.35)),
                          ],
                        ),
                      ),
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
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'PaySsip'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile'),
      if (role == Role.hod)
        const BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: 'Approval'),
      if (role == Role.admin)
        const BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'Manage Team'),
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
