import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/item_request_entry.dart';
import '../../domain/item_request_status.dart';
import 'item_request_parts.dart';

/// Satu baris di daftar "Request Items" — mengemas kolom tabel web (Request
/// Code, Requestor, Item, Quantity, Reason, Status, Action) jadi satu kartu.
///
/// - Zona 1: nama + kode request | badge status (+ menu ⋮).
/// - Zona 2: avatar + nama peminta (+ "You") | jumlah dalam chip.
/// - Zona 3: alasan, atau "-" bila tidak diisi (+ kotak alasan penolakan).
/// - Tanpa ikon barang dan tanpa garis berwarna; status lewat badge saja.
///
/// Edit / Cancel ada di menu ⋮ di samping badge status (bukan tombol besar)
/// dan hanya muncul bila server mengizinkan ([ItemRequestEntry.canEdit]
/// / [ItemRequestEntry.canCancel]), yaitu request milik sendiri yang
/// masih pending.
class ItemRequestRow extends StatelessWidget {
  const ItemRequestRow({
    super.key,
    required this.item,
    this.onEdit,
    this.onCancel,
    this.onTap,
  });

  final ItemRequestEntry item;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  /// Ketuk kartu: buka halaman detail.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showEdit = item.canEdit && onEdit != null;
    final showCancel = item.canCancel && onCancel != null;
    final rejected = item.status.code == ItemRequestStatus.codeRejected;

    return ItemRequestCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zona 1: nama + kode, status (+ menu ⋮).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: ItemRequestStatusPill(status: item.status),
              ),
              if (showEdit || showCancel)
                _ActionsMenu(
                  onEdit: showEdit ? onEdit : null,
                  onCancel: showCancel ? onCancel : null,
                )
              else
                const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 10),
          // Zona 2: peminta | jumlah.
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              children: [
                ItemRequestAvatar(name: item.requesterName),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.requesterName.isEmpty ? '-' : item.requesterName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMid,
                          ),
                        ),
                      ),
                      if (item.isMine) ...[
                        const SizedBox(width: 6),
                        const ItemRequestYouBadge(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ItemRequestQuantityChip(label: item.quantityLabel),
              ],
            ),
          ),
          // Zona 3: alasan; "-" bila tidak diisi.
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
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
              ],
            ),
          ),
          if (rejected && item.rejectReason != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _RejectReason(text: item.rejectReason!),
            ),
          ],
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
