import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Highly optimized, custom-painted Islamic compass widget.
/// Renders the rotating degree dial, cardinal points, Kaaba direction marker,
/// and golden pointing needle with alignment glow effect.
class CompassWidget extends StatelessWidget {
  const CompassWidget({
    super.key,
    required this.heading,
    required this.qiblaBearing,
    required this.isAligned,
    this.size = 280.0,
  });

  /// Device's current heading in degrees from true North (0..360)
  final double heading;

  /// Absolute Qibla direction in degrees from true North (0..360)
  final double qiblaBearing;

  /// Whether the device is currently facing Qibla within threshold (±3°)
  final bool isAligned;

  /// Diameter of the compass circle
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Angle of dial rotation (counter-rotate dial by device heading)
    final dialRotation = -heading * (math.pi / 180.0);

    // Angle of Qibla pointer relative to device top
    final relativeQiblaDeg = (qiblaBearing - heading);
    final qiblaPointerAngle = relativeQiblaDeg * (math.pi / 180.0);

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow ring: only changes when the alignment state changes.
            RepaintBoundary(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isAligned
                          ? AppColors.success.withOpacity(0.4)
                          : (isDark
                                  ? AppColors.nightSecondary
                                  : AppColors.daySecondary)
                              .withOpacity(0.15),
                      blurRadius: isAligned ? 35 : 18,
                      spreadRadius: isAligned ? 4 : 0,
                    ),
                  ],
                ),
              ),
            ),

            // Rotating dial: painted once and cached, only re-composited.
            Transform.rotate(
              angle: dialRotation,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _CompassDialPainter(
                    isDark: isDark,
                    isAligned: isAligned,
                    qiblaBearing: qiblaBearing,
                  ),
                ),
              ),
            ),

            // Needle pointing to Qibla relative to the device.
            Transform.rotate(
              angle: qiblaPointerAngle,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _QiblaNeedlePainter(
                    isAligned: isAligned,
                    isDark: isDark,
                  ),
                ),
              ),
            ),

            // Center hub with Kaaba indicator
            RepaintBoundary(child: _buildCenterHub(context, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterHub(BuildContext context, bool isDark) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isAligned
              ? [const Color(0xFF2A9D8F), const Color(0xFF4CAF88)]
              : (isDark
                  ? [AppColors.nightElevated, AppColors.nightSurface]
                  : [AppColors.daySurface, AppColors.dayBackground]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isAligned
              ? Colors.white
              : (isDark ? AppColors.nightSecondary : AppColors.daySecondary),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: isAligned
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
            : Icon(
                Icons.mosque_rounded,
                color: isDark ? AppColors.nightSecondary : AppColors.daySecondary,
                size: 26,
              ),
      ),
    );
  }
}

/// Custom painter for the compass dial (degree ticks, cardinal labels, Kaaba badge)
class _CompassDialPainter extends CustomPainter {
  final bool isDark;
  final bool isAligned;
  final double qiblaBearing;

  _CompassDialPainter({
    required this.isDark,
    required this.isAligned,
    required this.qiblaBearing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = isDark ? AppColors.nightChip : AppColors.dayChip
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, bgPaint);

    // Outer border
    final borderPaint = Paint()
      ..color = isAligned
          ? AppColors.success
          : (isDark ? AppColors.nightSecondary.withOpacity(0.5) : AppColors.daySecondary.withOpacity(0.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAligned ? 3.0 : 1.5;
    canvas.drawCircle(center, radius - 2, borderPaint);

    // Inner subtle guide ring
    final innerRingPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 28, innerRingPaint);

    // Degree ticks
    final majorTickPaint = Paint()
      ..color = isDark ? Colors.white70 : Colors.black87
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final minorTickPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.25)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (int deg = 0; deg < 360; deg += 5) {
      final rad = deg * (math.pi / 180.0) - math.pi / 2;
      final isCardinal = deg % 90 == 0;
      final isMajor = deg % 30 == 0;
      final tickLength = isCardinal ? 14.0 : (isMajor ? 9.0 : 5.0);

      final outerX = center.dx + (radius - 4) * math.cos(rad);
      final outerY = center.dy + (radius - 4) * math.sin(rad);
      final innerX = center.dx + (radius - 4 - tickLength) * math.cos(rad);
      final innerY = center.dy + (radius - 4 - tickLength) * math.sin(rad);

      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        isMajor ? majorTickPaint : minorTickPaint,
      );
    }

