import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_shimmer.dart';
import '../../domain/est_approval_item.dart';
import 'est_approve_hod_card.dart';

/// Bottom sheet detail satu request di tab Approve HOD: identitas request,
/// deskripsi utuh, dan foto lampiran (kalau ada).
///
/// Sheet-nya sendiri tidak mengubah data. Dia hanya pop membawa `true`
/// (Approve) atau `false` (Reject); ditutup tanpa tombol = `null`, artinya
/// tidak ada keputusan. Pemanggil yang meneruskannya ke bloc/API.
class EstApprovalDetailSheet extends StatelessWidget {
  const EstApprovalDetailSheet({super.key, required this.item});

  final EstApprovalItem item;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, size: 18, color: AppColors.primaryText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Request Detail', style: AppTextStyles.sectionTitle),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Name', value: item.requesterName),
                    _InfoRow(label: 'Department', value: item.department),
                    _InfoRow(label: 'Type of Request', value: item.type.toUpperCase()),
                    _InfoRow(label: 'Location', value: item.location),
                    _InfoRow(label: 'Date', value: item.date),
                    _InfoRow(
                      label: 'Description',
                      value: item.description,
                      showDivider: item.imageUrl != null,
                    ),
                    if (item.imageUrl != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Photo',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _Photo(url: item.imageUrl!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: EstDecisionButton(
                      label: 'Reject',
                      icon: Icons.close,
                      filled: false,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: EstDecisionButton(
                      label: 'Approve',
                      icon: Icons.check,
                      filled: true,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto lampiran dari server. Selama memuat tampil shimmer, dan kalau
/// gagal (URL mati / tanpa jaringan) tampil kotak pengganti — bukan
/// error merah Flutter.
class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const AppShimmer(
            child: ShimmerBox(
              width: double.infinity,
              height: 200,
              borderRadius: 10,
            ),
          );
        },
        errorBuilder: (context, error, stack) => Container(
          height: 80,
          width: double.infinity,
          alignment: Alignment.center,
          color: AppColors.neutralBg,
          child: Text('Photo could not be loaded', style: AppTextStyles.caption),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.showDivider = true});

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider ? Border(bottom: BorderSide(color: AppColors.border)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
