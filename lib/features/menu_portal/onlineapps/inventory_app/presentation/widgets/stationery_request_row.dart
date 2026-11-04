import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/stationery_request_item.dart';
import '../../domain/stationery_request_status.dart';
import 'stationery_item_icon.dart';
import 'stationery_request_parts.dart';

/// Satu baris di daftar "Request Items" — mengemas kolom tabel web (Request
/// Code, Requestor, Item, Quantity, Reason, Status, Action) jadi satu kartu.
///
/// - Kiri: ikon barang (gaya tile IMS Document).
/// - Baris 1: nama barang | badge status (+ menu ⋮ bila ada aksi).
/// - Baris 2: kode request · peminta | jumlah (teks tebal tanpa latar).
/// - Baris 3: alasan, atau "-" bila tidak diisi.
/// - Border kartu mengikuti warna status.
///
/// Edit / Cancel ada di menu ⋮ di samping badge status (bukan tombol besar)
/// dan hanya muncul bila server mengizinkan ([StationeryRequestItem.canEdit]
/// / [StationeryRequestItem.canCancel]), yaitu request milik sendiri yang
/// masih pending.
class StationeryRequestRow extends StatelessWidget {
  const StationeryRequestRow({
    super.key,
    required this.item,
    this.onEdit,
    this.onCancel,
  });

  final StationeryRequestItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final showEdit = item.canEdit && onEdit != null;
    final showCancel = item.canCancel && onCancel != null;
    final rejected = item.status.code == StationeryRequestStatus.codeRejected;

    return StationeryCard(
      borderColor: item.status.color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StationeryItemIcon(itemName: item.itemName, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris 1: nama barang | status (+ menu ⋮)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        item.itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(status: item.status),
                    if (showEdit || showCancel)
                      _ActionsMenu(
                        onEdit: showEdit ? onEdit : null,
                        onCancel: showCancel ? onCancel : null,
                      )
                    else
                      const SizedBox(width: 2),
                  ],
                ),
                const SizedBox(height: 2),
                // Baris 2: kode · peminta | jumlah
                Row(
                  children: [
                    Expanded(
                      child: StationeryMetaLine(
                        code: item.code,
                        requester: item.requesterName,
                        isMine: item.isMine,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StationeryQuantityText(label: item.quantityLabel),
                    const SizedBox(width: 2),
                  ],
                ),
                // Baris 3: alasan; "-" bila tidak diisi
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Text(
                    item.reasonLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      height: 1.4,
                      color: item.hasReason ? null : AppColors.textMuted,
                    ),
                  ),
                ),
                if (rejected && item.rejectReason != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: _RejectReason(text: item.rejectReason!),
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

enum _RowAction { edit, cancel }

/// Menu ⋮ berisi Edit dan/atau Cancel. Item yang tidak diizinkan server
/// tidak ditampilkan.
class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({this.onEdit, this.onCancel});

  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: PopupMenuButton<_RowAction>(
        tooltip: 'Actions',
        padding: EdgeInsets.zero,
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMid),
        onSelected: (action) {
          switch (action) {
            case _RowAction.edit:
              onEdit?.call();
            case _RowAction.cancel:
              onCancel?.call();
          }
        },
        itemBuilder: (_) => [
          if (onEdit != null)
            PopupMenuItem(
              value: _RowAction.edit,
              child: _MenuLabel(
                icon: Icons.edit_outlined,
                label: 'Edit',
                color: AppColors.text,
              ),
            ),
          if (onCancel != null)
            PopupMenuItem(
              value: _RowAction.cancel,
              child: _MenuLabel(
                icon: Icons.close_rounded,
                label: 'Cancel',
                color: AppColors.rejected,
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.body
              .copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Badge status: teks dari label server, warna dari [StationeryRequestStatus].
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final StationeryRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: status.color,
        ),
      ),
    );
  }
}

/// Alasan penolakan dari verifier, dalam kotak merah lembut.
class _RejectReason extends StatelessWidget {
  const _RejectReason({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: AppColors.rejected,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.rejected, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