    // Cardinal Points (N, E, S, W / ش، ق، ج، غ)
    _drawCardinal(canvas, center, radius - 22, 0, 'شمال\nN', const Color(0xFFE63946), isBold: true);
    _drawCardinal(canvas, center, radius - 22, 90, 'شرق\nE', isDark ? Colors.white70 : Colors.black87);
    _drawCardinal(canvas, center, radius - 22, 180, 'جنوب\nS', isDark ? Colors.white70 : Colors.black87);
    _drawCardinal(canvas, center, radius - 22, 270, 'غرب\nW', isDark ? Colors.white70 : Colors.black87);

    // Kaaba Marker on the perimeter dial at absolute Qibla bearing
    final qiblaRad = qiblaBearing * (math.pi / 180.0) - math.pi / 2;
    final kaabaOffset = Offset(
      center.dx + (radius - 14) * math.cos(qiblaRad),
      center.dy + (radius - 14) * math.sin(qiblaRad),
    );

    final kaabaBadgePaint = Paint()
      ..color = AppColors.nightSecondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(kaabaOffset, 7.0, kaabaBadgePaint);

    final kaabaInnerPaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(kaabaOffset, 4.0, kaabaInnerPaint);
  }

  void _drawCardinal(
    Canvas canvas,
    Offset center,
    double r,
    double degrees,
    String text,
    Color color, {
    bool isBold = false,
  }) {
    final rad = degrees * (math.pi / 180.0) - math.pi / 2;
    final offset = Offset(
      center.dx + r * math.cos(rad),
      center.dy + r * math.sin(rad),
    );

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        fontFamily: AppConstants.fontCairo,
        height: 1.0,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.isAligned != isAligned ||
        oldDelegate.qiblaBearing != qiblaBearing;
  }
}

/// Custom painter for the Qibla golden needle pointing upwards towards Mecca
class _QiblaNeedlePainter extends CustomPainter {
  final bool isAligned;
  final bool isDark;

  _QiblaNeedlePainter({
    required this.isAligned,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final needleLength = size.width / 2 - 38;

    final primaryGold = isAligned
        ? AppColors.success
        : (isDark ? const Color(0xFFD4AF37) : AppColors.daySecondary);

    // Top arrow pointing up towards Qibla
    final needlePath = Path();
    needlePath.moveTo(center.dx, center.dy - needleLength); // Arrow tip
    needlePath.lineTo(center.dx + 11, center.dy - 35);
    needlePath.lineTo(center.dx, center.dy - 25);
    needlePath.lineTo(center.dx - 11, center.dy - 35);
    needlePath.close();

    final needlePaint = Paint()
      ..color = primaryGold
      ..style = PaintingStyle.fill;
    canvas.drawPath(needlePath, needlePaint);

    // Left shading for 3D needle effect
    final shadowPath = Path();
    shadowPath.moveTo(center.dx, center.dy - needleLength);
    shadowPath.lineTo(center.dx - 11, center.dy - 35);
    shadowPath.lineTo(center.dx, center.dy - 25);
    shadowPath.close();

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawPath(shadowPath, shadowPaint);

    // Subtle opposite tail pointer (North-South counterweight)
    final tailPath = Path();
    tailPath.moveTo(center.dx, center.dy + needleLength * 0.45);
    tailPath.lineTo(center.dx + 6, center.dy + 35);
    tailPath.lineTo(center.dx - 6, center.dy + 35);
    tailPath.close();

    final tailPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(tailPath, tailPaint);
  }

  @override
  bool shouldRepaint(covariant _QiblaNeedlePainter oldDelegate) {
    return oldDelegate.isAligned != isAligned || oldDelegate.isDark != isDark;
  }
}
