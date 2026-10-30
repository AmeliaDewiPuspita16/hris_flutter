import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/detail_field_tile.dart';
import '../../../../core/widgets/profile_ui.dart';
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
      appBar: BackHeader(title: 'Employment Contract', onBack: () => Navigator.of(context).pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nomor kontrak diangkat jadi kartu ringkasan di atas.
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const TintedIcon(Icons.description_outlined, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contract No.', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(p.contractNo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SectionLabel('CONTRACT DETAILS'),
                ReadOnlyBadge(),
              ],
            ),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  DetailFieldTile(label: 'Position', value: p.title),
                  DetailFieldTile(label: 'Department', value: p.dept),
                  DetailFieldTile(label: 'Join Date', value: p.join),
                  DetailFieldTile(label: 'Employee Category', value: p.employeeCategory, showDivider: false),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const InfoNote('Contract data is managed by HR. Contact HR Admin to request changes.'),
          ],
        ),
      ),
    );
  }
}
