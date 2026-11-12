import 'package:flutter/material.dart';

/// Pilihan di sheet "Inventory" setelah membuka tile Inventory.
enum InventoryApp { request, management }

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

/// Isi menu Inventory.
class InventoryMenuData {
  InventoryMenuData._();

  static const apps = <InventoryOption<InventoryApp>>[
    InventoryOption(
      value: InventoryApp.request,
      icon: Icons.assignment_outlined,
      title: 'Item Request',
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
}
