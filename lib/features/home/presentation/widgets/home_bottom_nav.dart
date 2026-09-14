import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shared/domain/role.dart';

/// Navigasi bawah Beranda. Dua tab terakhir hanya muncul untuk role tertentu.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.role,
    required this.activeIndex,
    required this.onChanged,
  });

  final Role role;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.description_outlined),
        activeIcon: Icon(Icons.description),
        label: 'Request',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.event_note_outlined),
        activeIcon: Icon(Icons.event_note),
        label: 'Attendance',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
      if (role == Role.hod)
        const BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outline),
          activeIcon: Icon(Icons.check_circle),
          label: 'Persetujuan',
        ),
      if (role == Role.admin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined),
          activeIcon: Icon(Icons.groups),
          label: 'Kelola Tim',
        ),
    ];

    return BottomNavigationBar(
      currentIndex: activeIndex < items.length ? activeIndex : 0,
      onTap: onChanged,
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
