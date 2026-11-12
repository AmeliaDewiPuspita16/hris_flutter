import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/stationery_item_option.dart';
import '../../domain/stationery_request_item.dart';
import '../../domain/stationery_request_status.dart';
import 'stationery_action_button.dart';
import 'stationery_request_parts.dart';

/// Membuka sheet detail satu request
///
/// Tombol dibawah sheet hanya muncul untuk callback yang diisi:
/// - [onApprove] / [onReject]: dari tab Verification.
/// - [onEdit] / [onCancel]: dari tab Request, untuk request milik sendiri
///   yang masih pending.
/// Tanpa satupun callback, sheet hanya untuk dibaca.
Future<void> showStationeryDetailSheet(
  BuildContext context,
  StationeryRequestItem item, {
  VoidCallback? onEdit,
  VoidCallback? onCancel,
  VoidCallback? onApprove,
  VoidCallback? onReject,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StationeryDetailSheet(
      item: item,
      onEdit: onEdit,
      onCancel: onCancel,
      onApprove: onApprove,
      onReject: onReject,
    ),
  );
}

class StationeryDetailSheet extends StatelessWidget {
  const StationeryDetailSheet(
      {super.key,
      required this.item,
      this.onEdit,
      this.onCancel,
      this.onApprove,
      this.onReject});

  final StationeryRequestItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  /// Tutup sheet, lalu jalankan [action].
  void _run(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final rejected = item.status.code == StationeryRequestStatus.codeRejected;
    final hasDecision = onApprove != null || onReject != null;
    final hasOwnActions = onEdit != null || onCancel != null;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text('Request Detail', style: AppTextStyles.sectionTitle),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 20, color: AppColors.textMid),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Bagian yang bisa digulir; tombol aksi di bawah tetap terlihat.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.code,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        StationeryStatusPill(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Section(
                      title: 'Request',
                      children: [
                        _Field(
                          label: 'Requestor',
                          child: Row(
                            children: [
                              StationeryAvatar(name: item.requesterName, size: 26),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  item.requesterName.isEmpty ? '-' : item.requesterName,
                                  style: AppTextStyles.body
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (item.isMine) ...[
                                const SizedBox(width: 6),
                                const StationeryYouBadge(),
                              ],
                            ],
                          ),
                        ),
                        _Field(
                          label: 'Requested on',
                          child: Text(item.requestedAtLabel, style: AppTextStyles.body),
                        ),
                        _Field(
                          label: 'Reason',
                          child: _TextBox(
                            text: item.reasonLabel,
                            muted: !item.hasReason,
                          ),
                        ),
                        if (rejected && item.rejectReason != null)
                          _Field(
                            label: 'Rejection note',
                            child: _TextBox(text: item.rejectReason!, danger: true),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Item',
                      children: [
                        _Field(
                          label: 'Item name',
                          child: Text(
                            item.itemName,
                            style: AppTextStyles.body
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _Field(
                          label: 'Item code',
                          child: Text(item.itemCode, style: AppTextStyles.body),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Field(
                                label: 'Quantity',
                                child: StationeryQuantityChip(label: item.quantityLabel),
                              ),
                            ),
                            Expanded(
                              child: _Field(
                                label: 'Current stock',
                                child: _StockValue(item: item),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (hasDecision || hasOwnActions) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: StationeryActionButton(
                        label: 'Reject',
                        icon: Icons.close_rounded,
                        filled: false,
                        onPressed: () => _run(context, onReject!),
                      ),
                    ),
                  if (onCancel != null)
                    Expanded(
                      child: StationeryActionButton(
                        label: 'Cancel request',
                        icon: Icons.close_rounded,
                        filled: false,
                        onPressed: () => _run(context, onCancel!),
                      ),
                    ),
                  if ((onReject != null || onCancel != null) &&
                      (onApprove != null || onEdit != null))
                    const SizedBox(width: 10),
                  if (onApprove != null)
                    Expanded(
                      child: StationeryActionButton(
                        label: 'Approve',
                        icon: Icons.check_rounded,
                        filled: true,
                        onPressed: () => _run(context, onApprove!),
                      ),
                    ),
                  if (onEdit != null)
                    Expanded(
                      child: StationeryActionButton(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        filled: true,
                        onPressed: () => _run(context, onEdit!),
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


/// Kotak bergaris berisi satu kelompok info, dengan judul kecil di atasnya
/// ("REQUEST", "ITEM") seperti dua kartu di modal web.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Divider(height: 14, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }
}

/// Satu pasang label kecil (huruf besar, abu-abu) di atas nilainya.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

/// Teks panjang dalam kotak lembut (alasan, catatan penolakan).
class _TextBox extends StatelessWidget {
  const _TextBox({required this.text, this.muted = false, this.danger = false});

  final String text;
  final bool muted;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: danger ? AppColors.rejectedBg : AppColors.neutralBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          height: 1.4,
          color: danger
              ? AppColors.rejected
              : (muted ? AppColors.textMuted : AppColors.text),
        ),
      ),
    );
  }
}

/// Stok saat ini. Merah dengan ikon peringatan bila request yang masih pending
/// meminta lebih banyak dari stok.
class _StockValue extends StatelessWidget {
  const _StockValue({required this.item});

  final StationeryRequestItem item;

  @override
  Widget build(BuildContext context) {
    final stock = item.stock;
    if (stock == null) return Text('-', style: AppTextStyles.body);

    final short = item.status.isPending && item.quantity > stock;
    final color = short ? AppColors.rejected : AppColors.text;
    final stockText = formatInventoryQuantity(stock);
    final label = item.unit.isEmpty ? stockText : '$stockText ${item.unit}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (short) ...[
          Icon(Icons.warning_amber_rounded, size: 15, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: color,
            fontWeight: short ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
