import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/indent_request_item.dart';

/// Satu baris di tab "List of User Requests" — mengemas 10 kolom tabel web
/// (No, Name, Destination, Date, Remark, Vehicle, Approve, Status, Driver,
/// Action) jadi satu kartu ringkas, sama seperti `EstRequestRow`.
///
/// Urutan di kartu: siapa & mau ke mana (utama) → kapan & untuk apa →
/// kendaraan & driver → dua badge status (+ bintang kalau sudah Done).
class IndentRequestRow extends StatelessWidget {
  const IndentRequestRow({
    super.key,
    required this.item,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final IndentRequestItem item;
  final VoidCallback? onTap;

  /// Menu Edit / Delete cuma muncul selama request belum di-approve
  /// ([IndentRequestItem.canModify]) dan callback-nya diisi.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  bool get _showMenu => item.canModify && (onEdit != null || onDelete != null);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: nama
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (_showMenu) _ActionMenu(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
          const SizedBox(height: 6),

          // Baris 2: tujuan
          _InfoLine(icon: Icons.place_outlined, text: item.destination),
          const SizedBox(height: 4),

          // Baris 3: tanggal + jam
          _InfoLine(
            icon: Icons.event_outlined,
            text: '${item.date}  ·  ${item.timeRange}',
          ),
          const SizedBox(height: 8),

          // Baris 4: remark
          Text(
            item.remark,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Baris 5: kendaraan & driver
          Row(
            children: [
              Expanded(
                child: _InfoLine(
                  icon: Icons.directions_car_outlined,
                  text: item.vehicle ?? '-',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoLine(
                  icon: Icons.person_outline,
                  text: item.driver ??
                      (item.withDriver
                          ? 'Driver not assigned yet'
                          : 'No driver'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Baris 6: badge Approve & Status (+ rating bila Done)
          Row(
            children: [
              _LabeledPill(
                caption: 'Approve',
                label: item.approve.label,
                color: item.approve.color,
                background: item.approve.background,
              ),
              const SizedBox(width: 8),
              _LabeledPill(
                caption: 'Status',
                label: item.status.label,
                color: item.status.color,
                background: item.status.background,
              ),
              const Spacer(),
              if (item.rating != null) _Stars(rating: item.rating!),
            ],
          ),
        ],
      ),
    );
  }
}

enum _RowAction { edit, delete }

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 24,
      child: PopupMenuButton<_RowAction>(
        padding: EdgeInsets.zero,
        tooltip: 'Options',
        icon: Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
        // Putih polos + hilangkan tint hijau bawaan Material 3.
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.border),
        ),
        // Default lebar minimum menu 112px; dikecilkan supaya pas.
        constraints: const BoxConstraints(minWidth: 0),
        onSelected: (action) {
          switch (action) {
            case _RowAction.edit:
              onEdit?.call();
            case _RowAction.delete:
              onDelete?.call();
          }
        },
        itemBuilder: (_) => [
          if (onEdit != null)
            _item(_RowAction.edit, Icons.edit_outlined, 'Edit', AppColors.text),
          if (onDelete != null)
            _item(
              _RowAction.delete,
              Icons.delete_outline,
              'Delete',
              AppColors.hseRequest,
            ),
        ],
      ),
    );
  }

  PopupMenuItem<_RowAction> _item(
    _RowAction value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Badge kecil dengan caption di atasnya, supaya jelas mana "Approve" dan
/// mana "Status" — di web ini dua kolom terpisah, di kartu tidak ada
/// header kolom, jadi caption-nya yang menggantikan.
class _LabeledPill extends StatelessWidget {
  const _LabeledPill({
    required this.caption,
    required this.label,
    required this.color,
    required this.background,
  });

  final String caption;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption,
          style: AppTextStyles.caption.copyWith(
            fontSize: 9.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 15,
            color: AppColors.accent,
          ),
      ],
    );
  }
}
