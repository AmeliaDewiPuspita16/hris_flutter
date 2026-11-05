import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../../../../core/widgets/detail_field_tile.dart';
import '../../domain/observation_item.dart';
import '../widgets/observation_image_view.dart';
import '../widgets/observation_status_pill.dart';

/// Detail satu observasi. Isinya sama dengan PDF "Observation Department"
/// di web (Name, To Department, Category Finding, Date, Status, Description,
/// Description Close, Close Date, Closed By, Image Finding, Image Close),
/// tapi dibaca langsung di layar.
///
/// Murni baca. Bagian Closure & Image Close hanya tampil bila observasinya
/// sudah closed. Tab My Dept Open tidak membuka layar ini.
class ObservationDetailScreen extends StatelessWidget {
  const ObservationDetailScreen({super.key, required this.item});

  final ObservationItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Observation Detail',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHero(item),
          const SizedBox(height: 14),
          _SectionCard(
            icon: Icons.info_outline,
            title: 'OBSERVATION SUMMARY',
            children: [
              _rows([
                ('Name', item.reporterName),
                ('Department', item.reporterDept),
                ('To Department', item.relevantDept),
                ('Category Finding', item.categoryLabel),
                ('Date Finding', DateFormatter.shortDate(item.createdDate)),
                ('Location', item.location),
                ('Description', item.description),
              ]),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            icon: Icons.photo_outlined,
            title: 'IMAGE FINDING',
            children: [ObservationImageView(source: item.findingImage)],
          ),
          if (!item.isOpen) ...[
            const SizedBox(height: 14),
            _SectionCard(
              icon: Icons.check_circle_outline,
              title: 'CLOSURE',
              children: [
                _rows([
                  ('Description Close', item.closeReason ?? 'N/A'),
                  (
                    'Close Date',
                    item.closeDate == null
                        ? 'N/A'
                        : DateFormatter.shortDate(item.closeDate!),
                  ),
                  ('Closed By', item.closedBy ?? 'N/A'),
                ]),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              icon: Icons.photo_outlined,
              title: 'IMAGE CLOSE',
              children: [ObservationImageView(source: item.closeImage)],
            ),
          ],
        ],
      ),
    );
  }

  Widget _rows(List<(String, String)> rows) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          DetailFieldTile(
            label: rows[i].$1,
            value: rows[i].$2,
            showDivider: i != rows.length - 1,
          ),
      ],
    );
  }

  Widget _buildHero(ObservationItem item) {
    final category = item.category;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: category.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(category.icon, size: 24, color: category.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.categoryLabel,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
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
    );
  }
}

/// Kartu putih dengan judul kecil huruf kapital + ikon, sama dengan
/// kartu section di detail IT Request.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
