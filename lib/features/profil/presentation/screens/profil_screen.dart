import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/detail_field_tile.dart';
import '../../../../core/widgets/profile_ui.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth/auth_event.dart';
import '../../../shared/domain/role.dart';
import '../../data/photo_picker_service.dart';
import '../../data/profil_repository.dart';
import '../../domain/employee_profile.dart';
import '../../domain/photo_source.dart';
import '../bloc/photo/profil_photo_bloc.dart';
import '../bloc/photo/profil_photo_event.dart';
import '../bloc/photo/profil_photo_state.dart';
import '../widgets/photo_source_sheet.dart';
import '../widgets/profile_avatar.dart';
import 'profile_photo_viewer_screen.dart';
import 'update_password_screen.dart';

/// Layar Profil. Hanya menyediakan [ProfilPhotoBloc] untuk ganti foto;
/// tampilannya ada di [_ProfilView].
///
/// Isinya data `user` dari respons login, menu Update Password, dan Logout.
/// Menu Personal Data, Employment Contract, Bank Account, Address, dan
/// Dependents disembunyikan dulu karena datanya masih demo — menunggu API
/// HRIS dari Openbravo. Layarnya (DataDiriScreen, KontrakScreen, dst.)
/// sengaja tidak dihapus.
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
                        const SectionLabel('USER INFORMATION'),
                        const SizedBox(height: 8),
                        _buildInfoCard(p),
                        const SizedBox(height: 18),
                        const SectionLabel('SECURITY'),
                        const SizedBox(height: 8),
                        _buildMenuTile(
                          icon: Icons.lock_outline,
                          label: 'Update Password',
                          subtitle: 'Change your sign-in password',
                          onTap: () => _onUpdatePasswordTap(context),
                        ),
                        const SizedBox(height: 18),
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
        _toast(context, 'Profile photo updated');
      case ProfilPhotoStatus.failure:
        _toast(context,
            state.errorMessage ?? 'Failed to change the profile photo.');
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

  Future<void> _onUpdatePasswordTap(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
    );
    if (changed == true && context.mounted) {
      _toast(context, 'Password updated');
    }
  }

  Future<void> _onAvatarTap(
      BuildContext context, ProfilPhotoState photoState) async {
    final hasPhoto = photoState.photo != null || user?.photoUrl != null;
    final action = await showPhotoSourceSheet(context, hasPhoto: hasPhoto);
    if (action == null || !context.mounted) return;

    switch (action) {
      case PhotoSheetAction.view:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProfilePhotoViewerScreen(
            localPhoto: photoState.photo,
            photoUrl: photoState.photo == null ? user?.photoUrl : null,
          ),
        ));
      case PhotoSheetAction.camera:
        context
            .read<ProfilPhotoBloc>()
            .add(const ProfilPhotoPickRequested(PhotoSource.camera));
      case PhotoSheetAction.gallery:
        context
            .read<ProfilPhotoBloc>()
            .add(const ProfilPhotoPickRequested(PhotoSource.gallery));
    }
  }

  Widget _buildHeader(
      BuildContext context, EmployeeProfile p, ProfilPhotoState photoState) {
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
                decoration: const BoxDecoration(
                  // Sama dengan header Beranda (HomeTopHeader), supaya kedua
                  // layar terasa satu identitas visual.
                  image: DecorationImage(
                    image: AssetImage('assets/images/header_bg.png'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: const Text(
                  'Profile',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
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
                  onTap: photoState.isBusy
                      ? null
                      : () => _onAvatarTap(context, photoState),
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
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                height: 1.2),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            user?.section ?? p.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMid),
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
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2),
          ),
        ),
      ],
    );
  }

  /// Data `user` dari respons login, kecuali role. Field yang kosong di
  /// server jatuh ke data demo [p] (atau "-" bila demo pun tidak punya).
  Widget _buildInfoCard(EmployeeProfile p) {
    final u = user;
    final birthDate = u == null
        ? p.birthDate
        : DateFormatter.dayMonthYearFromIso(u.dateOfBirth) ?? '-';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          DetailFieldTile(label: 'Email', value: u?.email ?? p.email),
          DetailFieldTile(
              label: 'Phone No.',
              value: _orDash(u == null ? p.phone : u.phone)),
          DetailFieldTile(label: 'Date of Birth', value: birthDate),
          DetailFieldTile(
              label: 'Gender',
              value: _genderLabel(u?.gender),
              showDivider: false),
        ],
      ),
    );
  }

  static String _orDash(String? value) =>
      value == null || value.trim().isEmpty ? '-' : value;

  /// Server mengirim `male`/`female`; kode L/P juga diterima.
  static String _genderLabel(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'male' || 'm' || 'l' || 'laki-laki':
        return 'Male';
      case 'female' || 'f' || 'p' || 'perempuan':
        return 'Female';
      case null || '':
        return '-';
      default:
        return raw!;
    }
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textMuted),
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
      child: const Text('Logout',
          style: TextStyle(
              color: AppColors.rejected,
              fontSize: 14,
              fontWeight: FontWeight.w700)),
    );
  }
}
