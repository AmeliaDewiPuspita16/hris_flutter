import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/profile_ui.dart';
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TintedIcon(Icons.family_restroom_outlined, size: 56),
                    SizedBox(height: 14),
                    Text(
                      'Belum ada data tanggungan terdaftar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              // +1 untuk baris judul di paling atas.
              itemCount: list.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionLabel('TERDAFTAR'),
                      InfoPill('${list.length} orang'),
                    ],
                  );
                }
                final d = list[i - 1];
                return AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          d.name.isNotEmpty ? d.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(d.relation, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text('Lahir ${d.birthDate}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                                ),
                              ],
                            ),
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
