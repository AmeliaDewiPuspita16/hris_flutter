import 'dart:io';

import 'package:flutter/material.dart';

/// Layar penuh untuk melihat foto profil — foto lokal yang baru dipilih
/// (belum tentu sudah terupload) menang atas foto dari server, sama seperti
/// [ProfileAvatar]. Bisa di-pinch zoom, ditutup lewat tombol X atau swipe-back.
class ProfilePhotoViewerScreen extends StatelessWidget {
  const ProfilePhotoViewerScreen({super.key, this.localPhoto, this.photoUrl});

  final File? localPhoto;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final photo = localPhoto;
    final url = photoUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: photo != null
                  ? Image.file(photo)
                  : Image.network(
                      url!,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}
