import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/item_request_entry.dart';
import '../../domain/item_request_status.dart';
import 'item_request_parts.dart';

/// Satu baris di daftar "Request Items" — mengemas kolom tabel web jadi satu
/// kartu yang lega:
///
/// - Atas: kode request (kecil, abu-abu) | badge status (+ menu ⋮).
/// - Tengah: nama barang (besar, tebal), lalu alasan bila diisi.
/// - Bawah: avatar + nama peminta (+ "You") dengan tanggal pengajuan di
///   bawahnya | jumlah dalam chip.
///
/// Alasan yang kosong tidak ditampilkan (tidak ada "-"), supaya kartu lebih
/// ringkas; detailnya tetap ada di sheet detail.
///
/// Edit / Cancel ada di menu ⋮ di samping badge status dan hanya muncul bila
/// server mengizinkan ([ItemRequestEntry.canEdit] / [ItemRequestEntry.canCancel]).
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
    final hasMenu = showEdit || showCancel;

    return ItemRequestCard(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(18, 16, hasMenu ? 8 : 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Atas: kode | status (+ menu ⋮).
          Row(
            children: [
              Expanded(
                child: Text(
                  item.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ItemRequestStatusPill(status: item.status),
              if (hasMenu)
                _ActionsMenu(
                  onEdit: showEdit ? onEdit : null,
                  onCancel: showCancel ? onCancel : null,
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(right: hasMenu ? 10 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Tengah: nama barang, lalu alasan.
                Text(
                  item.itemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                if (item.hasReason) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.reasonLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(height: 1.45),
                  ),
                ],
                if (rejected && item.rejectReason != null) ...[
                  const SizedBox(height: 10),
                  _RejectReason(text: item.rejectReason!),
                ],
                const SizedBox(height: 16),
                // Bawah: peminta + tanggal | jumlah.
                Row(
                  children: [
                    ItemRequestAvatar(name: item.requesterName, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.requesterName.isEmpty
                                      ? '-'
                                      : item.requesterName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                              if (item.isMine) ...[
                                const SizedBox(width: 6),
                                const ItemRequestYouBadge(),
                              ],
                            ],
                          ),
                          if (item.requestedAt != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              item.requestedAtLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ItemRequestQuantityChip(label: item.quantityLabel),
                  ],
                ),
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
