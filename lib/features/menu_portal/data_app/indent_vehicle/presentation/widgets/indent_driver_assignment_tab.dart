import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/indent_assigned_item.dart';

/// Isi tab "My Assignments": perjalanan yang ditugaskan ke driver yang
/// sedang login, masing-masing dengan tombol Finish untuk menutup request
/// setelah perjalanan selesai. Tarik ke bawah untuk memuat ulang; berlaku
/// juga saat daftar kosong.
class IndentDriverAssignmentTab extends StatelessWidget {
  const IndentDriverAssignmentTab({
    super.key,
    required this.items,
    required this.onRefresh,
    required this.onFinish,
  });

  final List<IndentAssignedItem> items;
  final Future<void> Function() onRefresh;

  /// Dipanggil saat Finish ditekan. Konfirmasi dan pemanggilan server
  /// dilakukan pemanggil; kartu menampilkan loading selama Future berjalan.
  final Future<void> Function(IndentAssignedItem item) onFinish;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          // ListView (bukan Center saja) supaya tarik-untuk-refresh tetap
          // bisa dipakai saat daftar kosong.
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'No trips assigned to you',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _AssignedCard(
                item: items[index],
                onFinish: () => onFinish(items[index]),
              ),
            ),
    );
  }
}

class _AssignedCard extends StatefulWidget {
  const _AssignedCard({required this.item, required this.onFinish});

  final IndentAssignedItem item;
  final Future<void> Function() onFinish;

  @override
  State<_AssignedCard> createState() => _AssignedCardState();
}

class _AssignedCardState extends State<_AssignedCard> {
  bool _busy = false;

  Future<void> _finish() async {
    setState(() => _busy = true);
    await widget.onFinish();
    // Kartu bisa sudah dibuang dari daftar bila Finish berhasil.
    if (mounted) setState(() => _busy = false);
  }

  /// Inisial untuk lingkaran di kiri: huruf depan kata pertama dan terakhir.
  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final vehicle = item.vehicle;
    final dayState = item.dayState();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _initials(item.name),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tanpa label ini nama bisa dikira nama driver sendiri.
                    Text(
                      'Requested by',
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.destination,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (vehicle != null) ...[
                const SizedBox(width: 8),
                _PlateChip(plate: vehicle),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Tanggal dan jam berdampingan, masing-masing separuh lebar.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Detail(
                    icon: Icons.event_outlined,
                    label: 'Date',
                    value: item.date,
                    badge: _DayBadge(state: dayState),
                  ),
                ),
                Expanded(
                  child: _Detail(
                    icon: Icons.schedule_outlined,
                    label: 'Time',
                    value: item.timeRange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Purpose',
            style: AppTextStyles.caption.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 1),
          Text(
            item.remark,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              height: 1.4,
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _finish,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: Text(
                'Finish Trip',
                style: AppTextStyles.buttonText.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlateChip extends StatelessWidget {
  const _PlateChip({required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.directions_car_outlined,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            plate,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Penanda kecil di sebelah label, mis. "Today".
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    badge!,
                  ],
                ],
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Penanda posisi tanggal: Overdue (terlewat tapi belum ditutup), Today,
/// Tomorrow. Tanggal yang lebih jauh tidak diberi penanda.
class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.state});

  final IndentDayState state;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    final Color background;

    switch (state) {
      case IndentDayState.overdue:
        label = 'Overdue';
        color = AppColors.pending;
        background = AppColors.pendingBg;
        break;
      case IndentDayState.today:
        label = 'Today';
        color = AppColors.present;
        background = AppColors.presentBg;
        break;
      case IndentDayState.tomorrow:
        label = 'Tomorrow';
        color = AppColors.inProgress;
        background = AppColors.inProgressBg;
        break;
      case IndentDayState.upcoming:
      case IndentDayState.unknown:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
