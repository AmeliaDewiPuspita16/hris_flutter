import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/est_form_worker.dart';
import 'est_form_worker_tile.dart';

/// Pencarian + daftar pilih DW di form proyek. Seluruh state (hasil, pilihan,
/// query) dipegang form; widget ini hanya menggambar dan meneruskan aksi.
class EstFormWorkerPicker extends StatelessWidget {
  const EstFormWorkerPicker({
    super.key,
    required this.workers,
    required this.loading,
    required this.error,
    required this.searchQuery,
    required this.selectedCount,
    required this.onSearchChanged,
    required this.onRetry,
    required this.onToggle,
    required this.onToggleAll,
  });

  final List<EstFormWorker> workers;
  final bool loading;
  final String? error;
  final String searchQuery;
  final int selectedCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRetry;
  final ValueChanged<EstFormWorker> onToggle;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final allSelected =
        workers.isNotEmpty && workers.every((d) => d.isSelected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _searchField(),
        const SizedBox(height: 12),
        if (error != null) ...[
          _errorBox(),
          const SizedBox(height: 12),
        ],
        if (searchQuery.isEmpty && selectedCount == 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_search_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Text(
                  'Ketik nama untuk mencari DW',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        if (searchQuery.isNotEmpty && (!loading || workers.isNotEmpty)) ...[
          Row(
            children: [
              Text(
                loading ? 'Mencari...' : '${workers.length} DW ditemukan',
                style: TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
              const Spacer(),
              if (workers.isNotEmpty)
                GestureDetector(
                  onTap: onToggleAll,
                  child: Text(
                    allSelected ? 'Batalkan Semua' : 'Pilih Semua',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (searchQuery.isNotEmpty) ...[
          if (loading && workers.isEmpty)
            _shimmer()
          else if (workers.isEmpty && !loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'DW "$searchQuery" tidak ditemukan',
                  style: TextStyle(fontSize: 13, color: AppColors.textSub),
                ),
              ),
            )
          else
            ...workers.map(
              (dw) =>
                  EstFormWorkerTile(worker: dw, onToggle: () => onToggle(dw)),
            ),
        ],
        if (selectedCount > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.presentBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.groups_outlined,
                  color: AppColors.primaryText,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$selectedCount DW dipilih untuk proyek ini',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: onSearchChanged,
      style: TextStyle(fontSize: 13, color: AppColors.text),
      decoration: InputDecoration(
        hintText: 'Cari nama atau keahlian...',
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
        prefixIcon: Icon(Icons.search, color: AppColors.textSub, size: 18),
        suffixIcon: loading
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryText,
                  ),
                ),
              )
            : null,
        filled: true,
        fillColor: AppColors.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primaryText, width: 1.5),
        ),
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.rejected, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error!,
              style: TextStyle(fontSize: 12, color: AppColors.rejected),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Coba lagi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.rejected,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmer() {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
