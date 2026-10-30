import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_info.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
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
import '../../domain/profile_cover.dart';
import '../bloc/photo/profil_photo_bloc.dart';
import '../bloc/photo/profil_photo_event.dart';
import '../bloc/photo/profil_photo_state.dart';
import '../widgets/cover_background.dart';
import '../widgets/photo_source_sheet.dart';
import '../widgets/profile_avatar.dart';
import 'about_screen.dart';
import 'change_cover_screen.dart';
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
///
/// Saat dibuka, cover diambil ulang diam-diam dari server — bisa saja
/// diganti lewat web sejak login.
class ProfilScreen extends StatefulWidget {
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
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  late final ProfilRepository _repository =
      widget.repository ?? context.read<ProfilRepository>();

  @override
  void initState() {
    super.initState();
    _syncCover();
  }

  Future<void> _syncCover() async {
    if (widget.user == null) return;
    final ProfileCover? cover;
    try {
      cover = (await _repository.fetchCover()).cover;
    } on ApiException catch (e) {
      // Header tetap memakai cover dari sesi; tidak perlu mengganggu user.
      AppLogger.info('Gagal mengambil cover profil (${e.message})');
      return;
    }
    final user = widget.user;
    if (!mounted || cover == null || user == null || cover == user.cover) {
      return;
    }
    context.read<AuthBloc>().add(AuthUserRefreshed(user.copyWithCover(cover)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfilPhotoBloc(
        repository: _repository,
        picker: widget.picker ?? PhotoPickerService(),
      ),
      child: _ProfilView(role: widget.role, user: widget.user),
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
                        const SectionLabel('SETTINGS'),
                        const SizedBox(height: 8),
                        _buildThemeTile(),
                        const SizedBox(height: 10),
                        _buildMenuTile(
                          icon: Icons.lock_outline,
                          label: 'Update Password',
                          subtitle: 'Change your sign-in password',
                          onTap: () => _onUpdatePasswordTap(context),
                        ),
                        const SizedBox(height: 18),
                        const SectionLabel('GENERAL'),
                        const SizedBox(height: 8),
                        // Subtitle = versi terpasang, supaya tester bisa
                        // menyebutkannya tanpa membuka halaman About.
                        FutureBuilder<String>(
                          future: AppInfo.versionLabel(),
                          builder: (context, snapshot) => _buildMenuTile(
                            icon: Icons.info_outline,
                            label: 'About this app',
                            subtitle: snapshot.hasData
                                ? 'Version ${snapshot.data}'
                                : 'Version, licenses',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AboutScreen(),
                              ),
                            ),
                          ),
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

  Future<void> _onChangeCoverTap(BuildContext context) async {
    final u = user;
    if (u == null) return;
    final cover = await Navigator.of(context).push<ProfileCover>(
      MaterialPageRoute(builder: (_) => ChangeCoverScreen(user: u)),
    );
    if (cover == null || !context.mounted) return;
    context.read<AuthBloc>().add(AuthUserRefreshed(u.copyWithCover(cover)));
    _toast(context, 'Cover updated');
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

  /// Header: cover pilihan user (atau foto udara kawasan bila server belum
  /// mengirim cover) dengan gradasi gelap dari kiri, judul, tombol Change
  /// cover, lalu panel putih bertepi gelombang berisi avatar, nama,
  /// section, dan NIP.
  Widget _buildHeader(
      BuildContext context, EmployeeProfile p, ProfilPhotoState photoState) {
    final topInset = MediaQuery.paddingOf(context).top;
    // Foto berhenti sedikit di bawah puncak gelombang panel, supaya tidak
    // ada celah krem di antara keduanya.
    final heroHeight = topInset + 170;
    final panelTop = topInset + 128;
    const panelHeight = 142.0;
    const avatarLeft = 20.0;
    final canPop = Navigator.of(context).canPop();

    // Tinggi Stack memuat seluruh panel, supaya avatar yang menumpuk di
    // tepi gelombang tetap bisa diketuk (hit-test tidak keluar batas).
    return SizedBox(
      width: double.infinity,
      height: panelTop + panelHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoverBackground(cover: user?.cover),
                // Cover bawaan tetap bernuansa hijau seperti desain awal;
                // cover pilihan user cukup digelapkan sedikit dari kiri.
                if (user?.cover == null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0, 0.45, 1],
                        colors: [
                          AppColors.primary.withValues(alpha: 0.95), // AppColors.primary, 95%
                          AppColors.primary.withValues(alpha: 0.70), // 70%
                          AppColors.primary.withValues(alpha: 0.15), // 15%
                        ],
                      ),
                    ),
                  )
                else
                  const CoverReadabilityOverlay(),
              ],
            ),
          ),
          Positioned(
            left: canPop ? 8 : 24,
            right: 16,
            top: topInset + 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canPop)
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: Colors.white),
                  ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text(
                        //   'Profile',
                        //   style: TextStyle(
                        //       fontSize: 24,
                        //       fontWeight: FontWeight.w700,
                        //       color: Colors.white),
                        // ),
                        // SizedBox(height: 4),
                        // SizedBox(
                        //   width: 190,
                        //   child: Text(
                        //     'Together for a Better Industrial Estate',
                        //     style: TextStyle(
                        //         fontSize: 12,
                        //         fontWeight: FontWeight.w500,
                        //         color: Colors.white,
                        //         height: 1.35),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
                // _HeaderIconButton(
                //   icon: Icons.settings,
                //   tooltip: 'Update Password',
                //   onTap: () => _onUpdatePasswordTap(context),
                // ),
                if (user != null)
                  _ChangeCoverButton(onTap: () => _onChangeCoverTap(context)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: panelTop,
            height: panelHeight,
            child: ClipPath(
              clipper: _WaveTopClipper(),
              child: Container(
                color: AppColors.card,
                padding: const EdgeInsets.fromLTRB(
                    avatarLeft + ProfileAvatar.size + 16, 44, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          height: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.business_center,
                            size: 15, color: AppColors.textMid),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            user?.section ?? p.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMid),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.badge,
                              size: 15, color: AppColors.primaryMidText),
                          const SizedBox(width: 6),
                          Text(
                            'Emp. ID: ${user?.nik ?? p.nip}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                                letterSpacing: 0.2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: avatarLeft,
            top: panelTop - 8,
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

  /// Saklar mode gelap. Pilihan disimpan lokal oleh [ThemeCubit].
  Widget _buildThemeTile() {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        return AppCard(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryText.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.dark_mode_outlined,
                      size: 22, color: AppColors.primaryText),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dark mode',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text)),
                      const SizedBox(height: 2),
                      Text('Use a darker color theme',
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Switch(
                  value: mode == ThemeMode.dark,
                  activeTrackColor: AppColors.primaryText,
                  onChanged: (v) => context.read<ThemeCubit>().setDark(v),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                  color: AppColors.primaryText.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: AppColors.primaryText),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
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
        side: BorderSide(color: AppColors.rejected, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text('Logout',
          style: TextStyle(
              color: AppColors.rejected,
              fontSize: 14,
              fontWeight: FontWeight.w700)),
    );
  }
}

/// Tombol bulat hijau di pojok kanan atas header.
// ignore: unused_element
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton(
      {required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.primaryMid,
        shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Tepi atas bergelombang untuk panel identitas: rendah di kiri (tempat
/// avatar), naik di tengah, lalu turun lagi ke kanan.
class _WaveTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    return Path()
      ..moveTo(0, 34)
      ..cubicTo(w * 0.28, 4, w * 0.55, 0, w * 0.72, 22)
      ..cubicTo(w * 0.84, 38, w * 0.94, 30, w, 14)
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Pil "Change cover" di pojok kanan atas header, seperti di web portal.
class _ChangeCoverButton extends StatelessWidget {
  const _ChangeCoverButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const StadiumBorder(side: BorderSide(color: Colors.white24)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Change cover',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
