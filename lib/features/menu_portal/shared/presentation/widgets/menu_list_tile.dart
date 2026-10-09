import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_card.dart';

/// satu baris di halaman daftar menu portal (Online Apps, Record, Data):
/// ikon kotak, label, baris subtitle bebas bentuknya, dan chevron di kanan.
///
/// [subtitle] sengaja berupa [widget], bukan [String] - Online Apps
/// menaruh 'Text' nama department, Record dan Data menaruh
/// [OwnerBadgeRow]. Tile punya fitur lain, bikin widget baru yang
/// membungkus ini (seperti [OnlineAppTile]/[RecordTile]), jangan tambah
/// parameter opsional di sini.
class MenuListTile extends StatelessWidget {
  const MenuListTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final Widget subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                subtitle,
              ],
            )
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textMuted
          )
        ],
      ),
    );
  }
}
