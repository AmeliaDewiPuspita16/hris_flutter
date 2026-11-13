import 'package:flutter/material.dart';

/// Pilihan di sheet "Inventory" setelah membuka tile Inventory.
enum InventoryApp { request, management }

/// Kartu di halaman "Management". Baru tiga; yang lain (Master Data, User
/// Access, My Stores, Project Plans, Scrap, Audit Log) menyusul.
enum InventoryManagement { stockOpname, myCategories, myItems }

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
    ),
  ];

  /// Isi halaman Management, urutannya sama dengan di web.
  ///
  /// Menonaktifkan sebuah fitur: ubah `ready` jadi false (kartu jadi redup
  /// dengan label "Coming soon" dan tidak bisa diketuk), atau hapus barisnya
  /// kalau mau disembunyikan sama sekali.
  static const management = <InventoryOption<InventoryManagement>>[
    InventoryOption(
      value: InventoryManagement.stockOpname,
      icon: Icons.fact_check_outlined,
      title: 'Stock Opname',
      subtitle: 'Count and adjust stock',
    ),
    InventoryOption(
      value: InventoryManagement.myCategories,
      icon: Icons.sell_outlined,
      title: 'My Categories',
      subtitle: 'Who handles each category',
    ),
    InventoryOption(
      value: InventoryManagement.myItems,
      icon: Icons.inventory_2_outlined,
      title: 'My Items',
      subtitle: 'Items, stock and operations',
    ),
  ];
}
