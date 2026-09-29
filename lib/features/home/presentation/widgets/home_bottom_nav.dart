import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/main_tab.dart';

/// Navigasi bawah Beranda: Home, HRIS, Notifications, Profile.
///
/// Sama untuk semua role. Fitur yang hanya untuk role tertentu (Approvals,
/// Manage Team, dst.) tidak lagi jadi tab sendiri, tapi item di menu HRIS
/// (lihat `HrisMenuConfig`).
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.activeTab,
    required this.onChanged,
    this.unreadCount = 0,
  });

  final MainTab activeTab;
  final ValueChanged<MainTab> onChanged;

  /// Jumlah notifikasi belum dibaca, ditampilkan sebagai badge di tab
  /// Notifications.
  final int unreadCount;

  Widget _notificationIcon(IconData icon) {
    return Badge(
      isLabelVisible: unreadCount > 0,
      label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Urutan harus sama dengan urutan nilai [MainTab].
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.grid_view_outlined),
        activeIcon: Icon(Icons.grid_view),
        label: 'HRIS',
      ),
      BottomNavigationBarItem(
        icon: _notificationIcon(Icons.notifications_outlined),
        activeIcon: _notificationIcon(Icons.notifications),
        label: 'Notifications',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    return BottomNavigationBar(
      currentIndex: activeTab.index,
      onTap: (index) => onChanged(MainTab.values[index]),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      selectedLabelStyle: const TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: AppColors.card,
      items: items,
    );
  }
}
