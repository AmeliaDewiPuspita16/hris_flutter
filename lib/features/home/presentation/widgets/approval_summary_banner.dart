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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTapAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, size: 20, color: AppColors.rejected),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                              children: [
                                TextSpan(
                                  text: '$_total',
                                  style: const TextStyle(color: AppColors.rejected),
                                ),
                                const TextSpan(text: ' approvals waiting'),
                              ],
                            ),
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
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ModuleTag(
                    label: 'Leave',
                    count: leaveCount,
                    onTap: onTapLeave,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModuleTag(
                    label: 'IT',
                    count: itCount,
                    onTap: onTapIt,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModuleTag(
                    label: 'EST',
                    count: estCount,
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

/// Tile netral per modul (Leave/IT/EST) dengan badge angka merah di pojok —
/// angka jadi penanda "perlu direspons", bukan sekadar statistik warna-warni.
class _ModuleTag extends StatelessWidget {
  const _ModuleTag({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.neutralBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMid,
                ),
              ),
            ),
            Positioned(
              top: -4,
              right: 8,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.rejected,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
