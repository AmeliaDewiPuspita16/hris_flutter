import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/leave_history_entry.dart';
import '../../domain/leave_type.dart';

/// Detail satu pengajuan (tanggal, durasi, alasan, lampiran, catatan) dalam
/// bottom sheet. Dipisah jadi fungsi + widget sendiri supaya tab Ringkasan
/// dan tab Status bisa sama-sama memanggilnya saat barisnya ditap.
///
/// Untuk draft, [onEditDraft] dan [onSubmitDraft] menampilkan tombol Edit &
/// Submit. Keduanya dipanggil SETELAH sheet ditutup, dan dibuat oleh pemanggil
/// karena sheet ini dibuka di route terpisah yang tidak mewarisi bloc/provider
/// layar Pengajuan. Tanpa callback (mis. dari tab Ringkasan) tombolnya tidak
/// tampil.
Future<void> showLeaveDetailSheet(
  BuildContext context,
  LeaveHistoryEntry entry, {
  VoidCallback? onEditDraft,
  VoidCallback? onSubmitDraft,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _LeaveDetailSheet(
      entry: entry,
      onEditDraft: onEditDraft,
      onSubmitDraft: onSubmitDraft,
    ),
  );
}

class _LeaveDetailSheet extends StatelessWidget {
  const _LeaveDetailSheet({
    required this.entry,
    this.onEditDraft,
    this.onSubmitDraft,
  });

  final LeaveHistoryEntry entry;
  final VoidCallback? onEditDraft;
  final VoidCallback? onSubmitDraft;

  /// Catatan hanya ditampilkan bila menambah informasi di luar badge status
  /// (mis. "Waiting for approval"), bukan sekadar mengulang "Approved".
  bool get _showNote {
    final note = entry.note.trim().toLowerCase();
    final label = (entry.statusLabel ?? '').trim().toLowerCase();
    return note.isNotEmpty && note != label;
  }

  bool get _showActions =>
      entry.canEditDraft && (onEditDraft != null || onSubmitDraft != null);

  @override
  Widget build(BuildContext context) {
    final reason = entry.reason?.trim();
    final hasReason = reason != null && reason.isNotEmpty;
    final attachment = entry.photoUrl;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _Header(entry: entry),
            const SizedBox(height: 18),
            _InfoStrip(entry: entry),
            const SizedBox(height: 20),
            const _SectionLabel('Reason'),
            const SizedBox(height: 6),
            Text(
              hasReason ? reason : 'No reason provided.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: hasReason ? AppColors.text : AppColors.textMuted,
                fontStyle: hasReason ? FontStyle.normal : FontStyle.italic,
              ),
            ),
            if (attachment != null) ...[
              const SizedBox(height: 20),
              const _SectionLabel('Attachment'),
              const SizedBox(height: 8),
              _AttachmentTile(name: attachment),
            ],
            if (_showNote) ...[
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.note,
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ],
            if (_showActions) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  if (onEditDraft != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryText,
                          side: BorderSide(color: AppColors.primaryText, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () {
                          Navigator.pop(context);
                          onEditDraft!();
                        },
                      ),
                    ),
                  if (onEditDraft != null && onSubmitDraft != null) const SizedBox(width: 10),
                  if (onSubmitDraft != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 17),
                        label: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () {
                          Navigator.pop(context);
                          onSubmitDraft!();
                        },
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ikon jenis, nama jenis (+ penanda urgent), dan badge status.
class _Header extends StatelessWidget {
  const _Header({required this.entry});

  final LeaveHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final icon = LeaveTypeX.fromLabel(entry.type)?.icon ?? Icons.event_note_outlined;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: entry.typeBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: entry.typeColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.type,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: AppColors.text,
                ),
              ),
              if (entry.isUrgent) ...[
                const SizedBox(height: 5),
                const _UrgentChip(),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        StatusBadge(status: entry.status, label: entry.statusLabel),
      ],
    );
  }
}

class _UrgentChip extends StatelessWidget {
  const _UrgentChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded, size: 12, color: AppColors.rejected),
          const SizedBox(width: 2),
          Text(
            'Urgent',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.rejected),
          ),
        ],
      ),
    );
  }
}

/// Tanggal, jam (hanya cuti per jam), dan durasi dalam satu panel.
class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.entry});

  final LeaveHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final cells = <_InfoCell>[
      _InfoCell(icon: Icons.calendar_today_outlined, label: 'Date', value: entry.dateOnly),
      if (entry.timeRange != null)
        _InfoCell(icon: Icons.schedule_rounded, label: 'Time', value: entry.timeRange!),
      if (entry.durationLabel != null)
        _InfoCell(icon: Icons.hourglass_bottom_rounded, label: 'Duration', value: entry.durationLabel!),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) Container(width: 1, color: AppColors.border),
              Expanded(flex: i == 0 ? 3 : 2, child: cells[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.3, color: AppColors.text),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final isPdf = name.toLowerCase().endsWith('.pdf');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
              size: 18,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
