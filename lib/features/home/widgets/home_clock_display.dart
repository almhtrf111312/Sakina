import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../providers/home_providers.dart';

/// Main screen styles share the same prayer data and global time format.
class HomeClockDisplay extends StatelessWidget {
  const HomeClockDisplay({super.key, required this.style, required this.data});
  final int style;
  final NextPrayerProgress data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final countdown = FittedBox(fit: BoxFit.scaleDown, child: Text(
      data.formattedCountdown, textDirection: TextDirection.ltr,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold)));
    if (style == 1) {
      return Column(children: [
        const Text('المتبقي على الأذان'),
        const SizedBox(height: 12), countdown,
        const SizedBox(height: 16),
        LinearProgressIndicator(value: data.progress, minHeight: 6,
            borderRadius: BorderRadius.circular(8)),
      ]);
    }
    if (style == 2) {
      return Column(children: [
        const HomeAnalogClock(), const SizedBox(height: 6),
        const Text('المتبقي على الأذان'), countdown,
      ]);
    }
    return SizedBox(width: 142, height: 142, child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: CircularProgressIndicator(
          value: data.progress, strokeWidth: 8,
          backgroundColor: colors.primary.withOpacity(.12),
          strokeCap: StrokeCap.round)),
        Padding(padding: const EdgeInsets.all(14), child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const Text('المتبقي على الأذان', textAlign: TextAlign.center),
            const SizedBox(height: 8), countdown],
        )),
      ],
    ));
  }
}

class HomeAnalogClock extends StatefulWidget {
  const HomeAnalogClock({super.key});
  @override
  State<HomeAnalogClock> createState() => _HomeAnalogClockState();
}

class _HomeAnalogClockState extends State<HomeAnalogClock> {
  late final Timer _timer;
  DateTime _now = DateTime.now();
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }
  @override
  void dispose() { _timer.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'ساعة تناظرية ${_now.hour}:${_now.minute}',
    child: CustomPaint(size: const Size(116, 116), painter: _ClockPainter(
        _now, Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.onSurface)),
  );
}

class _ClockPainter extends CustomPainter {
  _ClockPainter(this.time, this.accent, this.ink);
  final DateTime time;
  final Color accent;
  final Color ink;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 5;
    final paint = Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 3;
    canvas.drawCircle(center, radius, paint);
    Offset point(double angle, double length) => center +
        Offset(math.sin(angle), -math.cos(angle)) * length;
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      canvas.drawLine(point(angle, radius - 12), point(angle, radius - 5), paint);
    }
    void hand(double angle, double length, double width, Color color) {
      paint..color = color..strokeWidth = width..strokeCap = StrokeCap.round;
      canvas.drawLine(center, point(angle, length), paint);
    }
    hand((time.hour % 12 + time.minute / 60) * math.pi / 6, radius * .5, 6, ink);
    hand((time.minute + time.second / 60) * math.pi / 30, radius * .72, 4, ink);
    hand(time.second * math.pi / 30, radius * .8, 2, accent);
    canvas.drawCircle(center, 4, Paint()..color = accent);
  }
  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      old.time != time || old.accent != accent || old.ink != ink;
}
