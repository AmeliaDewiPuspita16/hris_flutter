import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/detail_field_tile.dart';
import '../../../../core/widgets/profile_ui.dart';
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
      appBar: BackHeader(title: 'Bank Account', onBack: () => Navigator.of(context).pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Ikon sebelumnya dikomentari sehingga lingkarannya kosong;
                  // sekarang ditampilkan.
                  const TintedIcon(Icons.account_balance_outlined, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.bankName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryText.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, size: 11, color: AppColors.primaryText),
                                SizedBox(width: 4),
                                Text('Primary Salary Account', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                              ],
                            ),
                          ),
                        ),
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
                  DetailFieldTile(label: 'Account No.', value: p.bankAccountNo),
                  DetailFieldTile(label: 'Account Holder', value: p.bankAccountName, showDivider: false),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const InfoNote('Salary account changes must be requested through HR Admin.'),
          ],
        ),
      ),
    );
  }
}
