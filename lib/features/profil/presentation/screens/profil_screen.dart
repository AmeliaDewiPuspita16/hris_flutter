import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth/auth_event.dart';
import '../../../shared/domain/role.dart';
import '../../domain/employee_profile.dart';
import 'data_diri_screen.dart';
import 'kontrak_screen.dart';
import 'rekening_screen.dart';
import 'alamat_screen.dart';
import 'tanggungan_screen.dart';

class _CategoryItem {
  const _CategoryItem(this.icon, this.label, this.builder);
  final IconData icon;
  final String label;
  final WidgetBuilder builder;
}

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({
    super.key,
    required this.role,
    this.user,
  });

  final Role role;

  /// Pengguna yang sedang masuk. Null berarti belum ada sesi — hero-nya
  /// jatuh kembali ke data demo milik [role].
  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final p = EmployeeProfile.of(role);

    final categories = <_CategoryItem>[
      _CategoryItem(Icons.badge_outlined, 'Data Diri', (_) => DataDiriScreen(profile: p, user: user)),
      _CategoryItem(Icons.description_outlined, 'Kontrak Kerja', (_) => KontrakScreen(profile: p)),
      _CategoryItem(Icons.account_balance_outlined, 'Rekening Bank', (_) => RekeningScreen(profile: p)),
      _CategoryItem(Icons.location_on_outlined, 'Alamat', (_) => AlamatScreen(profile: p)),
      _CategoryItem(Icons.family_restroom_outlined, 'Tanggungan', (_) => TanggunganScreen(profile: p)),
    ];

    return ColoredBox(
      color: AppColors.bg,
      // top: false — hero hijaunya sengaja dibiarkan naik sampai ke balik
      // status bar, jadi _buildHero yang menambahkan jarak amannya sendiri.
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(context, p),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatsCard(),
                      const SizedBox(height: 14),
                      const Text('DATA SAYA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.3)),
                      const SizedBox(height: 8),
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: List.generate(categories.length, (i) {
                            final c = categories[i];
                            return InkWell(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: c.builder)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                  border: i < categories.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(color: AppColors.neutralBg, shape: BoxShape.circle),
                                      child: Icon(c.icon, size: 17, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(c.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                                    ),
                                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const SizedBox(height: 16),
                      _buildLogoutButton(context),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, EmployeeProfile p) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 24, 20, 52),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Row(
        children: [
          UserAvatar(
            initials: user?.initials ?? p.initials,
            photoUrl: user?.photoUrl,
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 3),
                // API tidak punya field jabatan; `section` adalah keterangan
                // unit kerja terdekat yang tersedia.
                Text(user?.section ?? p.title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 2),
                Text('NIP: ${user?.nik ?? p.nip}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    const stats = [('7 Thn', 'Masa Kerja'), ('94%', 'Kehadiran'), ('8', 'Sisa Cuti')];
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Column(
              children: [
                Text(s.$1, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 2),
                Text(s.$2, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton(
      // Cukup lapor ke AuthBloc — AuthGate yang memulangkan ke layar login,
      // jadi jalurnya sama dengan sesi yang kedaluwarsa.
      onPressed: () => context.read<AuthBloc>().add(
            const AuthLogoutRequested(),
          ),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.rejectedBg,
        side: const BorderSide(color: AppColors.rejected, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('Logout', style: TextStyle(color: AppColors.rejected, fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }
}