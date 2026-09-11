import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../shared/domain/role.dart';
import '../../domain/leave_type.dart';

class RingkasanTab extends StatelessWidget {
  const RingkasanTab({
    super.key,
    required this.role,
  });

  final Role role;

  List<_SaldoCard> get saldoCards {
    final showLembur =
        LeaveTypeX.showPersonalLembur(role);

    return [
      const _SaldoCard(
        'Cuti Tahunan',
        4,
        12,
        'Hari',
        AppColors.primaryMid,
        AppColors.primaryLight,
      ),

      const _SaldoCard(
        'Cuti Sakit',
        0,
        null,
        'Hari',
        AppColors.rejected,
        AppColors.rejectedBg,
      ),

      const _SaldoCard(
        'Izin',
        2,
        6,
        'Hari',
        AppColors.pending,
        AppColors.pendingBg,
      ),

      if (showLembur)
        const _SaldoCard(
          'Lembur',
          14.5,
          null,
          'Jam',
          Color(0xFF6B46C1),
          Color(0xFFFAF5FF),
        )
      else
        const _SaldoCard(
          'Cuti Pengganti',
          2,
          5,
          'Hari',
          Color(0xFF2C7A7B),
          Color(0xFFE6FFFA),
        ),

      const _SaldoCard(
        'Cek Kesehatan',
        0,
        1,
        'Kali',
        AppColors.presentMid,
        AppColors.presentBg,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Saldo cuti & izin tahun $year',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(height: 14),

          ...saldoCards.map(
            (saldo) {
              final sisa = saldo.total != null
                  ? saldo.total! - saldo.used
                  : saldo.used;

              final ratio = saldo.total != null
                  ? (saldo.used / saldo.total!)
                      .clamp(0, 1)
                      .toDouble()
                  : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: saldo.bg,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    saldo.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: saldo.color,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  saldo.total != null
                                      ? 'Terpakai ${saldo.used} dari ${saldo.total} ${saldo.unit}'
                                      : 'Terkumulasi: ${saldo.used} ${saldo.unit}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$sisa',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight:
                                      FontWeight.w900,
                                  color: saldo.color,
                                  height: 1,
                                ),
                              ),

                              Text(
                                saldo.total != null
                                    ? 'Tersisa'
                                    : 'Saldo',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color:
                                      AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      if (ratio != null) ...[
                        const SizedBox(height: 10),

                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor:
                                AppColors.border,
                            valueColor:
                                AlwaysStoppedAnimation(
                              saldo.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SaldoCard {
  const _SaldoCard(
    this.label,
    this.used,
    this.total,
    this.unit,
    this.color,
    this.bg,
  );

  final String label;
  final num used;
  final num? total;
  final String unit;
  final Color color;
  final Color bg;
}