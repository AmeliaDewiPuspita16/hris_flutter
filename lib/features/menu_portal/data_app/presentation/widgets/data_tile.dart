import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/portal_category_card.dart';
import '../../domain/data_item.dart';

/// Satu kartu kategori di halaman Data. Tampilannya ada di
/// [PortalCategoryCard] (dipakai bersama halaman Records).
class DataTile extends StatelessWidget {
  const DataTile({super.key, required this.item});

  final DataItem item;

  @override
  Widget build(BuildContext context) {
    return PortalCategoryCard(
      icon: item.icon,
      label: item.label,
      owners: item.owners,
      color: item.color,
      background: item.background,
      onTap: item.onTap,
    );
  }
}
