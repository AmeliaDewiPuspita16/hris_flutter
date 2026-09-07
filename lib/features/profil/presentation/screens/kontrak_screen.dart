import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/detail_field_tile.dart';
import '../../domain/employee_profile.dart';

/// Padanan tab "Contract" di modul web Employee Information.
class KontrakScreen extends StatelessWidget {
  const KontrakScreen({super.key, required this.profile});

  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(title: 'Kontrak Kerja', onBack: () => Navigator.of(context).pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  DetailFieldTile(label: 'No. Kontrak', value: p.contractNo),
                  DetailFieldTile(label: 'Jabatan', value: p.title),
                  DetailFieldTile(label: 'Departemen', value: p.dept),
                  DetailFieldTile(label: 'Tanggal Bergabung', value: p.join),
                  DetailFieldTile(label: 'Kategori Pegawai', value: p.employeeCategory, showDivider: false),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('🔒 Data kontrak dikelola oleh HR. Hubungi Admin HR untuk perubahan.', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }
}