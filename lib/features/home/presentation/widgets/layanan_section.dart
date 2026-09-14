import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/service_shortcut.dart';

/// Grid pintasan layanan.
///
/// Semua item berada di dalam satu kartu, bukan kotak-kotak terpisah — dengan
/// jumlah item yang berubah per role, kotak terpisah menyisakan "anak yatim"
/// di baris terakhir dan bidangnya terlihat pecah. Kolomnya dibuat tetap
/// [_columns] buah dan slot sisa diisi ruang kosong, jadi ikon di baris mana
/// pun tetap lurus satu sama lain.
class LayananSection extends StatelessWidget {
  const LayananSection({super.key, required this.services});

  static const _columns = 4;

  final List<ServiceShortcut> services;

  /// Memotong daftar jadi baris-baris berisi [_columns] slot.
  /// Slot yang tidak terpakai bernilai null.
  List<List<ServiceShortcut?>> get _rows {
    final rows = <List<ServiceShortcut?>>[];
    for (var start = 0; start < services.length; start += _columns) {
      rows.add([
        for (var column = 0; column < _columns; column++)
          start + column < services.length ? services[start + column] : null,
      ]);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Services', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final service in rows[i])
                        Expanded(
                          child: service == null
                              ? const SizedBox.shrink()
                              : _ServiceTile(service: service),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service});

  final ServiceShortcut service;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: service.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: service.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(service.icon, size: 22, color: service.color),
            ),
            const SizedBox(height: 8),
            Text(
              service.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMid,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
