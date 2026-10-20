import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../domain/approve_request_item.dart';

/// Kartu satu permintaan yang menunggu keputusan di tab "Approve Request".
///
/// Susunan dari atas: avatar inisial + nama + departemen (kiri) dan pill
/// Support Type (kanan); isi permintaan utuh (tidak dipotong) di kotak abu
/// lembut; lalu dua tombol sama besar — Reject
/// outline merah dan Approve hijau penuh — supaya keduanya jelas terbaca
/// sebagai tombol.
class ApproveRequestCard extends StatelessWidget {
  const ApproveRequestCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final ApproveRequestItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  /// Huruf depan kata pertama dan terakhir nama, mis. 'Rika Susila Susanti'
  /// -> 'RS'. Kosong -> '?'.
  String get _initials {
    final parts = item.requesterName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final supportType = item.supportType;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(initials: _initials),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.requesterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.business_outlined,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.department,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (supportType != null) ...[
                const SizedBox(width: 8),
                _SupportTypePill(label: supportType),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.neutralBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.description,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                height: 1.5,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: Text(
                      'Reject',
                      style: AppTextStyles.buttonText.copyWith(
                        color: AppColors.rejected,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rejected,
                      side: const BorderSide(color: AppColors.rejected),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      'Approve',
                      style: AppTextStyles.buttonText.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Pill jenis dukungan: biru untuk IT, ungu untuk Media.
class _SupportTypePill extends StatelessWidget {
  const _SupportTypePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isMedia = label.toLowerCase().startsWith('media');
    final color = isMedia ? AppColors.violet : AppColors.itRequest;
    final background = isMedia ? AppColors.violetBg : AppColors.itRequestBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
