import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../procurement/presentation/screens/procurement_page.dart';
import '../../domain/online_apps_demo_data.dart';
import '../../domain/request_type.dart';
import '../widgets/choose_request_type_sheet.dart';
import '../widgets/online_app_tile.dart';
import 'it_request_screen.dart';

/// Halaman daftar Online Apps, dibuka dari salah satu 4 menu utama di
/// Beranda ("Record", "Data", "Online Apps", "Dashboard").
///
/// Dipush sebagai halaman baru (bukan tab Beranda), jadi bottom nav HRIS
/// tidak ikut terbawa — sesuai pola "pindah page tanpa mempertahankan
/// bottom nav" untuk keempat menu utama portal.
class OnlineAppsScreen extends StatelessWidget {
  const OnlineAppsScreen({super.key});

  /// Placeholder untuk app yang belum punya halamannya sendiri.
  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label belum tersedia')),
    );
  }

  /// "Work Order" punya 2 sub-pilihan (IT / EST Request), jadi tampil lewat
  /// bottom sheet dulu sebelum pindah ke form yang sesuai — form-nya sendiri
  /// belum dibuat di iterasi ini, jadi untuk sementara jatuh ke placeholder.
  Future<void> _openWorkOrder(BuildContext context) async {
    final type = await showModalBottomSheet<RequestType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChooseRequestTypeSheet(),
    );

    if (type == null || !context.mounted) return;

    switch (type) {
      case RequestType.it:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ItRequestScreen()),
        );
      case RequestType.est:
        _showComingSoon(context, 'Form EST Request');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = OnlineAppsDemoData.items(
      onInventory: () => _showComingSoon(context, 'Inventory'),
      onMeterReading: () => _showComingSoon(context, 'Meter Reading'),
      onReservation: () => _showComingSoon(context, 'Reservation'),
      onProcurement: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProcurementPage()),
      ),
      onTenantFeedback: () => _showComingSoon(context, 'Tenant Feedback'),
      onWorkOrder: () => _openWorkOrder(context),
      onHseWorkRequest: () => _showComingSoon(context, 'HSE Work Request'),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Online Apps',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              'ECOSYSTEM',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16, left: 4),
            child: Text(
              'Akses tools operasional dan sistem manajemen internal.',
              style: AppTextStyles.bodyMuted,
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            OnlineAppTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}
