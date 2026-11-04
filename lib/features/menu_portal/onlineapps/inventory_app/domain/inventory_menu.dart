import 'package:flutter/material.dart';

/// Pilihan di sheet "Choose App" setelah membuka tile Inventory.
enum InventoryApp { request, management }

/// Pilihan di sheet "Request" (product line yang bisa di-request).
enum InventoryProductLine { stationery, estateBuilding }

/// Satu baris pilihan di [InventoryOptionSheet].
///
/// [ready] false = fitur belum ada di aplikasi: baris tampil redup dengan
/// label "Coming soon" dan tidak bisa diketuk (sama seperti web).
class InventoryOption<T> {
  const InventoryOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ready = true,
  });

  final T value;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool ready;
}

/// Isi menu Inventory, mengikuti web (Home / Inventory / Request).
class InventoryMenuData {
  InventoryMenuData._();

  static const apps = <InventoryOption<InventoryApp>>[
    InventoryOption(
      value: InventoryApp.request,
      icon: Icons.assignment_outlined,
      title: 'Request',
      subtitle: 'Request items from stock.',
    ),
    InventoryOption(
      value: InventoryApp.management,
      icon: Icons.settings_outlined,
      title: 'Management',
      subtitle: 'Manage items, stock in/out, and master data.',
      ready: false,
    ),
  ];

  static const productLines = <InventoryOption<InventoryProductLine>>[
    InventoryOption(
      value: InventoryProductLine.stationery,
      icon: Icons.create_outlined,
      title: 'Stationery',
      subtitle: 'Office stationery items, stock, and requests.',
    ),
    // InventoryOption(
    //   value: InventoryProductLine.uniform,
    //   icon: Icons.checkroom_outlined,
    //   title: 'Uniform',
    //   subtitle: 'Uniform items, stock, and requests.',
    //   ready: false,
    // ),
    InventoryOption(
      value: InventoryProductLine.estateBuilding,
      icon: Icons.apartment_outlined,
      title: 'Estate Building',
      subtitle: 'Estate building items, stock, and project material requests.',
      ready: false,
    ),
  ];
}
