import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/portal_category_card.dart';
import '../../domain/record_item.dart';

/// Satu kartu kategori di halaman Records. Tampilannya ada di
/// [PortalCategoryCard] (dipakai bersama halaman Data).
class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.item});

  final RecordItem item;

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
