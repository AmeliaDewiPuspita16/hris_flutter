import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/back_header.dart';
import '../../domain/data_demo_data.dart';
import '../widgets/data_tile.dart';

/// Halaman daftar Data, dibuka dari salah satu 4 menu utama di Beranda
/// ("Record", "Data", "Online Apps", "Dashboard"). Strukturnya sama persis
/// [RecordScreen] — bedanya cuma judul, teks intro, dan sumber datanya.
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  /// Placeholder untuk kategori yang belum punya halamannya sendiri.
  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label belum tersedia')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = DataDemoData.items(
      onAwardRecognition: () => _showComingSoon(context, 'Award & Recognition'),
      onBudgetDepartment: () => _showComingSoon(context, 'Budget Department'),
      onCatalogKitchen: () => _showComingSoon(context, 'Catalog Kitchen'),
      onDailyWorker: () => _showComingSoon(context, 'Daily Worker'),
      onDormitoryBie: () => _showComingSoon(context, 'Dormitory BIE'),
      onEstProjectMonitoring: () => _showComingSoon(context, 'EST Project Monitoring'),
      onExportImport: () => _showComingSoon(context, 'Export Import'),
      onFacility: () => _showComingSoon(context, 'Facility'),
      onFoodCost: () => _showComingSoon(context, 'Food Cost'),
      onGymMember: () => _showComingSoon(context, 'Gym Member'),
      onIndentVehicle: () => _showComingSoon(context, 'Indent Vehicle'),
      onInfrastucture: () => _showComingSoon(context, 'Infrastucture'),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Data',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              'REFERENCE',
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
              'Data referensi lintas departemen di satu tempat.',
              style: AppTextStyles.bodyMuted,
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            DataTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}
