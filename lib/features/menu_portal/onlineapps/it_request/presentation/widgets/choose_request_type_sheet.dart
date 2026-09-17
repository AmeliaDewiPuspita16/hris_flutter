import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/request_type.dart';

/// Bottom sheet "Choose request type" saat user membuka Work Order.
///
/// Cuma dua opsi tetap (IT Request / EST Request) sehingga cukup sebagai
/// sheet, bukan halaman baru — mengikuti modal "Choose App" di versi web.
/// Mengembalikan [RequestType] yang dipilih lewat Navigator.pop, atau null
/// kalau ditutup tanpa memilih.
class ChooseRequestTypeSheet extends StatelessWidget {
  const ChooseRequestTypeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Choose request type', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Icons.desktop_windows_outlined,
              color: AppColors.primary,
              background: AppColors.primaryLight,
              title: 'IT Request',
              subtitle: 'Design, photo, troubleshooting PC, etc.',
              onTap: () => Navigator.of(context).pop(RequestType.it),
            ),
            const SizedBox(height: 10),
            _OptionTile(
              icon: Icons.apartment_outlined,
              color: AppColors.accent,
              background: AppColors.accentBg,
              title: 'EST Request',
              subtitle: 'Repairs, building problems, etc.',
              onTap: () => Navigator.of(context).pop(RequestType.est),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}