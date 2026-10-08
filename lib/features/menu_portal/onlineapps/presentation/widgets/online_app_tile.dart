import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../shared/presentation/widgets/menu_list_tile.dart';
import '../../domain/online_app_item.dart';

/// Satu baris di halaman Online Apps: ikon, judul + departemen, dan chevron
/// di kanan. Tampilan baris sendiri ada di [MenuListTile] — di sini cuma
/// menentukan subtitle-nya berupa nama departemen.
class OnlineAppTile extends StatelessWidget {
  const OnlineAppTile({super.key, required this.item});

  final OnlineAppItem item;

  @override
  Widget build(BuildContext context) {
    return MenuListTile(
      icon: item.icon,
      label: item.label,
      color: item.color,
      background: item.background,
      onTap: item.onTap,
      subtitle: Text(
        item.department,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textMuted
        ),
      )
    );
  }
}
