/// Formatters for the stock opname screens (English, short month names).

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatShortDate(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${d.year}';

String formatQty(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

String formatShortDateTime(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${formatShortDate(d)}, $hh:$mm';
}
