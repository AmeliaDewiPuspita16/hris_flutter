import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/menu_list_tile.dart';
import '../../../shared/presentation/widgets/owner_badge_row.dart';
import '../../domain/record_item.dart';

/// Satu baris di halaman Records: ikon, judul + badge owner (bisa lebih
/// dari satu), dan chevron di kanan. Tampilan baris sendiri ada di
/// [MenuListTile] — di sini cuma menentukan subtitle-nya berupa
/// [OwnerBadgeRow].
class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.item});

  final RecordItem item;

  @override
  Widget build(BuildContext context) {
    return MenuListTile(
      icon: item.icon,
      label: item.label,
      color: item.color,
      background: item.background,
      onTap: item.onTap,
      subtitle: OwnerBadgeRow(owners: item.owners),
    );
  }
}
