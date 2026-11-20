import 'package:material_ui/material_ui.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../domain/opname_record.dart';
import 'opname_detail_header.dart';

/// Bar bawah detail draft: hasil hitungan sekilas di atas, lalu tombol
/// Delete, Edit, dan Confirm. Hanya dipakai untuk draft (`can_edit`).
class OpnameDetailActionBar extends StatelessWidget {
  final OpnameDetail detail;

  /// Permintaan confirm / delete sedang berjalan: tombol dikunci.
  final bool acting;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;

  const OpnameDetailActionBar({
    super.key,
    required this.detail,
    required this.acting,
    required this.onDelete,
    required this.onEdit,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hasil dari Confirm, tepat di sebelah tombolnya.
              Align(
                alignment: Alignment.centerLeft,
                child: OpnameStatsChips(stats: opnameStatsOf(detail)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Delete draft',
                    onPressed: acting ? null : onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: acting ? null : onEdit,
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: acting ? null : onConfirm,
                      child: acting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
