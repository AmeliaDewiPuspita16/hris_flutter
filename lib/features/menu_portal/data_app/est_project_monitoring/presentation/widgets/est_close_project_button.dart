import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../bloc/detail/close_project_bloc.dart';
import '../bloc/detail/close_project_event.dart';
import '../bloc/detail/close_project_state.dart';

/// Tombol "Request Tutup Proyek" (dengan dialog konfirmasi). Bila proyek sudah
/// `pending_close`, menampilkan kotak status menunggu persetujuan HOD.
class EstCloseProjectButton extends StatelessWidget {
  const EstCloseProjectButton({
    super.key,
    required this.projectId,
    required this.status,
  });

  final int projectId;
  final String status;

  @override
  Widget build(BuildContext context) {
    // Jika sudah pending_close → tampilkan status, bukan tombol tutup
    if (status == 'pending_close') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.orangeBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_top_outlined,
                color: AppColors.orange, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Menunggu persetujuan HOD untuk menutup proyek ini.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.orange,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<CloseProjectBloc, CloseProjectState>(
      builder: (context, state) {
        final isLoading = state is CloseProjectLoading;
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : () => _confirmClose(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.rejected,
              side: BorderSide(color: AppColors.rejected),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.rejected,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.lock_outline, size: 18),
            label: Text(
              isLoading ? 'Mengirim Request...' : 'Request Tutup Proyek',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmClose(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orangeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.send_outlined,
                color: AppColors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Request Tutup Proyek?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Request penutupan akan dikirim ke HOD untuk disetujui.\n\n'
          'Proyek akan berstatus "Pending Approval" sampai HOD menyetujui atau menolak request ini.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSub,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.solid(AppColors.orange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Kirim Request',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<CloseProjectBloc>().add(SubmitCloseProject(projectId));
    }
  }
}
