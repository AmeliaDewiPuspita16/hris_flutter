import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../domain/pr_status.dart';
import '../../domain/procurement_demo_data.dart';
import '../../domain/purchase_requisition.dart';
import '../widgets/pr_card.dart';
import '../widgets/pr_status_filter_bar.dart';
import 'pr_detail_screen.dart';

/// Halaman Procurement Monitoring — daftar Purchase Requisition.
///
/// Versi mobile dari tabel PR di web: hanya pemantauan, tanpa "Create PR" dan
/// "Receiving". Filter Section dan rentang tanggal juga belum ikut; yang
/// dibawa baru pencarian dan filter status.
class ProcurementPage extends StatefulWidget {
  const ProcurementPage({super.key, this.requisitions});

  /// Sumber data. Dibiarkan opsional supaya repository EProcurement nanti
  /// tinggal menyuntikkan hasilnya ke sini tanpa mengubah layar; selama belum
  /// ada, jatuh ke [ProcurementDemoData].
  final List<PurchaseRequisition>? requisitions;

  @override
  State<ProcurementPage> createState() => _ProcurementPageState();
}

class _ProcurementPageState extends State<ProcurementPage> {
  final _searchController = TextEditingController();

  late final List<PurchaseRequisition> _all =
      widget.requisitions ?? ProcurementDemoData.items();

  String _query = '';

  /// Null berarti filter "Semua".
  PrStatus? _status;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(PurchaseRequisition requisition) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrDetailScreen(requisition: requisition),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pencarian dihitung lebih dulu supaya angka di chip menggambarkan hasil
    // pencarian, sementara daftar chip-nya tetap diambil dari seluruh data.
    final searched = _all.where((pr) => pr.matchesQuery(_query)).toList();
    final visible = _status == null
        ? searched
        : searched.where((pr) => pr.status == _status).toList();

    final statuses =
        PrStatus.values.where((s) => _all.any((pr) => pr.status == s)).toList();
    final counts = {
      for (final status in statuses)
        status: searched.where((pr) => pr.status == status).length,
    };

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Procurement Monitoring',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: AppTextField(
              label: 'Cari',
              controller: _searchController,
              hint: 'Nomor PR, requestor, atau purpose',
              icon: Icons.search,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          PrStatusFilterBar(
            statuses: statuses,
            counts: counts,
            totalCount: searched.length,
            selected: _status,
            onChanged: (status) => setState(() => _status = status),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text('Tidak ada data', style: AppTextStyles.bodyMuted),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => PrCard(
                      requisition: visible[i],
                      onTap: () => _openDetail(visible[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
