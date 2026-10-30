import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../domain/online_apps_demo_data.dart';
import '../../procurement/presentation/screens/procurement_page.dart';
import '../../hse_work_request/presentation/screens/hse_work_request_list_screen.dart';
import '../../work_order/domain/request_type.dart';
import '../../work_order/est_request/presentation/screens/est_request_screen.dart';
import '../../work_order/it_request/presentation/screens/it_request_screen.dart';
import '../../work_order/presentation/widgets/choose_request_type_sheet.dart';
import '../../../shared/presentation/widgets/portal_category_page.dart';
import '../widgets/online_app_tile.dart';

/// Halaman daftar Online Apps, dibuka dari salah satu 4 menu utama di
/// Beranda ("Record", "Data", "Online Apps", "Dashboard").
class OnlineAppsScreen extends StatelessWidget {
  const OnlineAppsScreen({super.key});

  /// "Work Order" punya 2 sub-pilihan (IT / EST Request), jadi tampil lewat
  /// bottom sheet dulu sebelum pindah ke halaman yang sesuai.
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
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EstRequestScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Procurement Monitoring hanya untuk user ber-role epro-*. Tanpa sesi
    // (user null) menu disembunyikan.
    final user = context.read<AuthBloc>().state.session?.user;

    final items = OnlineAppsDemoData.items(
      showProcurement: user?.canAccessProcurement ?? false,
      // null = belum siap: tile tampil redup & tidak bisa diketuk.
      onInventory: null,
      onMeterReading: null,
      onReservation: null,
      onProcurement: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProcurementPage()),
      ),
      onTenantFeedback: null,
      onWorkOrder: () => _openWorkOrder(context),
      onHseWorkRequest: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HseWorkRequestListScreen()),
      ),
    );

    return PortalCategoryPage(
      title: 'Online Apps',
      subtitle: 'Akses tools operasional dan sistem manajemen internal.',
      illustrationAsset: PortalCategoryPage.monitorIllustration,
      sectionLabel: 'ECOSYSTEM',
      children: [for (final item in items) OnlineAppTile(item: item)],
    );
  }
}
