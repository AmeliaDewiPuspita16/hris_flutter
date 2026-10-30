import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_shimmer.dart';

/// Banner ringkasan approval yang masih menunggu, digabung dari 5 modul:
/// Leave (HRIS), IT Request, EST Work Order, Indent Vehicle, eProcurement —
/// ditempatkan di bawah header dan di atas "Main Menu", mengikuti pola awal
/// HRIS.
///
/// Dua zona ketuk:
/// - Badan banner (ikon + judul) → [onTapAll], dimaksudkan membuka
///   Notifications tab "Action" — cakupannya semua hal yang butuh
///   keputusan, tidak cuma modul-modul ini.
/// - Tiap tag warna → `onTap...` masing-masing, dimaksudkan membuka halaman
///   approval modul itu langsung kalau sudah tersedia (baru IT yang punya
///   tab Approve Request sungguhan sekarang; yang lain untuk sementara
///   jatuh ke Notifications juga sampai halaman approval masing-masing
///   dibuat).
///
/// Gerbang role (hanya `hod`) dipasang oleh pemanggil di BerandaScreen,
/// bukan di widget ini. Pemetaan HOD per-departemen dari API belum ada.
/// Sembunyikan otomatis kalau totalnya 0 (dan bukan sedang [isLoading]).
class ApprovalSummaryBanner extends StatelessWidget {
  const ApprovalSummaryBanner({
    super.key,
    required this.isLoading,
    required this.leaveCount,
    required this.itCount,
    required this.estCount,
    required this.indentVehicleCount,
    required this.eprocurementCount,
    required this.onTapAll,
    required this.onTapLeave,
    required this.onTapIt,
    required this.onTapEst,
    required this.onTapIndentVehicle,
    required this.onTapEprocurement,
  });

  /// True selagi ringkasan IT/EST/Indent Vehicle/eProcurement masih diambil
  /// dari server — banner menampilkan skeleton shimmer, bukan isi asli,
  /// supaya tidak "lompat" dari kosong ke terisi.
  final bool isLoading;

  final int leaveCount;
  final int itCount;
  final int estCount;
  final int indentVehicleCount;
  final int eprocurementCount;

  final VoidCallback onTapAll;
  final VoidCallback onTapLeave;
  final VoidCallback onTapIt;
  final VoidCallback onTapEst;
  final VoidCallback onTapIndentVehicle;
  final VoidCallback onTapEprocurement;

  int get _total =>
      leaveCount + itCount + estCount + indentVehicleCount + eprocurementCount;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && _total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: isLoading ? const _BannerShimmer() : _buildContent(),
      ),
    );
  }

  List<_ModuleTag> get _tags => [
        _ModuleTag(
          label: 'Leave',
          count: leaveCount,
          icon: Icons.beach_access_outlined,
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: onTapLeave,
        ),
        _ModuleTag(
          label: 'IT',
          count: itCount,
          icon: Icons.computer_outlined,
          color: AppColors.itRequest,
          background: AppColors.itRequestBg,
          onTap: onTapIt,
        ),
        _ModuleTag(
          label: 'EST',
          count: estCount,
          icon: Icons.engineering_outlined,
          color: AppColors.estRequest,
          background: AppColors.estRequestBg,
          onTap: onTapEst,
        ),
        _ModuleTag(
          label: 'Indent Vehicle',
          count: indentVehicleCount,
          icon: Icons.directions_car_outlined,
          color: AppColors.orange,
          background: AppColors.orangeBg,
          onTap: onTapIndentVehicle,
        ),
        _ModuleTag(
          label: 'eProcurement',
          count: eprocurementCount,
          icon: Icons.trending_up_outlined,
          color: AppColors.accent,
          background: AppColors.accentBg,
          onTap: onTapEprocurement,
        ),
      ];

  Widget _buildContent() {
    final tags = _tags.where((tag) => tag.count > 0).toList();

    return Column(
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
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                        color: AppColors.primaryText,
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
                Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        // Digulir horizontal, bukan dipaksa muat satu baris — sama seperti
        // "Main Menu" ([LayananSection]) — supaya kartu tidak sempit terus
        // bisa nambah modul lagi nanti tanpa pecah layout.
        SizedBox(
          height: 54,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) => SizedBox(width: 140, child: tags[index]),
          ),
        ),
      ],
    );
  }
}

/// Skeleton shimmer berbentuk layout isi banner asli (ikon + judul, lalu
/// baris tag modul yang bisa digulir), ditampilkan selagi
/// [ApprovalSummaryBanner.isLoading].
class _BannerShimmer extends StatelessWidget {
  const _BannerShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const ShimmerBox(width: 40, height: 40, borderRadius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 130, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 160, height: 11, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) =>
                  const SizedBox(width: 140, child: ShimmerBox(height: 54, borderRadius: 12)),
            ),
          ),
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
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.badge,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.card, width: 1.5),
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

/// Tile per modul, masing-masing dengan warna & ikon khasnya sendiri supaya
/// gampang dibedakan sekilas, dengan badge angka merah di pojok sebagai
/// penanda "perlu direspons".
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  _CountBadge(count: count),
                ],
              ],
            ),
            Icon(Icons.chevron_right, size: 14, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
