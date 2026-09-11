import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/detail_field_tile.dart';
import '../../domain/employee_profile.dart';

/// Padanan tab "Bank Account" di modul web Employee Information.
class RekeningScreen extends StatelessWidget {
  const RekeningScreen({super.key, required this.profile});

  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(title: 'Rekening Bank', onBack: () => Navigator.of(context).pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                    // child: const Icon(Icons.account_balance_outlined, color: AppColors.primaryMid),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.bankName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
                        const SizedBox(height: 2),
                        const Text('Rekening Gaji Utama', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  DetailFieldTile(label: 'No. Rekening', value: p.bankAccountNo),
                  DetailFieldTile(label: 'Nama Pemilik', value: p.bankAccountName, showDivider: false),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('🔒 Perubahan rekening gaji wajib melalui pengajuan ke HR Admin.', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }
}