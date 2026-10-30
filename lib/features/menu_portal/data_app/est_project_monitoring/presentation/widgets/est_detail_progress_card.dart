import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/executive_dashboard.dart';
import 'est_detail_format.dart';

/// Kartu progres jam: lingkaran persentase, rincian jam, dan bar progres.
class EstDetailProgressCard extends StatelessWidget {
  const EstDetailProgressCard({super.key, required this.project});

  final ExecutiveProjectModel project;

  @override
  Widget build(BuildContext context) {
    final color = estProgressColor(project.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: estCardDecoration(radius: 20, blur: 10),
      child: Row(
        children: [
          _CircularProgress(percent: project.progress, color: color),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HourRow(
                  label: 'Budget Jam',
                  value: '${estFmtHours(project.budgetHours.toDouble())} jam',
                  color: AppColors.textSub,
                ),
                const SizedBox(height: 12),
                _HourRow(
                  label: 'Terpakai',
                  value: '${estFmtHours(project.usedHours)} jam',
                  color: color,
                  bold: true,
                ),
                const SizedBox(height: 12),
                _HourRow(
                  label: 'Sisa',
                  value: '${estFmtHours(project.remainingHours)} jam',
                  color: project.remainingHours > 0
                      ? AppColors.primaryText
                      : AppColors.rejected,
                  bold: true,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: project.progress,
                    backgroundColor: AppColors.bg,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${project.progressPercent}% jam terpakai',
                  style: TextStyle(fontSize: 11, color: AppColors.textSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgress extends StatelessWidget {
  const _CircularProgress({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(100, 100),
            painter: _CirclePainter(
              percent: percent.clamp(0.0, 1.0),
              color: color,
              bgColor: AppColors.bg,
              strokeWidth: 10,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(percent * 100).round()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Terpakai',
                style: TextStyle(fontSize: 9, color: AppColors.textSub),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  _CirclePainter({
    required this.percent,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  final double percent;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    paint.color = bgColor;
    canvas.drawCircle(center, radius, paint);
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.percent != percent || old.color != color || old.bgColor != bgColor;
}

class _HourRow extends StatelessWidget {
  const _HourRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSub),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
