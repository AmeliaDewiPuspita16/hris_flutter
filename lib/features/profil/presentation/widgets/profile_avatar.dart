import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/auth_user.dart';

/// Avatar besar di tengah dengan cincin hijau + celah krem, tombol kamera
/// putih di pojok kanan bawah, dan lapisan spinner selama upload.
///
/// Hanya menggambar; tidak tahu soal bloc. Foto lokal [photo] (bila ada)
/// menang atas foto dari server supaya langsung tampil setelah dipilih.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initials,
    this.user,
    this.photo,
    this.uploading = false,
    this.onTap,
  });

  final String initials;
  final AuthUser? user;
  final File? photo;
  final bool uploading;

  /// Null menonaktifkan ketukan (mis. saat upload berjalan).
  final VoidCallback? onTap;

  // Foto (radius [_radius]) + celah krem + cincin hijau.
  static const double _radius = 50;
  static const double _gap = 4;
  static const double _ringWidth = 3;

  /// Garis tengah total avatar; dipakai header untuk menaruhnya setengah
  /// turun ke area krem.
  static const double size = (_radius + _gap + _ringWidth) * 2;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ubah foto profil',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(_gap),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: _ringWidth),
                ),
                child: photo != null
                    ? CircleAvatar(radius: _radius, backgroundImage: FileImage(photo!))
                    : UserAvatar(
                        initials: user?.initials ?? initials,
                        photoUrl: user?.photoUrl,
                        radius: _radius,
                        backgroundColor: AppColors.primary,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
              ),
              if (uploading)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(_gap + _ringWidth),
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
}
