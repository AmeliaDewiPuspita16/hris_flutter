import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/hris_menu_item.dart';

enum _ViewMode { grid, list }

/// Warna bar judul section (Attendance, Leave & Time Off, dst).
///
/// Ganti nilai [HrisMenuScreen.sectionBarStyle] untuk membandingkan; tidak
/// ada bagian lain yang perlu diubah.
enum HrisSectionBarStyle {
  /// Semua section bar hijau (warna utama app) — versi awal.
  emerald,

  /// Semua section bar abu-abu netral, sama rata — mengikuti gaya aplikasi
  /// HRIS referensi (semua judul section satu warna, tidak menonjolkan
  /// kategori tertentu).
  neutral,

  /// Tiap section bar mengikuti warna aksen grupnya sendiri (Attendance =
  /// teal, Leave & Time Off = emas, Employee = ungu, Team = hijau) — sama
  /// dengan warna ikon di dalamnya, supaya kelompok gampang dibedakan
  /// sekilas saat di-scroll.
  categorized,
}

/// Tab "HRIS": pintu masuk ke semua fitur kepegawaian, dikelompokkan dan
/// bisa dicari — polanya mengikuti "Menu Features" pada aplikasi HRIS
/// referensi (search bar di atas, judul section sebagai bar penuh, toggle
/// tampilan grid/list).
///
/// Layar ini tidak tahu apa-apa soal fitur; ia hanya menampilkan [items]
/// yang lolos [HrisMenuItem.isVisible], lalu menyaringnya lagi lewat kotak
/// pencarian. Daftar itemnya ada di `HrisMenuConfig`.
class HrisMenuScreen extends StatefulWidget {
  const HrisMenuScreen({
    super.key,
    required this.items,
    required this.menuContext,
    this.showNotReady = true,
    this.sectionBarStyle = HrisSectionBarStyle.neutral,
  });

  final List<HrisMenuItem> items;
  final HrisMenuContext menuContext;

  /// True (default) = item yang belum siap tetap ditampilkan, redup dan
  /// berlabel "Soon", supaya struktur menu terlihat lengkap seperti
  /// checklist requirement. Set false untuk menyembunyikannya sama sekali.
  final bool showNotReady;

  /// Lihat [HrisSectionBarStyle]. Ganti di sini untuk mencoba versi warna
  /// lain, mis. `HrisMenuScreen(..., sectionBarStyle: HrisSectionBarStyle.neutral)`.
  final HrisSectionBarStyle sectionBarStyle;

  @override
  State<HrisMenuScreen> createState() => _HrisMenuScreenState();
}

