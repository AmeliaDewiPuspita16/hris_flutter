import 'package:flutter/material.dart';

/// Pil navigasi bulan di dalam header hijau: panah bulan sebelumnya/berikutnya
/// dan label bulan yang bisa diketuk untuk membuka pemilih bulan.
///
/// Bentuknya sama dengan navigasi bulan di Log Absensi. [onPrevious] / [onNext]
/// null = panah mati (sudah di batas bulan yang boleh dibuka).
class AttendanceMonthNav extends StatelessWidget {
  const AttendanceMonthNav({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime month;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  String get _label => '${_months[month.month - 1]} ${month.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Arrow(
            icon: Icons.chevron_left,
            label: 'Previous month',
            onTap: onPrevious,
          ),
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          _Arrow(
            icon: Icons.chevron_right,
            label: 'Next month',
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            size: 20,
            color: Colors.white.withOpacity(onTap == null ? 0.35 : 1),
          ),
        ),
      ),
    );
  }
}
