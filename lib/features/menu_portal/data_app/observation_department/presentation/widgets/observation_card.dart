import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/observation_item.dart';
import 'observation_status_pill.dart';

/// Satu baris di daftar Observation — mengemas kolom tabel web (Created
/// Date, Name - Dept, Category, Location, Relevant Dept, Description,
/// Status, Actions) jadi satu kartu ringkas, sama seperti `IndentRequestRow`.
///
/// Urutan: kategori + tanggal + status (utama) → lokasi & pelapor →
/// deskripsi → dept tujuan + aksi (Close bila boleh, kalau tidak "Details").
class ObservationCard extends StatelessWidget {
  const ObservationCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onClose,
  });

  final ObservationItem item;
  final VoidCallback onTap;

  /// Tombol Close hanya tampil bila [ObservationItem.canClose] dan callback
  /// ini diisi.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final category = item.category;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: kategori, tanggal, status
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: category.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(category.icon, size: 20, color: category.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.categoryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.shortDate(item.createdDate),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ObservationStatusPill(status: item.status),
            ],
          ),
          const SizedBox(height: 10),

          // Baris 2-3: lokasi & pelapor
          _InfoLine(icon: Icons.place_outlined, text: item.location),
          const SizedBox(height: 4),
          _InfoLine(icon: Icons.person_outline, text: item.reporter),
          const SizedBox(height: 8),

          // Baris 4: deskripsi
          Text(
            item.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Baris 5: dept tujuan + aksi
          Row(
            children: [
              Icon(Icons.apartment_outlined,
                  size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'To  ', style: AppTextStyles.caption),
                      TextSpan(
                        text: item.relevantDept,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.canClose && onClose != null)
                _CloseButton(onTap: onClose!)
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Details',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.primaryText),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: AppColors.textMuted),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMid),
          ),
        ),
      ],
    );
  }
}

/// Tombol "Close" kecil — outline hijau seperti tombol Close di tabel web.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 15, color: AppColors.primaryText),
            const SizedBox(width: 5),
            Text(
              'Close',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
