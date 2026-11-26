import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shared/domain/role.dart';
import '../../domain/leave_history_entry.dart';
import '../widgets/ajukan_tab.dart';

/// Layar edit draft: form yang sama dengan tab Ajukan, terisi data draft.
///
/// Dibuka lewat push dari tab Status; pemanggil wajib membungkusnya dengan
/// `RepositoryProvider<PengajuanRepository>` dan `BlocProvider<LeaveHistoryBloc>`
/// (lihat `_StatusTabState._editDraft`) karena route baru tidak mewarisinya.
class EditDraftScreen extends StatelessWidget {
  const EditDraftScreen({super.key, required this.role, required this.entry});

  final Role role;
  final LeaveHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Edit Draft'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AjukanTab(
        role: role,
        initialDraft: entry.draft,
        editingEntry: entry,
        // Setelah tersimpan/terkirim, kembali ke tab Status.
        onSubmitted: () => Navigator.of(context).pop(),
      ),
    );
  }
}