class _HrisMenuScreenState extends State<HrisMenuScreen> {
  _ViewMode _mode = _ViewMode.grid;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HrisMenuItem> get _visible {
    final query = _query.trim().toLowerCase();
    return [
      for (final item in widget.items)
        if (item.isVisible(widget.menuContext) &&
            (item.isReady || widget.showNotReady) &&
            (query.isEmpty ||
                item.label.toLowerCase().replaceAll('\n', ' ').contains(query)))
          item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    // Strip status bar memakai warna header (primary), badan halaman putih
    // — mengikuti referensi, yang menu-nya polos di atas latar putih,
    // bukan beige seperti tab lain.
    return ColoredBox(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: ColoredBox(
          color: AppColors.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              _MenuFeaturesBar(
                mode: _mode,
                onModeChanged: (mode) => setState(() => _mode = mode),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const _EmptyState()
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          for (final group in HrisMenuGroup.values)
                            ..._buildSection(group, visible),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSection(
    HrisMenuGroup group,
    List<HrisMenuItem> visible,
  ) {
    final groupItems = [
      for (final item in visible)
        if (item.group == group) item,
    ];
    if (groupItems.isEmpty) return const [];

    return [
      _SectionBar(label: group.label, group: group, style: widget.sectionBarStyle),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: _mode == _ViewMode.grid
            ? _GridSection(items: groupItems)
            : _ListSection(items: groupItems),
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      // Solid primary, sudut bawah bulat — sama dengan header Leave Request
      // dan Log Absensi.
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HRIS', style: AppTextStyles.h2.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            'Attendance, requests & employee services',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 14,
        color: AppColors.text,
      ),
      decoration: InputDecoration(
        hintText: 'Search Menu',
        hintStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          color: AppColors.textMuted,
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : InkWell(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
              ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _MenuFeaturesBar extends StatelessWidget {
  const _MenuFeaturesBar({required this.mode, required this.onModeChanged});

  final _ViewMode mode;
  final ValueChanged<_ViewMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Menu Features', style: AppTextStyles.h2),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _ModeButton(
                  icon: Icons.grid_view_rounded,
                  selected: mode == _ViewMode.grid,
                  onTap: () => onModeChanged(_ViewMode.grid),
                ),
                _ModeButton(
                  icon: Icons.view_list_rounded,
                  selected: mode == _ViewMode.list,
                  onTap: () => onModeChanged(_ViewMode.list),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: AppColors.primary) : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}

/// Pasangan (latar, teks) tiap grup untuk [HrisSectionBarStyle.categorized]
/// — sengaja dipetakan dari warna ikon grup itu sendiri (lihat
/// `HrisMenuConfig`), bukan warna baru, supaya section bar dan ikon di
/// dalamnya terasa satu keluarga warna.
(Color, Color) _categorizedColors(HrisMenuGroup group) {
  switch (group) {
    case HrisMenuGroup.attendance:
      return (AppColors.tealBg, AppColors.teal);
    case HrisMenuGroup.leave:
      return (AppColors.accentBg, AppColors.accent);
    case HrisMenuGroup.employee:
      return (AppColors.violetBg, AppColors.violet);
    case HrisMenuGroup.team:
      return (AppColors.primaryLight, AppColors.primary);
  }
}

/// Bar penuh selebar layar sebagai judul section — mengikuti gaya
/// referensi ("Organization", "Employee", dst), bukan label kecil seperti
/// di kartu lain. Warnanya mengikuti [HrisSectionBarStyle]; lihat enum itu
/// untuk perbandingan pilihannya.
class _SectionBar extends StatelessWidget {
  const _SectionBar({
    required this.label,
    required this.group,
    required this.style,
  });

  final String label;
  final HrisMenuGroup group;
  final HrisSectionBarStyle style;

  @override
  Widget build(BuildContext context) {
    // neutral: abu yang sama persis dengan kotak toggle grid/list di
    // sebelah "Menu Features" (AppColors.bg + garis AppColors.border),
    // supaya keduanya terasa satu warna abu, bukan dua abu yang beda tipis.
    final (background, foreground, border) = switch (style) {
      HrisSectionBarStyle.emerald =>
        (AppColors.primaryLight, AppColors.primary, null),
      HrisSectionBarStyle.neutral =>
        (AppColors.bg, AppColors.textMid, AppColors.border),
      HrisSectionBarStyle.categorized => (
          _categorizedColors(group).$1,
          _categorizedColors(group).$2,
          null,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: background,
        border: border == null
            ? null
            : Border(
                top: BorderSide(color: border),
                bottom: BorderSide(color: border),
              ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _GridSection extends StatelessWidget {
  const _GridSection({required this.items});

  final List<HrisMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        // Tinggi sel harus cukup untuk ikon 56 + label 2 baris + teks "Soon"
        // (item belum siap). 96 dulu bikin bottom overflow 14px.
        mainAxisExtent: 112,
      ),
      itemBuilder: (_, index) => _GridTile(item: items[index]),
    );
  }
}

/// Kotak ikon polos + label di bawahnya, TANPA bingkai kartu di sekeliling
/// keduanya — mengikuti gaya referensi (ikon dalam kotak putih beraksen
/// bayangan tipis, teks langsung di bawah, bukan di dalam card).
class _GridTile extends StatelessWidget {
  const _GridTile({required this.item});

  final HrisMenuItem item;

  @override
  Widget build(BuildContext context) {
    final enabled = item.isReady;

    return InkWell(
      onTap: enabled ? item.onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, size: 24, color: item.color),
                ),
                if (item.badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: _CountBadge(count: item.badgeCount),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMid,
                height: 1.25,
              ),
            ),
            if (!enabled)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('Soon', style: AppTextStyles.caption),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tampilan daftar (toggle "list") — baris ikon kecil + label + chevron,
/// dipisah garis tipis. Data dan urutannya sama dengan tampilan grid, cuma
/// bentuknya berbeda untuk yang lebih suka menyisir daftar panjang.
class _ListSection extends StatelessWidget {
  const _ListSection({required this.items});

  final List<HrisMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _ListTile(item: items[i]),
          if (i != items.length - 1)
            const Divider(height: 1, color: AppColors.border),
        ],
      ],
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({required this.item});

  final HrisMenuItem item;

  @override
  Widget build(BuildContext context) {
    final enabled = item.isReady;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? item.onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 20, color: item.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label.replaceAll('\n', ' '),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (item.badgeCount > 0) ...[
                _CountBadge(count: item.badgeCount),
                const SizedBox(width: 8),
              ],
              if (!enabled)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text('Soon', style: AppTextStyles.caption),
                ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.rejected,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(40, 0, 40, 60),
        child: Text(
          'Menu tidak ditemukan.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted,
        ),
      ),
    );
  }
}
