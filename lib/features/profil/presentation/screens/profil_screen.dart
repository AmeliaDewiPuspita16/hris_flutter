import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth/auth_event.dart';
import '../../../shared/domain/role.dart';
import '../../data/photo_picker_service.dart';
import '../../data/profil_repository.dart';
import '../../domain/employee_profile.dart';
import '../bloc/photo/profil_photo_bloc.dart';
import '../bloc/photo/profil_photo_event.dart';
import '../bloc/photo/profil_photo_state.dart';
import '../widgets/photo_source_sheet.dart';
import '../widgets/profile_avatar.dart';
import 'data_diri_screen.dart';
import 'kontrak_screen.dart';
import 'rekening_screen.dart';
import 'alamat_screen.dart';
import 'tanggungan_screen.dart';

class _CategoryItem {
  const _CategoryItem(this.icon, this.label, this.subtitle, this.builder);
  final IconData icon;
  final String label;
  final String subtitle;
  final WidgetBuilder builder;
}

/// Layar Profil. Hanya menyediakan [ProfilPhotoBloc] untuk ganti foto;
/// tampilannya ada di [_ProfilView].
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({
    super.key,
    required this.role,
    this.user,
    this.repository,
    this.picker,
  });

  final Role role;

  /// Pengguna yang sedang masuk. Null berarti belum ada sesi — header-nya
  /// jatuh kembali ke data demo milik [role].
  final AuthUser? user;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ProfilRepository? repository;

  /// Diisi test; di aplikasi memakai [PhotoPickerService] bawaan.
  final PhotoPickerService? picker;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfilPhotoBloc(
        repository: repository ?? context.read<ProfilRepository>(),
        picker: picker ?? PhotoPickerService(),
      ),
      child: _ProfilView(role: role, user: user),
    );
  }
}

class _ProfilView extends StatelessWidget {
  const _ProfilView({required this.role, this.user});

  final Role role;
  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final p = EmployeeProfile.of(role);

    final categories = <_CategoryItem>[
      _CategoryItem(Icons.badge_outlined, 'Data Diri', 'Identitas dan kontak pribadi', (_) => DataDiriScreen(profile: p, user: user)),
      _CategoryItem(Icons.description_outlined, 'Kontrak Kerja', 'Periode dan status kontrak', (_) => KontrakScreen(profile: p)),
      _CategoryItem(Icons.account_balance_outlined, 'Rekening Bank', 'Rekening untuk pembayaran', (_) => RekeningScreen(profile: p)),
      _CategoryItem(Icons.location_on_outlined, 'Alamat', 'Alamat domisili dan KTP', (_) => AlamatScreen(profile: p)),
      _CategoryItem(Icons.family_restroom_outlined, 'Tanggungan', 'Anggota keluarga yang ditanggung', (_) => TanggunganScreen(profile: p)),
    ];

    return BlocConsumer<ProfilPhotoBloc, ProfilPhotoState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onPhotoStateChanged,
      builder: (context, photoState) {
        return ColoredBox(
          color: AppColors.bg,
          // top: false — header hijaunya sengaja dibiarkan naik sampai ke balik
          // status bar, jadi _buildHeader yang menambahkan jarak amannya sendiri.
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, p, photoState),
                  const SizedBox(height: 18),
                  // Menu berupa tile terpisah, bukan satu daftar polos.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < categories.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _buildMenuTile(context, categories[i]),
                        ],
                        const SizedBox(height: 14),
                        _buildLogoutButton(context),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Hasil ganti foto: sukses diteruskan ke [AuthBloc] (pemegang sesi),
  /// gagal cukup ditampilkan sebagai snackbar.
  void _onPhotoStateChanged(BuildContext context, ProfilPhotoState state) {
    switch (state.status) {
      case ProfilPhotoStatus.success:
        final updated = state.user;
        if (updated != null) {
          context.read<AuthBloc>().add(AuthUserRefreshed(updated));
        }
        _toast(context, 'Foto profil diperbarui');
      case ProfilPhotoStatus.failure:
        _toast(context, state.errorMessage ?? 'Gagal mengganti foto profil.');
      case ProfilPhotoStatus.initial:
      case ProfilPhotoStatus.picking:
      case ProfilPhotoStatus.uploading:
        break;
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onAvatarTap(BuildContext context) async {
    final source = await showPhotoSourceSheet(context);
    if (source == null || !context.mounted) return;
    context.read<ProfilPhotoBloc>().add(ProfilPhotoPickRequested(source));
  }

  Widget _buildHeader(BuildContext context, EmployeeProfile p, ProfilPhotoState photoState) {
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight = topInset + 124;
    const half = ProfileAvatar.size / 2;

    return Column(
      children: [
        // Tinggi Stack sengaja memuat separuh avatar yang turun ke area
        // krem, supaya avatar tetap bisa diketuk (hit-test tidak keluar batas).
        SizedBox(
          width: double.infinity,
          height: heroHeight + half,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: double.infinity,
                height: heroHeight,
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(top: topInset + 16),
                decoration: BoxDecoration(
                  // Hijau muda lembut (tint dari warna utama), sudut bawah melengkung.
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.22),
                      AppColors.primary.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
                ),
                child: const Text(
                  'Profil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              Positioned(
                top: heroHeight - half,
                child: ProfileAvatar(
                  initials: p.initials,
                  user: user,
                  photo: photoState.photo,
                  uploading: photoState.status == ProfilPhotoStatus.uploading,
                  // Selama kamera/crop/upload berjalan, ketukan diabaikan.
                  onTap: photoState.isBusy ? null : () => _onAvatarTap(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            user?.name ?? p.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text, height: 1.2),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'NIP: ${user?.nik ?? p.nip}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(BuildContext context, _CategoryItem c) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: c.builder)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(c.icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text(c.subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
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
