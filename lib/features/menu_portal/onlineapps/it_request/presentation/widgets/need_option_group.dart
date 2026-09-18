import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/need_option.dart';

/// Daftar "What do you need?": baris-baris yang menempel jadi satu grup
/// tanpa jarak sama sekali, dan HANYA baris yang sedang dipilih yang
/// "keluar" dari grup dengan jarak di atas & bawah plus border hijau —
/// opsi yang belum dipilih tetap ringkas, opsi yang dipilih (beserta field
/// tambahannya, kalau ada) jelas menonjol.
///
/// Menggantikan pola lama di mana setiap opsi adalah kartu terpisah dengan
/// jarak yang sama rata, yang terasa terlalu kaku/berjarak.
class NeedOptionGroup extends StatelessWidget {
  const NeedOptionGroup({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelect,
    required this.expandedChildBuilder,
  });

  final List<NeedOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  /// Dipanggil untuk opsi yang sedang terpilih untuk merender field
  /// tambahannya (chip pilihan, text field, atau sub-form) — null berarti
  /// opsi itu tidak punya field tambahan.
  final Widget? Function(NeedOption option) expandedChildBuilder;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = options.indexWhere((o) => o.id == selectedId);

    if (selectedIndex == -1) {
      // Belum ada yang dipilih — semua baris nempel jadi satu grup.
      return _OptionGroupCard(
          options: options, selectedId: null, onSelect: onSelect);
    }

    final before = options.sublist(0, selectedIndex);
    final selected = options[selectedIndex];
    final after = options.sublist(selectedIndex + 1);
    final expandedChild = expandedChildBuilder(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (before.isNotEmpty) ...[
          _OptionGroupCard(
              options: before, selectedId: null, onSelect: onSelect),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OptionRow(
                  option: selected,
                  selected: true,
                  onTap: () => onSelect(selected.id)),
              if (expandedChild != null) ...[
                // Pemisah antara judul/deskripsi opsi dan field tambahannya
                // di bawah, supaya jelas ini bagian yang berbeda — bukan
                // menyambung begitu saja.
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                  indent: 60,
                  endIndent: 16,
                ),
                // Divider(height: 1, thickness: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(60, 12, 14, 14),
                  child: expandedChild,
                ),
              ],
            ],
          ),
        ),
        if (after.isNotEmpty) ...[
          const SizedBox(height: 8),
          _OptionGroupCard(
              options: after, selectedId: null, onSelect: onSelect),
        ],
      ],
    );
  }
}

/// Satu grup baris yang menempel (tidak ada opsi terpilih di dalamnya).
class _OptionGroupCard extends StatelessWidget {
  const _OptionGroupCard({
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  final List<NeedOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.border.withValues(alpha: 0.7),
                // indent: 600,
                // endIndent: 12,
              ),
            _OptionRow(
              option: options[i],
              selected: options[i].id == selectedId,
              onTap: () => onSelect(options[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ikon + subjudul singkat per opsi, dicocokkan dari teks labelnya supaya
/// tidak perlu menambah field baru di [NeedOption]. Kalau ada label baru
/// yang belum kena mapping di sini, ikon jatuh ke [Icons.more_horiz] dan
/// subjudulnya jatuh ke deskripsi generik.
({IconData icon, String description}) _metaFor(NeedOption option) {
  final label = option.label.toLowerCase();
  if (label.contains('new employee')) {
    return (
      icon: Icons.person_add_alt_outlined,
      description: 'Opens an 8-field form'
    );
  }
  if (label.contains('account creation')) {
    return (
      icon: Icons.person_outline,
      description: 'Existing employee, no account yet'
    );
  }
  if (label.contains('account management')) {
    return (
      icon: Icons.lock_outline,
      description: 'Update login, username, role, or deactivate',
    );
  }
  if (label.contains('network') || label.contains('internet')) {
    return (icon: Icons.wifi, description: 'Connectivity issue or new access');
  }
  if (label.contains('backup')) {
    return (
      icon: Icons.backup_outlined,
      description: 'Weekly scheduled data backup'
    );
  }
  if (label.contains('download') || label.contains('install')) {
    return (
      icon: Icons.file_download_outlined,
      description: 'Tell us which application you need',
    );
  }
  if (label.contains('hardware') || label.contains('computer')) {
    return (
      icon: Icons.desktop_windows_outlined,
      description: 'Laptop, PC, printer, mouse'
    );
  }
  if (label.contains('event') || label.contains('meeting')) {
    return (
      icon: Icons.cast_outlined,
      description: 'Projector, pointer, videotron, webcam'
    );
  }
  if (label.contains('design')) {
    return (
      icon: Icons.palette_outlined,
      description: 'Poster, banner, streamer, logo'
    );
  }
  if (label.contains('documentation')) {
    return (
      icon: Icons.photo_camera_outlined,
      description: 'Photo or video coverage'
    );
  }
  if (label.contains('print')) {
    return (icon: Icons.print_outlined, description: 'ID card, certificate');
  }
  if (label.contains('social')) {
    return (icon: Icons.share_outlined, description: 'Instagram, WhatsApp');
  }
  return (icon: Icons.more_horiz, description: 'Tell us what you need');
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final NeedOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(option);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Box for icon
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                meta.icon,
                size: 17,
                color: selected ? AppColors.primary : AppColors.textMuted
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.label,
                    style: AppTextStyles.body.copyWith(
                      // fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      fontWeight: FontWeight.w600, // selalu bold
                      fontSize: 14.5,
                    ),
                  ),
                  if (meta.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(meta.description, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Circle indikator — ukuran & border sedikit lebih tegas.
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
