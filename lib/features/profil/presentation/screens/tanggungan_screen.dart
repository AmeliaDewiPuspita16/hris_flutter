import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/employee_profile.dart';

/// Padanan tab "Dependent" di modul web Employee Information.
class TanggunganScreen extends StatelessWidget {
  const TanggunganScreen({super.key, required this.profile});

  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    final list = profile.dependents;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(title: 'Tanggungan', onBack: () => Navigator.of(context).pop()),
      body: list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text('Belum ada data tanggungan terdaftar.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final d = list[i];
                return AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                        child: Text(d.name.isNotEmpty ? d.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryMid)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                            const SizedBox(height: 2),
                            Text('${d.relation} · Lahir ${d.birthDate}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}