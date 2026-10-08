import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/menu_list_tile.dart';
import '../../../shared/presentation/widgets/owner_badge_row.dart';
import '../../domain/data_item.dart';

/// Satu baris di halaman Data: ikon, judul + badge owner, dan chevron di
/// kanan. Pola sama persis dengan `RecordTile` — tampilan baris sendiri
/// ada di [MenuListTile], di sini cuma menentukan subtitle-nya berupa
/// [OwnerBadgeRow].
class DataTile extends StatelessWidget {
  const DataTile({super.key, required this.item});

  final DataItem item;

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
