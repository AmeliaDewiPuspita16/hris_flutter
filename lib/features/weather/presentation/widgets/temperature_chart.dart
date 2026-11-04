import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/weather_forecast.dart';

/// Grafik garis suhu per slot: kurva halus berisi gradasi di bawahnya,
/// titik tiap slot, garis "Now", dan label hari di sumbu X.
///
/// Digambar sendiri dengan [CustomPainter] — cukup untuk satu seri data,
/// tanpa menambah dependensi chart.
class TemperatureChart extends StatelessWidget {
  const TemperatureChart({
    super.key,
    required this.slots,
    required this.now,
    this.height = 180,
  });

  final List<WeatherSlot> slots;
  final DateTime now;
  final double height;

  @override
  Widget build(BuildContext context) {
    final temps = slots.map((s) => '${s.tempC}°').join(', ');
    return Semantics(
      label: 'Temperature chart: $temps',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _TemperaturePainter(
            slots: slots,
            now: now,
            line: AppColors.primary,
            dot: AppColors.solid(AppColors.orange),
            grid: AppColors.border,
            label: AppColors.textMuted,
            nowLine: AppColors.primaryText,
            card: AppColors.card,
          ),
        ),
      ),
    );
  }
}

class _TemperaturePainter extends CustomPainter {
  _TemperaturePainter({
    required this.slots,
    required this.now,
    required this.line,
    required this.dot,
    required this.grid,
    required this.label,
    required this.nowLine,
    required this.card,
  });

  final List<WeatherSlot> slots;
  final DateTime now;
  final Color line;
  final Color dot;
  final Color grid;
  final Color label;
  final Color nowLine;
  final Color card;

  static const _left = 28.0;
  static const _right = 8.0;
  static const _top = 18.0;
  static const _bottom = 24.0;

  TextPainter _text(String s, {double size = 10, FontWeight? weight, Color? color}) {
    return TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: size,
          fontWeight: weight,
          color: color ?? label,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (slots.length < 2) return;

    final temps = slots.map((s) => s.tempC);
    final minT = temps.reduce((a, b) => a < b ? a : b) - 1;
    final maxT = temps.reduce((a, b) => a > b ? a : b) + 1;

    final chart = Rect.fromLTRB(
      _left,
      _top,
      size.width - _right,
      size.height - _bottom,
    );

    final t0 = slots.first.time;
    final span = slots.last.time.difference(t0).inMinutes.toDouble();
    double xOf(DateTime t) =>
        chart.left + chart.width * (t.difference(t0).inMinutes / span);
    double yOf(num temp) =>
        chart.bottom - chart.height * ((temp - minT) / (maxT - minT));

    // Grid horizontal + label suhu (genap saja agar tidak padat).
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var t = minT; t <= maxT; t++) {
      if (t.isOdd) continue;
      final y = yOf(t);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final tp = _text('$t°');
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Pemisah & label hari tiap tengah malam.
    final dayFmt = DateFormat('EEE d', 'en_US');
    for (final slot in slots) {
      if (slot.time.hour != 0) continue;
      final x = xOf(slot.time);
      canvas.drawLine(
        Offset(x, chart.top),
        Offset(x, chart.bottom),
        gridPaint,
      );
      final tp = _text(dayFmt.format(slot.time), weight: FontWeight.w600);
      final dx = (x + 4).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(dx, chart.bottom + 6));
    }

    final points = [
      for (final s in slots) Offset(xOf(s.time), yOf(s.tempC)),
    ];

    // Kurva halus (Catmull-Rom → cubic Bézier).
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    final fill = Path.from(path)
      ..lineTo(points.last.dx, chart.bottom)
      ..lineTo(points.first.dx, chart.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [line.withValues(alpha: 0.22), line.withValues(alpha: 0)],
        ).createShader(chart),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Garis "Now".
    if (!now.isBefore(t0) && !now.isAfter(slots.last.time)) {
      final x = xOf(now);
      final dash = Paint()
        ..color = nowLine
        ..strokeWidth = 1.2;
      for (var y = chart.top; y < chart.bottom; y += 6) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 3), dash);
      }
      final tp = _text('Now', weight: FontWeight.w700, color: nowLine);
      final dx = (x - tp.width / 2).clamp(chart.left, size.width - tp.width);
      tp.paint(canvas, Offset(dx, 0));
    }

    // Titik tiap slot.
    final dotFill = Paint()..color = dot;
    final dotRing = Paint()..color = card;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotRing);
      canvas.drawCircle(p, 2.8, dotFill);
    }
  }

  @override
  bool shouldRepaint(_TemperaturePainter old) =>
      old.slots != slots || old.now != now || old.line != line;
}
