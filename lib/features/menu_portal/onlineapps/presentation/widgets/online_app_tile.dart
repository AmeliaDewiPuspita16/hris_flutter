import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/portal_category_card.dart';
import '../../domain/online_app_item.dart';

/// Satu kartu di halaman Online Apps. Tampilannya ada di
/// [PortalCategoryCard] (dipakai bersama Records dan Data); badge-nya berisi
/// nama departemen.
class OnlineAppTile extends StatelessWidget {
  const OnlineAppTile({super.key, required this.item});

  final OnlineAppItem item;

  @override
  Widget build(BuildContext context) {
    return PortalCategoryCard(
      icon: item.icon,
      label: item.label,
      owners: [item.department],
      color: item.color,
      background: item.background,
      onTap: item.onTap,
    );
  }
}
