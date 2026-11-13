import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/inventory_menu.dart';
import '../../stock_opname/presentation/screens/opname_home_screen.dart';
import '../widgets/inventory_management_card.dart';

/// Halaman "Management" di modul Inventory: kartu fitur pengelolaan
/// (`InventoryMenuData.management`) dalam grid dua kolom. Dibuka dari sheet
/// Inventory saat memilih Management.
///
/// Tampilannya mengikuti layar HSE Work Permit: top bar kecil (tombol kembali
/// dan judul di tengah) di atas gambar latar, tanpa ilustrasi.
///
/// Layar tujuan tiap kartu belum dibuat, jadi ketukan sementara hanya
/// menampilkan snackbar. Sambungkan di [_open] begitu layarnya siap.
class InventoryManagementScreen extends StatelessWidget {
  const InventoryManagementScreen({super.key});

  static const double _gap = 12;

  /// Jumlah kartu per baris. 2 = kartu lapang dengan keterangan penuh; 3 =
  /// kartu ringkas (`dense`) yang muat banyak menu, cocok bila fitur
  /// Management sudah bertambah.
  static const int _columns = 3;

  /// Tinggi gambar latar di bawah status bar. Ujung bawahnya dipudarkan ke
  /// warna halaman.
  static const double _backdropHeight = 200;

  /// Warna tiap fitur, diambil dari palet Online Apps. Fitur baru tinggal
  /// menambah satu baris.
  InventoryManagementTone _tone(InventoryManagement target) {
    switch (target) {
      case InventoryManagement.stockOpname:
        return InventoryManagementTone.green;
      case InventoryManagement.myCategories:
        return InventoryManagementTone.gold;
      case InventoryManagement.myItems:
        return InventoryManagementTone.coral;
    }
  }

  void _open(
    BuildContext context,
    InventoryOption<InventoryManagement> option,
  ) {
    switch (option.value) {
      case InventoryManagement.stockOpname:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OpnameHomeScreen()),
        );
      case InventoryManagement.myCategories:
        // TODO: Navigator.push ke layar My Categories bila sudah ada.
        _comingSoon(context, option);
      case InventoryManagement.myItems:
        // TODO: Navigator.push ke layar My Items bila sudah ada.
        _comingSoon(context, option);
    }
  }

  void _comingSoon(
    BuildContext context,
    InventoryOption<InventoryManagement> option,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${option.title} is not available yet')),
    );
  }

  Widget _card(
    BuildContext context,
    InventoryOption<InventoryManagement> option,
  ) {
    return InventoryManagementCard<InventoryManagement>(
      option: option,
      tone: _tone(option.value),
      dense: _columns >= 3,
      onTap: () => _open(context, option),
    );
  }

  @override
  Widget build(BuildContext context) {
    const options = InventoryMenuData.management;
    final topInset = MediaQuery.paddingOf(context).top;

    // [_columns] kartu per baris; IntrinsicHeight + stretch menyamakan tinggi
    // kartu satu baris walau panjang keterangannya beda. Sisa kolom di baris
    // terakhir diisi ruang kosong supaya lebar kartunya tetap sama.
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += _columns) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var c = 0; c < _columns; c++) ...[
                if (c > 0) const SizedBox(width: _gap),
                Expanded(
                  child: i + c < options.length
                      ? _card(context, options[i + c])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
      rows.add(const SizedBox(height: _gap));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Latar terang, jadi ikon status bar harus gelap.
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            AppColors.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            AppColors.isDark ? Brightness.dark : Brightness.light,
      ),
      child: DecoratedBox(
        decoration: AppColors.portalBackdrop,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Gambar latar hanya untuk mode terang; mode gelap memakai
              // `portalBackdrop` saja.
              if (!AppColors.isDark) ...[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topInset + _backdropHeight,
                  child: SvgPicture.asset(
                    'assets/icons/header-background.svg',
                    fit: BoxFit.cover,
                  ),
                ),
                // Memudarkan ujung bawah gambar ke warna halaman supaya tidak
                // ada garis sambungan.
                Positioned(
                  top: topInset + _backdropHeight - 40,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.bg.withValues(alpha: 0),
                          AppColors.bg,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _TopBar(title: 'Management'),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          24 + MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 14),
                            child: Text(
                              'Choose what you want to manage.',
                              style: AppTextStyles.bodyMuted
                                  .copyWith(fontSize: 12.5),
                            ),
                          ),
                          ...rows,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris atas: tombol kembali bulat dan judul hijau di tengah. Lebar kosong
/// di kanan menyamai tombol kembali supaya judul tepat di tengah.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Material(
            color: AppColors.card,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black12,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              customBorder: const CircleBorder(),
              child: Tooltip(
                message: 'Back',
                child: SizedBox.square(
                  dimension: 44,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox.square(dimension: 44),
        ],
      ),
    );
  }
}
