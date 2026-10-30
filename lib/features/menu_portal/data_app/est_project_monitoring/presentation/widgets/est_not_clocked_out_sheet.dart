import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/executive_dashboard.dart';

/// Peringatan "Ada DW Belum Absen Pulang" sebelum sesi ditutup. Hasil true =
/// pengguna memilih "Auto Clock Out ... & Tutup".
class EstNotClockedOutSheet {
  const EstNotClockedOutSheet._();

  static Future<bool> show(
    BuildContext context,
    ExecutiveProjectModel project,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _Body(project: project),
    );
    return confirmed ?? false;
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.project});

  final ExecutiveProjectModel project;

  @override
  Widget build(BuildContext context) {
    final shown = project.notClockedOutList.take(4).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orangeBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ada DW Belum Absen Pulang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${project.notClockedOut} DW di proyek "${project.name}" belum melakukan absen pulang.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSub,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < shown.length; i++)
                        _WorkerRow(
                          worker: shown[i],
                          showDivider: i != shown.length - 1,
                        ),
                    ],
                  ),
                ),
                if (project.notClockedOut > 4) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '+${project.notClockedOut - 4} DW lainnya',
                      style: TextStyle(fontSize: 12, color: AppColors.textSub),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.solid(AppColors.orange),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.flash_on_rounded, size: 18),
                    label: Text(
                      'Auto Clock Out ${project.notClockedOut} DW & Tutup',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSub,
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerRow extends StatelessWidget {
  const _WorkerRow({required this.worker, required this.showDivider});

  final ExecutiveNotClockedOutModel worker;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.orangeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    worker.name[0],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      'Masuk: ${worker.clockIn}',
                      style: TextStyle(fontSize: 11, color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orangeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Belum Pulang',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 64, color: AppColors.border),
      ],
    );
  }
}
