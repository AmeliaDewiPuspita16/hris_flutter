import 'package:flutter/widgets.dart';

import '../../auth/domain/auth_user.dart';
import '../../shared/domain/role.dart';

/// Kelompok item di halaman menu HRIS. Urutan enum = urutan tampil;
/// kelompok tanpa item yang terlihat otomatis tidak ditampilkan.
enum HrisMenuGroup {
  attendance('Attendance'),
  leave('Leave & Time Off'),
  employee('Employee'),
  team('Team');

  const HrisMenuGroup(this.label);

  final String label;
}

/// Data yang dibutuhkan untuk memutuskan sebuah item terlihat atau tidak.
///
/// Sekarang masih memakai [Role] (enum UI yang dipatok di `AuthGate`).
/// Begitu pemetaan role dari API sudah diputuskan, cukup ganti aturan di
/// `HrisMenuConfig` memakai [user] (mis. `user.canApproveLeave`) — layar
/// menu dan item lain tidak perlu berubah.
class HrisMenuContext {
  const HrisMenuContext({required this.role, this.user});

  final Role role;
  final AuthUser? user;
}

typedef HrisMenuVisibility = bool Function(HrisMenuContext context);

bool _visibleToEveryone(HrisMenuContext context) => true;

/// Satu item di menu HRIS.
class HrisMenuItem {
  const HrisMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.group,
    required this.color,
    required this.background,
    required this.onTap,
    this.isReady = true,
    this.isVisible = _visibleToEveryone,
    this.badgeCount = 0,
  });

  /// Pengenal stabil (snake_case), berguna untuk test dan analytics.
  final String id;
  final String label;
  final IconData icon;
  final HrisMenuGroup group;

  /// Warna ikon dan latar kotak ikon.
  final Color color;
  final Color background;

  final VoidCallback onTap;

  /// False = fitur belum tersedia (mis. API/data vendor belum ada). Item
  /// disembunyikan; tinggal ubah jadi true saat fiturnya siap.
  final bool isReady;

  /// Aturan siapa yang boleh melihat item ini.
  final HrisMenuVisibility isVisible;

  /// Angka kecil di pojok kanan atas ikon (mis. jumlah approval). 0 = tanpa badge.
  final int badgeCount;
}
