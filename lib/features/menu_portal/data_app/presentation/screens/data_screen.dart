import 'package:flutter/material.dart';

import '../../indent_vehicle/presentation/screens/indent_vehicle_screen.dart';
import '../../est_project_monitoring/presentation/screens/est_project_monitoring_screen.dart';
import '../../domain/data_demo_data.dart';
import '../../../shared/presentation/widgets/portal_category_page.dart';
import '../widgets/data_tile.dart';

/// Halaman daftar Data, dibuka dari salah satu 4 menu utama di Beranda
/// ("Record", "Data", "Online Apps", "Dashboard"). Kerangka & kartunya sama
/// dengan [RecordScreen] lewat [PortalCategoryPage] — bedanya cuma judul,
/// teks intro, dan sumber datanya.
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = DataDemoData.items(
      // null = belum siap: tile tampil redup & tidak bisa diketuk.
      onAwardRecognition: null,
      onBudgetDepartment: null,
      onCatalogKitchen: null,
      onDailyWorker: null,
      onDormitoryBie: null,
      onEstProjectMonitoring: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EstProjectMonitoringScreen()),
      ),
      onExportImport: null,
      onFacility: null,
      onFoodCost: null,
      onGymMember: null,
      onIndentVehicle: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => IndentVehicleScreen()),
      ),
      onInfrastucture: null,
    );

    return PortalCategoryPage(
      title: 'Data',
      subtitle: 'Data reference cross-department in one place.',
      children: [for (final item in items) DataTile(item: item)],
    );
  }
}
