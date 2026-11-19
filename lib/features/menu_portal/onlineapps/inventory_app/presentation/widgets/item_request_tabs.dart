import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Tab bergaya garis bawah ("Request" | "Verification") untuk layar Item
/// Request. Sengaja berbeda bentuk dari chip filter di bawahnya (pil): tab
/// = pindah halaman, chip = menyaring isi halaman.
///
/// [badgeCounts] memetakan indeks tab ke angka badge; badge disembunyikan
/// bila angkanya 0 atau tidak ada.
class ItemRequestTabs extends StatelessWidget {
  const ItemRequestTabs({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onChanged,
    this.icons,
    this.badgeCounts = const {},
  });

  final List<String> labels;
  final List<IconData>? icons;
  final int activeIndex;
  final ValueChanged<int> onChanged;
  final Map<int, int> badgeCounts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _Tab(
                label: labels[i],
                icon: icons != null && i < icons!.length ? icons![i] : null,
                badge: badgeCounts[i] ?? 0,
                active: i == activeIndex,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.badge,
    required this.active,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final int badge;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // primaryText (bukan primary): menyesuaikan tema, jadi tetap terbaca di
    // mode gelap.
    final color = active ? AppColors.primaryText : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                if (badge > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      // Di mode gelap `AppColors.pending` berubah jadi salmon
                      // terang sehingga teks putihnya tidak kontras; pakai
                      // oranye-merah gelap.
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFC2410C)
                          : AppColors.pending,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: active ? AppColors.primaryText : Colors.transparent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
