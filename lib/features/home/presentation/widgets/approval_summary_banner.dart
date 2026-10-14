import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';

/// Satu modul yang punya approval menunggu (Leave, IT, EST, Indent, dst) —
/// jadi satu tag warna di [ApprovalSummaryBanner]. Modul baru cukup
/// ditambah ke daftar `entries`, tanpa mengubah banner-nya.
class ApprovalSummaryEntry {
  const ApprovalSummaryEntry({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;
}

/// Banner ringkasan approval yang masih menunggu, digabung dari semua modul
/// yang butuh keputusan (sekarang Leave, IT Request, EST Request, Indent
/// Vehicle) — ditempatkan di bawah header dan di atas "Main Menu", mengikuti
/// pola awal HRIS.
///
/// Sampai 3 modul tag dibagi rata selebar kartu; lebih dari 3 jadi satu baris
/// yang bisa digeser ke samping. Di mode geser lebar tiap tag mengikuti
/// panjang labelnya (`fitContent`), jadi label selalu terbaca penuh dan tag
/// yang terpotong di tepi kartu jadi petunjuk bahwa masih bisa digeser.
///
/// Dua zona ketuk:
/// - Badan banner (ikon + judul) → [onTapAll], dimaksudkan membuka
///   Notifications tab "Action" — cakupannya semua hal yang butuh
///   keputusan, tidak cuma 3 modul ini.
/// - Tiap tag warna → `onTap` milik [ApprovalSummaryEntry]-nya, dimaksudkan
///   membuka halaman approval modul itu langsung kalau sudah tersedia
///   (yang belum punya halaman approval sendiri untuk sementara jatuh ke
///   Notifications).
///
/// SEMENTARA: ditampilkan tanpa gerbang role — pemetaan HOD per-departemen
/// (HOD IT vs HOD Estate vs HOD lain) dari API belum ada, sama seperti
/// catatan role di auth_gate.dart. Sembunyikan lewat [visible]=false kalau
/// totalnya 0.
class ApprovalSummaryBanner extends StatelessWidget {
  const ApprovalSummaryBanner({
    super.key,
    required this.entries,
    required this.onTapAll,
  });

  final List<ApprovalSummaryEntry> entries;

  final VoidCallback onTapAll;

  int get _total => entries.fold(0, (sum, e) => sum + e.count);

  @override
  Widget build(BuildContext context) {
    if (_total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTapAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: _CountBadge(count: _total),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Approvals waiting',
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Tap for all in Notifications',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            _ModuleTagRow(entries: entries),
          ],
        ),
      ),
    );
  }
}

/// Baris tag modul: dibagi rata kalau muat ([_fixedCount] atau kurang),
/// selebihnya bisa digeser ke samping.
class _ModuleTagRow extends StatelessWidget {
  const _ModuleTagRow({required this.entries});

  final List<ApprovalSummaryEntry> entries;

  static const _gap = 8.0;

  /// Jumlah tag yang masih dibagi rata selebar kartu.
  static const _fixedCount = 3;

  Widget _tag(ApprovalSummaryEntry e, {bool fitContent = false}) => _ModuleTag(
        fitContent: fitContent,
        label: e.label,
        count: e.count,
        icon: e.icon,
        color: e.color,
        background: e.background,
        onTap: e.onTap,
      );

  @override
  Widget build(BuildContext context) {
    if (entries.length <= _fixedCount) {
      return Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(child: _tag(entries[i])),
          ],
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            _tag(entries[i], fitContent: true),
          ],
        ],
      ),
    );
  }
}

/// Badge bulat merah untuk menampilkan angka jumlah — dipakai di ikon lonceng
/// (total semua modul) maupun di tiap [_ModuleTag] (jumlah per modul).
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.rejected,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// Tile per modul (Leave/IT/EST/Indent), masing-masing dengan warna & ikon khasnya
/// sendiri (selaras dengan [NotificationCategory]) supaya gampang dibedakan
/// sekilas, dengan badge angka merah di pojok sebagai penanda "perlu
/// direspons".
class _ModuleTag extends StatelessWidget {
  const _ModuleTag({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
    this.fitContent = false,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  /// True = lebar tag mengikuti isinya (dipakai di baris yang bisa digeser).
  /// False = mengisi lebar yang diberikan induknya (dibagi rata).
  final bool fitContent;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              // fitContent: tag selebar isinya (label tidak boleh Expanded
              // karena baris yang bisa digeser tidak punya lebar terbatas).
              mainAxisSize: fitContent ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                if (fitContent) labelText else Expanded(child: labelText),
                const SizedBox(width: 6),
                _CountBadge(count: count),
              ],
            ),
            Icon(Icons.chevron_right, size: 14, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
