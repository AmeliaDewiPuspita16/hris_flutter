import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_exception.dart';
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
  const _CategoryItem(this.icon, this.label, this.subtitle, this.builder);
  final IconData icon;
  final String label;
  final String subtitle;
  final WidgetBuilder builder;
}

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({
    super.key,
    required this.role,
    this.user,
  });

  final Role role;

  /// Pengguna yang sedang masuk. Null berarti belum ada sesi — header-nya
  /// jatuh kembali ke data demo milik [role].
  final AuthUser? user;

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  // Avatar: foto (radius [_avatarRadius]) + celah krem + cincin hijau.
  static const double _avatarRadius = 50;
  static const double _avatarGap = 4;
  static const double _avatarRingWidth = 3;
  static const double _avatarSize =
      (_avatarRadius + _avatarGap + _avatarRingWidth) * 2;

  // Batas dari server: jpeg/jpg/png, maksimal 1024 KB.
  static const int _maxPhotoBytes = 1024 * 1024;

  final _picker = ImagePicker();

  /// Foto yang baru dipilih, ditampilkan langsung tanpa menunggu foto dari
  /// server selesai dimuat. Null berarti pakai foto/inisial dari [user].
  File? _pickedPhoto;
  bool _uploading = false;

  Role get role => widget.role;
  AuthUser? get user => widget.user;

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
              _buildHeader(context, p),
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
  }

  // ---- Ganti foto profil -------------------------------------------------

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showPhotoSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _sheetItem(ctx, Icons.photo_camera_outlined, 'Ambil foto',
                  () => _pickAndUpload(ImageSource.camera)),
              _sheetItem(ctx, Icons.photo_library_outlined, 'Pilih dari galeri',
                  () => _pickAndUpload(ImageSource.gallery)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetItem(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text, size: 22),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
      ),
      onTap: () {
        Navigator.of(ctx).pop();
        onTap();
      },
    );
  }

  /// Alur lengkap: pilih foto -> cek syarat server -> upload -> sesi
  /// diperbarui lewat [AuthBloc].
  Future<void> _pickAndUpload(ImageSource source) async {
    // 1. Pilih. Ukuran asli dibiarkan dulu supaya user bisa meng-crop dari
    //    foto beresolusi penuh; pengecilannya dilakukan di langkah crop.
    final XFile? picked;
    try {
      picked = await _picker.pickImage(source: source);
    } catch (_) {
      _toast('Tidak bisa membuka kamera/galeri. Cek izin aplikasi.');
      return;
    }
    if (picked == null || !mounted) return;

    // 1b. Crop 1:1 (geser + zoom), seperti di WhatsApp. Hasilnya langsung
    //     JPG 800x800, jadi hampir pasti di bawah batas 1 MB server.
    //     Null berarti user membatalkan crop.
    final croppedPath = await _cropSquare(picked.path);
    if (croppedPath == null || !mounted) return;

    // 2. Cek syarat server di sisi aplikasi, supaya user langsung dapat
    //    pesan jelas tanpa menunggu upload yang pasti ditolak. Format dibaca
    //    dari ISI berkas, bukan dari namanya: path hasil image_picker bisa
    //    tanpa ekstensi, dan path Android memuat titik di nama package.
    var file = File(croppedPath);
    final ext = await _detectExtension(file);
    if (ext == null) {
      _toast('Format foto harus JPG atau PNG.');
      return;
    }
    if (await file.length() > _maxPhotoBytes) {
      _toast('Ukuran foto terlalu besar (maksimal 1 MB).');
      return;
    }
    // Pastikan nama berkas berekstensi sesuai isinya, supaya Content-Type
    // yang dikirim ke server benar.
    final lower = file.path.toLowerCase();
    final nameOk = lower.endsWith('.$ext') || (ext == 'jpg' && lower.endsWith('.jpeg'));
    if (!nameOk) {
      file = await file.copy(
        '${Directory.systemTemp.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
    }
    if (!mounted) return;

    // 3. Upload. Foto tampil dulu secara lokal; bila gagal, dikembalikan.
    final bloc = context.read<AuthBloc>();
    final previous = _pickedPhoto;
    setState(() {
      _pickedPhoto = file;
      _uploading = true;
    });

    try {
      await bloc.changeProfilePhoto(file);
      if (!mounted) return;
      setState(() => _uploading = false);
      _toast('Foto profil diperbarui');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pickedPhoto = previous;
        _uploading = false;
      });
      _toast(e is ApiException ? e.message : 'Gagal mengunggah foto. Coba lagi.');
    }
  }

  /// Membuka layar crop bawaan platform dengan bingkai bulat dan rasio 1:1
  /// terkunci. Mengembalikan path hasil crop, atau null bila dibatalkan /
  /// gagal.
  Future<String?> _cropSquare(String sourcePath) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Atur foto profil',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'Atur foto profil',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
            resetAspectRatioEnabled: false,
            cropStyle: CropStyle.circle,
          ),
        ],
      );
      return cropped?.path;
    } catch (_) {
      _toast('Gagal membuka layar crop foto.');
      return null;
    }
  }

  /// Mengenali format dari beberapa byte pertama berkas: `jpg` untuk JPEG,
  /// `png` untuk PNG, null untuk selain itu (mis. HEIC, WebP, bukan gambar).
  Future<String?> _detectExtension(File file) async {
    final raf = await file.open();
    try {
      final head = await raf.read(8);
      if (head.length >= 3 && head[0] == 0xFF && head[1] == 0xD8 && head[2] == 0xFF) {
        return 'jpg';
      }
      if (head.length >= 8 &&
          head[0] == 0x89 &&
          head[1] == 0x50 &&
          head[2] == 0x4E &&
          head[3] == 0x47) {
        return 'png';
      }
      return null;
    } finally {
      await raf.close();
    }
  }

  /// Avatar besar di tengah dengan cincin hijau + celah krem, dan tombol
  /// kamera putih di pojok kanan bawah.
  Widget _buildAvatar(BuildContext context, EmployeeProfile p) {
    return Semantics(
      button: true,
      label: 'Ubah foto profil',
      child: GestureDetector(
        // Selama upload, ketukan diabaikan supaya tidak ada upload ganda.
        onTap: _uploading ? null : _showPhotoSheet,
        child: SizedBox(
          width: _avatarSize,
          height: _avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(_avatarGap),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: _avatarRingWidth),
                ),
                child: _pickedPhoto != null
                    ? CircleAvatar(
                        radius: _avatarRadius,
                        backgroundImage: FileImage(_pickedPhoto!),
                      )
                    : UserAvatar(
                        initials: user?.initials ?? p.initials,
                        photoUrl: user?.photoUrl,
                        radius: _avatarRadius,
                        backgroundColor: AppColors.primary,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
              ),
              if (_uploading)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(_avatarGap + _avatarRingWidth),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 2,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EmployeeProfile p) {
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight = topInset + 124;
    const half = _avatarSize / 2;

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
                child: _buildAvatar(context, p),
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
