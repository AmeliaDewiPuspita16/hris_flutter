import 'package:material_ui/material_ui.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/opname_formatters.dart';
import '../../domain/opname_record.dart';
import 'opname_text_styles.dart';

/// Bagian atas detail opname: label kecil, kode opname, lalu pil status,
/// tanggal, dan nama penghitung.
class OpnameDetailHeader extends StatelessWidget {
  final OpnameDetail detail;

  const OpnameDetailHeader({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STOCK OPNAME',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          d.code,
          style: OpnameTextStyles.title.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusPill(status: d.status),
            _InfoPill(
              icon: Icons.calendar_today_outlined,
              text: d.date == null ? '-' : formatShortDate(d.date!),
            ),
            _InfoPill(icon: Icons.person_outline, text: d.countedBy),
          ],
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final OpnameStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, label, fg, bg) = switch (status) {
      OpnameStatus.draft => (
          Icons.edit_note_rounded,
          'Draft',
          AppColors.pending,
          AppColors.pending.withValues(alpha: 0.14),
        ),
      OpnameStatus.confirmed => (
          Icons.verified_rounded,
          'Confirmed',
          AppColors.present,
          AppColors.presentBg,
        ),
      OpnameStatus.other => (
          Icons.help_outline_rounded,
          'Unknown',
          AppColors.textMuted,
          AppColors.neutralBg,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.primaryText),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Jumlah baris yang sudah dihitung, dan berapa di antaranya surplus atau
/// kekurangan. Dihitung per baris, bukan dijumlahkan, karena satuan barangnya
/// bisa berbeda.
typedef OpnameStats = ({int counted, int surplus, int shortage});

OpnameStats opnameStatsOf(OpnameDetail d) {
  final counted = d.items.where((e) => e.isCounted).toList();
  return (
    counted: counted.length,
    surplus: counted.where((e) => (e.difference ?? 0) > 0).length,
    shortage: counted.where((e) => (e.difference ?? 0) < 0).length,
  );
}

/// Hasil sekilas: counted, surplus, dan shortage sebagai tiga angka besar
/// dalam satu kartu.
class OpnameStatsCard extends StatelessWidget {
  final OpnameStats stats;

  const OpnameStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final divider = Container(width: 1, height: 40, color: AppColors.border);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.fact_check_outlined,
              value: stats.counted,
              label: 'Counted',
              color: AppColors.primaryText,
              background: AppColors.primaryLight,
            ),
          ),
          divider,
          Expanded(
            child: _StatTile(
              icon: Icons.arrow_upward_rounded,
              value: stats.surplus,
              label: 'Surplus',
              color: OpnameTextStyles.success,
              background: AppColors.presentBg,
            ),
          ),
          divider,
          Expanded(
            child: _StatTile(
              icon: Icons.arrow_downward_rounded,
              value: stats.shortage,
              label: 'Shortage',
              color: AppColors.rejected,
              background: AppColors.rejectedBg,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final Color background;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

/// "N counted · N surplus · N shortage" sebagai tiga pil kecil. Dipakai di
/// bar tombol bawah, di sebelah tombol Confirm.
class OpnameStatsChips extends StatelessWidget {
  final OpnameStats stats;

  const OpnameStatsChips({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, String text, Color fg, Color bg) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        chip(
          Icons.fact_check_outlined,
          '${stats.counted} counted',
          AppColors.primaryText,
          AppColors.card,
        ),
        chip(
          Icons.arrow_upward_rounded,
          '${stats.surplus} surplus',
          OpnameTextStyles.success,
          AppColors.presentBg,
        ),
        chip(
          Icons.arrow_downward_rounded,
          '${stats.shortage} shortage',
          AppColors.rejected,
          AppColors.rejectedBg,
        ),
      ],
    );
  }
}
