import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/back_header.dart';
import '../../domain/app_notification.dart';
import '../../domain/notification_filter.dart';
import '../../domain/notification_category.dart';
import '../widgets/notification_action_type_filter.dart';
import '../widgets/notification_filter_tabs.dart';
import '../widgets/notification_tile.dart';

/// Halaman Notifications.
///
/// Daftarnya dipegang pemanggil ([notifications]) dan setiap perubahan
/// dilaporkan lewat [onChanged], supaya titik penanda di lonceng Beranda
/// ikut bergerak saat notifikasi dibaca atau diputuskan di sini.
///
/// Tampilannya sengaja dibuat rata: satu daftar putih tanpa kartu, dengan
/// filter sebagai tab bergaris bawah di atas ([NotificationFilterTabs])
/// alih-alih deretan chip pil. Notifikasi yang butuh keputusan tidak lagi
/// memakai kartu berbeda — cuma naik ke kelompok paling atas dan
/// menumbuhkan sepasang tombol kecil di barisnya sendiri.
///
/// Layar ini sekarang menjadi tab di bottom nav ([showBack] = false). Karena
/// tab tetap hidup di `IndexedStack`, ia menyalin ulang daftar dari
/// pemanggil setiap kali [notifications] berganti (lihat [didUpdateWidget]).
class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({
    super.key,
    required this.notifications,
    required this.onChanged,
    this.initialFilter = NotificationFilter.all,
    this.showBack = true,
    this.filterRequestToken = 0,
    this.onAssign,
    this.onOpen,
    this.onRefresh,
  });

  final List<AppNotification> notifications;
  final ValueChanged<List<AppNotification>> onChanged;

  /// Filter yang aktif saat layar ini dibuka — dipakai banner approval di
  /// Beranda untuk masuk langsung ke "Action" alih-alih "All".
  final NotificationFilter initialFilter;

  /// False saat dipakai sebagai tab — header tanpa tombol kembali.
  final bool showBack;

  /// Sebagai tab, layar ini dibuat sekali dan tidak dibuka ulang, jadi
  /// [initialFilter] saja tidak cukup untuk "lompat ke Action" dari banner
  /// Beranda. Naikkan angka ini setiap kali pemanggil ingin filter
  /// [initialFilter] diterapkan lagi.
  final int filterRequestToken;

  /// Dipanggil saat tombol "Assign" di notifikasi bertipe assign ditekan.
  /// Pemanggil yang membuka sheet dan mengirim ke server; hasilnya kembali
  /// lewat [notifications]/[onChanged] seperti keputusan biasa.
  final ValueChanged<AppNotification>? onAssign;

  /// Dipanggil saat sebuah notifikasi di-tap, setelah ditandai sudah dibaca.
  /// Pemanggil yang membuka layar tujuannya ([AppNotification.link]).
  final ValueChanged<AppNotification>? onOpen;

  /// Tarik ke bawah untuk memuat ulang notifikasi dari server. Null = daftar
  /// tidak bisa ditarik.
  final Future<void> Function()? onRefresh;

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  late List<AppNotification> _items = List.of(widget.notifications);
  late NotificationFilter _filter = widget.initialFilter;

  /// Sub-filter jenis tindakan di tab Action. Null = semua jenis.
  NotificationCategory? _actionCategory;

  @override
  void didUpdateWidget(NotifikasiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.notifications, widget.notifications)) {
      _items = List.of(widget.notifications);
    }
    if (oldWidget.filterRequestToken != widget.filterRequestToken) {
      _filter = widget.initialFilter;
      _actionCategory = null;
    }
  }

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

  void _open(AppNotification notification) {
    if (!notification.isRead) _markRead(notification.id);
    widget.onOpen?.call(notification);
  }

  /// Keputusan sekaligus menandai sudah dibaca — begitu diputuskan,
  /// notifikasinya turun dari kelompok "Perlu tindakan".
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

  /// Angka per filter = berapa yang belum dibaca, bukan total.
  Map<NotificationFilter, int> get _unreadCounts => {
        for (final filter in NotificationFilter.values)
          filter: _items.where((n) => filter.matches(n) && !n.isRead).length,
      };

  /// Kategori yang ada di daftar Action beserta jumlahnya, urutan kemunculan.
  Map<NotificationCategory, int> get _actionOptions {
    final counts = <NotificationCategory, int>{};
    for (final item in _items.where(NotificationFilter.action.matches)) {
      counts.update(item.category, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final actionOptions = _actionOptions;
    // Dropdown cuma berguna kalau ada lebih dari satu jenis. Pilihan yang
    // jenisnya sudah habis (semua sudah diputuskan) dianggap "All types".
    final showTypeFilter =
        _filter == NotificationFilter.action && actionOptions.length > 1;
    final category = showTypeFilter && actionOptions.containsKey(_actionCategory)
        ? _actionCategory
        : null;

    final visible = _items
        .where(_filter.matches)
        .where((n) => category == null || n.category == category)
        .toList();
    final pending = visible.where((n) => n.needsAction).toList();
    final rest = visible.where((n) => !n.needsAction).toList();

    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: BackHeader(
        title: 'Notifications',
        onBack: widget.showBack ? () => Navigator.of(context).pop() : null,
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
          NotificationFilterTabs(
            selected: _filter,
            counts: _unreadCounts,
            onSelected: (filter) => setState(() => _filter = filter),
          ),
          if (showTypeFilter)
            NotificationActionTypeFilter(
              options: actionOptions,
              selected: category,
              onSelected: (value) => setState(() => _actionCategory = value),
            ),
          Expanded(
            child: _withRefresh(
              visible.isEmpty
                  ? const _EmptyState()
                  : _NotificationList(
                      pending: pending,
                      rest: rest,
                      onDecide: _decide,
                      onAssign: widget.onAssign,
                      onOpen: _open,
                      onDismiss: _dismiss,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _withRefresh(Widget child) {
    final onRefresh = widget.onRefresh;
    if (onRefresh == null) return child;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      // Keadaan kosong bukan daftar yang bisa di-scroll, jadi dibungkus
      // supaya tetap bisa ditarik.
      child: child is _NotificationList
          ? child
          : LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: constraints.maxHeight, child: child),
              ),
            ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.pending,
    required this.rest,
    required this.onDecide,
    required this.onAssign,
    required this.onOpen,
    required this.onDismiss,
  });

  final List<AppNotification> pending;
  final List<AppNotification> rest;
  final void Function(String id, NotificationDecision decision) onDecide;
  final ValueChanged<AppNotification>? onAssign;
  final ValueChanged<AppNotification> onOpen;
  final ValueChanged<String> onDismiss;

  /// Mengelompokkan sisa notifikasi per hari, urutannya dipertahankan.
  Map<String, List<AppNotification>> get _grouped {
    final groups = <String, List<AppNotification>>{};
    for (final item in rest) {
      groups
          .putIfAbsent(DateFormatter.dayGroup(item.createdAt), () => [])
          .add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        if (pending.isNotEmpty) ...[
          const _GroupLabel('Action needed'),
          for (final item in pending)
            NotificationTile(
              notification: item,
              onTap: () => onOpen(item),
              onDecide: (decision) => onDecide(item.id, decision),
              onAssign: onAssign == null ? null : () => onAssign!(item),
            ),
        ],
        for (final entry in _grouped.entries) ...[
          _GroupLabel(entry.key),
          for (final item in entry.value)
            // Notifikasi informasi boleh digeser untuk dibuang; yang masih
            // menunggu keputusan sengaja tidak, supaya tidak terhapus tanpa
            // sengaja sebelum ditindaklanjuti.
            Dismissible(
              key: ValueKey(item.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => onDismiss(item.id),
              background: const _DismissBackground(),
              child: NotificationTile(
                notification: item,
                onTap: () => onOpen(item),
              ),
            ),
        ],
      ],
    );
  }
}

/// Pemisah antar kelompok. Bukan judul tebal berjarak lebar — cuma penanda
/// kecil, karena isinya yang harus dibaca, bukan labelnya.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
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
            const Icon(
              Icons.notifications_none,
              size: 34,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'No notifications yet',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'New updates will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
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
