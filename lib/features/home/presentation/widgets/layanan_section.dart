import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/service_shortcut.dart';

/// Grid pintasan layanan. Jumlah item berbeda per role, jadi dipakai [Wrap]
/// supaya barisnya menyesuaikan sendiri.
class LayananSection extends StatelessWidget {
  const LayananSection({super.key, required this.services});

  final List<ServiceShortcut> services;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Layanan', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final service in services) _ServiceTile(service: service),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service});

  final ServiceShortcut service;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: service.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: service.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(service.icon, size: 20, color: service.color),
              ),
              const SizedBox(height: 6),
              Text(
                service.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
