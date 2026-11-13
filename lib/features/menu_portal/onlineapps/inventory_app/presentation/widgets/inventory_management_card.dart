import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/inventory_menu.dart';

/// Warna satu kartu Management, mengikuti kartu di halaman Online Apps:
/// ikon di kotak gradien, latar putih yang memudar ke warna tint, dan garis
/// tepi setipis tint yang sama.
///
/// Nilai hex diambil dari kartu Inventory / Procurement / HSE di Online Apps.
/// Ganti dengan token `AppColors` bila warna itu sudah punya nama di sana.
class InventoryManagementTone {
  const InventoryManagementTone({
    required this.panel,
    required this.border,
    required this.tileFrom,
    required this.tileTo,
  });

  /// Latar panel atas (ujung tint).
  final Color panel;
  final Color border;

  /// Gradien kotak ikon, kiri-atas ke kanan-bawah.
  final Color tileFrom;
  final Color tileTo;

  /// Hijau hutan, seperti Inventory.
  static const green = InventoryManagementTone(
    panel: Color(0xFFE3F6EF),
    border: Color(0xFFBFDACD),
    tileFrom: Color(0xFF63917D),
    tileTo: Color(0xFF387157),
  );

  /// Emas, seperti Procurement Monitoring.
  static const gold = InventoryManagementTone(
    panel: Color(0xFFFBF5E6),
    border: Color(0xFFECDEBE),
    tileFrom: Color(0xFFD7BA7A),
    tileTo: Color(0xFFCCA654),
  );

  /// Terakota, seperti HSE Work Request. Belum dipakai.
  static const coral = InventoryManagementTone(
    panel: Color(0xFFFCECE5),
    border: Color(0xFFEDB5A1),
    tileFrom: Color(0xFFE28566),
    tileTo: Color(0xFFDA623A),
  );

  /// Kartu yang belum siap (redup, seperti Meter Reading di Online Apps).
  static const disabled = InventoryManagementTone(
    panel: Color(0xFFEFF0F2),
    border: Color(0xFFE2E4E8),
    tileFrom: Color(0xFFC9CFD8),
    tileTo: Color(0xFFB3BAC6),
  );
}

/// Satu kartu di halaman Management: panel tint di atas dengan ikon besar di
/// kotak gradien, lalu judul dan keterangan singkat di bagian putih bawahnya.
///
/// Bila `option.ready` false kartu memakai [InventoryManagementTone.disabled]
/// dengan label "Coming soon" dan tidak bisa diketuk, sama seperti di web.
///
/// [dense] true untuk grid tiga kolom: panel, ikon, dan teks dikecilkan.
class InventoryManagementCard<T> extends StatelessWidget {
  const InventoryManagementCard({
    super.key,
    required this.option,
    required this.tone,
    this.dense = false,
    this.onTap,
  });

  final InventoryOption<T> option;
  final InventoryManagementTone tone;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ready = option.ready;
    final t = ready ? tone : InventoryManagementTone.disabled;

    final panelHeight = dense ? 72.0 : 84.0;
    final tileSize = dense ? 46.0 : 52.0;
    final iconSize = dense ? 23.0 : 26.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border),
        boxShadow: ready
            ? [
                BoxShadow(
                  color: t.tileTo.withAlpha(36),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: ready ? onTap : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    height: panelHeight,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(Colors.white, t.panel, 0.4)!,
                          t.panel,
                        ],
                      ),
                    ),
                    child: SizedBox.expand(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Lingkaran besar samar di balik kotak ikon, ikut
                          // warna tint kartu.
                          Positioned(
                            top: -36,
                            right: -28,
                            child: _Circle(
                              size: 112,
                              color: Colors.white.withAlpha(110),
                            ),
                          ),
                          Positioned(
                            bottom: -30,
                            left: -22,
                            child: _Circle(
                              size: 78,
                              color: Colors.white.withAlpha(80),
                            ),
                          ),
                          _IconTile(
                            icon: option.icon,
                            tone: t,
                            ready: ready,
                            size: tileSize,
                            iconSize: iconSize,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!ready)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Coming soon',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Opacity(
                opacity: ready ? 1 : 0.6,
                child: Padding(
                  padding: dense
                      ? const EdgeInsets.fromLTRB(10, 8, 10, 10)
                      : const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontSize: dense ? 12 : 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle,
                        maxLines: dense ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: dense ? 10 : 11,
                          height: 1.35,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kotak ikon bergradien dengan lingkaran transparan di dalamnya, seperti
/// hiasan pada kartu kategori di halaman Online Apps.
class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.tone,
    required this.ready,
    required this.size,
    required this.iconSize,
  });

  final IconData icon;
  final InventoryManagementTone tone;
  final bool ready;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.31;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.tileFrom, tone.tileTo],
        ),
        boxShadow: [
          BoxShadow(
            color: tone.tileTo.withAlpha(ready ? 90 : 0),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -size * 0.25,
              right: -size * 0.25,
              child: _Circle(
                size: size * 0.78,
                color: Colors.white.withAlpha(40),
              ),
            ),
            Positioned(
              bottom: -size * 0.31,
              left: -size * 0.22,
              child: _Circle(
                size: size * 0.66,
                color: Colors.white.withAlpha(28),
              ),
            ),
            Icon(icon, size: iconSize, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
