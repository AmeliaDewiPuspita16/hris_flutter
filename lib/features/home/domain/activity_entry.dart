import 'package:flutter/widgets.dart';

/// Satu baris di bagian "Aktivitas Terbaru".
class ActivityEntry {
  const ActivityEntry({
    required this.icon,
    required this.title,
    required this.description,
    required this.occurredAt,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String description;

  /// Kapan aktivitasnya terjadi. Dipakai untuk mengurutkan (terbaru di atas)
  /// dan untuk label waktu relatif — bukan teks jadi seperti "2 jam lalu",
  /// supaya label tetap benar kapan pun layar dibuka.
  final DateTime occurredAt;

  /// Warna ikon dan kotak di belakangnya.
  final Color color;
  final Color background;

  /// Label waktu relatif untuk ditampilkan, mis. "2 hours ago", "Yesterday".
  /// [now] hanya untuk test.
  String timeLabel([DateTime? now]) => formatRelativeTime(occurredAt, now: now);
}

/// Aturan "Recent Activity": hanya [maxVisible] aktivitas terbaru yang
/// tampil. Begitu ada aktivitas baru, yang paling lama otomatis keluar dari
/// daftar (tidak dihapus dari sumber datanya, hanya tidak ditampilkan).
class ActivityFeed {
  ActivityFeed._();

  /// Jumlah maksimum baris di Beranda.
  static const maxVisible = 4;

  /// [all] diurutkan dari yang terbaru, lalu dipotong sampai [limit].
  /// Urutan input tidak berpengaruh, dan list asli tidak diubah.
  static List<ActivityEntry> latest(
    Iterable<ActivityEntry> all, {
    int limit = maxVisible,
  }) {
    final sorted = all.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return sorted.take(limit).toList();
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Waktu relatif singkat: "Just now", "5 min ago", "2 hours ago",
/// "Yesterday", "3 days ago", lalu tanggal ("17 Jul") untuk seminggu ke
/// atas. Waktu di masa depan (jam perangkat tidak cocok dengan server)
/// diperlakukan sebagai "Just now".
String formatRelativeTime(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(time);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';

  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(time.year, time.month, time.day);
  final dayGap = today.difference(day).inDays;

  if (dayGap == 0) {
    final h = diff.inHours;
    return h == 1 ? '1 hour ago' : '$h hours ago';
  }
  if (dayGap == 1) return 'Yesterday';
  if (dayGap < 7) return '$dayGap days ago';
  return '${time.day} ${_months[time.month - 1]}';
}
