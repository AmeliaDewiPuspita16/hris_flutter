import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/back_header.dart';
import '../../domain/app_notification.dart';
import '../../domain/notification_filter.dart';
import '../widgets/action_needed_card.dart';
import '../widgets/notification_filter_chips.dart';
import '../widgets/notification_tile.dart';

/// Halaman Notifications.
///
/// Daftarnya dipegang pemanggil ([notifications]) dan setiap perubahan
/// dilaporkan lewat [onChanged], supaya titik penanda di lonceng Beranda
/// ikut bergerak saat notifikasi dibaca atau diputuskan di sini.
class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({
    super.key,
    required this.notifications,
    required this.onChanged,
  });

  final List<AppNotification> notifications;
  final ValueChanged<List<AppNotification>> onChanged;

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  late List<AppNotification> _items = List.of(widget.notifications);
  NotificationFilter _filter = NotificationFilter.all;

  void _update(List<AppNotification> next) {
    setState(() => _items = next);
    widget.onChanged(next);
  }

  void _replace(String id, AppNotification Function(AppNotification) change) {
    _update([
      for (final item in _items) item.id == id ? change(item) : item,
    ]);
  }

  void _markRead(String id) => _replace(id, (n) => n.copyWith(isRead: true));

  /// Keputusan sekaligus menandai sudah dibaca — begitu diputuskan,
  /// notifikasinya turun dari blok "Needs your action".
  void _decide(String id, NotificationDecision decision) {
    _replace(id, (n) => n.copyWith(decision: decision, isRead: true));
  }

  void _markAllRead() {
    _update([for (final item in _items) item.copyWith(isRead: true)]);
  }

  void _dismiss(String id) {
    _update([
      for (final item in _items)
        if (item.id != id) item,
    ]);
  }

  /// Angka di chip = berapa yang belum dibaca, bukan total. Chip yang sudah
  /// tuntas jadi polos, jadi mata langsung tertuju ke yang masih menumpuk.
  Map<NotificationFilter, int> get _unreadCounts => {
        for (final filter in NotificationFilter.values)
          filter: _items
              .where((n) => filter.matches(n) && !n.isRead)
              .length,
      };

  @override
  Widget build(BuildContext context) {
    final visible = _items.where(_filter.matches).toList();
    final pending = visible.where((n) => n.needsAction).toList();
    final rest = visible.where((n) => !n.needsAction).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Notifications',
        onBack: () => Navigator.of(context).pop(),
        trailing: InkWell(
          onTap: _markAllRead,
          child: const Icon(
            Icons.done_all,
            size: 19,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 14),
          NotificationFilterChips(
            selected: _filter,
            counts: _unreadCounts,
            onSelected: (filter) => setState(() => _filter = filter),
          ),
          Expanded(
            child: visible.isEmpty
                ? const _EmptyState()
                : _NotificationList(
                    pending: pending,
                    rest: rest,
                    onDecide: _decide,
                    onRead: _markRead,
                    onDismiss: _dismiss,
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.pending,
    required this.rest,
    required this.onDecide,
    required this.onRead,
    required this.onDismiss,
  });

  final List<AppNotification> pending;
  final List<AppNotification> rest;
  final void Function(String id, NotificationDecision decision) onDecide;
  final ValueChanged<String> onRead;
  final ValueChanged<String> onDismiss;

  /// Mengelompokkan sisa notifikasi per hari, urutannya dipertahankan.
  Map<String, List<AppNotification>> get _grouped {
    final groups = <String, List<AppNotification>>{};
    for (final item in rest) {
      groups.putIfAbsent(DateFormatter.dayGroup(item.createdAt), () => []).add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        if (pending.isNotEmpty) ...[
          const _GroupLabel('Needs your action'),
          const SizedBox(height: 10),
          for (final item in pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ActionNeededCard(
                notification: item,
                onDecide: (decision) => onDecide(item.id, decision),
              ),
            ),
          const SizedBox(height: 10),
        ],
        for (final entry in groups.entries) ...[
          _GroupLabel(entry.key),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  for (var i = 0; i < entry.value.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.border,
                      ),
                    // Notifikasi informasi boleh digeser untuk dibuang;
                    // yang menunggu keputusan sengaja tidak, supaya tidak
                    // terhapus tanpa sengaja sebelum ditindaklanjuti.
                    Dismissible(
                      key: ValueKey(entry.value[i].id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => onDismiss(entry.value[i].id),
                      background: const _DismissBackground(),
                      child: NotificationTile(
                        notification: entry.value[i],
                        onTap: () => onRead(entry.value[i].id),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.rejectedBg,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: 20),
          child: Icon(
            Icons.delete_outline,
            size: 20,
            color: AppColors.rejected,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neutralBg,
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 32,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nothing here',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You are all caught up. New updates will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
