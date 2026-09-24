import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';

/// Banner ringkasan approval yang masih menunggu, digabung dari 3 modul:
/// Leave (HRIS), IT Request, EST Request — ditempatkan di bawah header dan
/// di atas "Main Menu", mengikuti pola awal HRIS.
///
/// Dua zona ketuk:
/// - Badan banner (ikon + judul) → [onTapAll], dimaksudkan membuka
///   Notifications tab "Action" — cakupannya semua hal yang butuh
///   keputusan, tidak cuma 3 modul ini.
/// - Tiap tag warna → [onTapLeave]/[onTapIt]/[onTapEst], dimaksudkan
///   membuka halaman approval modul itu langsung kalau sudah tersedia
///   (baru IT yang punya tab Approve Request sungguhan sekarang; Leave &
///   EST untuk sementara jatuh ke Notifications juga sampai halaman
///   approval masing-masing dibuat).
///
/// SEMENTARA: ditampilkan tanpa gerbang role — pemetaan HOD per-departemen
/// (HOD IT vs HOD Estate vs HOD lain) dari API belum ada, sama seperti
/// catatan role di auth_gate.dart. Sembunyikan lewat [visible]=false kalau
/// totalnya 0.
class ApprovalSummaryBanner extends StatelessWidget {
  const ApprovalSummaryBanner({
    super.key,
    required this.leaveCount,
    required this.itCount,
    required this.estCount,
    required this.onTapAll,
    required this.onTapLeave,
    required this.onTapIt,
    required this.onTapEst,
  });

  final int leaveCount;
  final int itCount;
  final int estCount;

  final VoidCallback onTapAll;
  final VoidCallback onTapLeave;
  final VoidCallback onTapIt;
  final VoidCallback onTapEst;

  int get _total => leaveCount + itCount + estCount;

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
            Row(
              children: [
                Expanded(
                  child: _ModuleTag(
                    label: 'Leave',
                    count: leaveCount,
                    icon: Icons.beach_access_outlined,
                    color: AppColors.teal,
                    background: AppColors.tealBg,
                    onTap: onTapLeave,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModuleTag(
                    label: 'IT',
                    count: itCount,
                    icon: Icons.computer_outlined,
                    color: AppColors.itRequest,
                    background: AppColors.itRequestBg,
                    onTap: onTapIt,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModuleTag(
                    label: 'EST',
                    count: estCount,
                    icon: Icons.engineering_outlined,
                    color: AppColors.estRequest,
                    background: AppColors.estRequestBg,
                    onTap: onTapEst,
                  ),
                ),
              ],
            ),
          ],
        ),
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

/// Tile per modul (Leave/IT/EST), masing-masing dengan warna & ikon khasnya
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
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
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
