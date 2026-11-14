import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/prayer/prayer_repository.dart';
import 'aod_settings_screen.dart';

// ─── Color helpers ────────────────────────────────────────────────────────────

Color _aodColorValue(AodColor c) {
  switch (c) {
    case AodColor.green:
      return const Color(0xFF5FB59B);
    case AodColor.gold:
      return const Color(0xFFC9A86A);
    case AodColor.white:
      return Colors.white;
    case AodColor.blue:
      return const Color(0xFF5B9BD5);
  }
}

// ─── Prayer model (local) ─────────────────────────────────────────────────────

class _PrayerEntry {
  final String name;
  final String abbr;
  final String time;
  final bool passed;
  const _PrayerEntry(this.name, this.abbr, this.time, this.passed);
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class AodPreviewScreen extends ConsumerStatefulWidget {
  const AodPreviewScreen({super.key});

  @override
  ConsumerState<AodPreviewScreen> createState() => _AodPreviewScreenState();
}

class _AodPreviewScreenState extends ConsumerState<AodPreviewScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  static const _names = {
    'Fajr': ['الفجر', 'فجر'],
    'Dhuhr': ['الظهر', 'ظهر'],
    'Asr': ['العصر', 'عصر'],
    'Maghrib': ['المغرب', 'مغرب'],
    'Isha': ['العشاء', 'عشاء'],
  };

  List<_PrayerEntry> _prayers = const [];
  DateTime? _nextAt;

  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Builds today's five prayers from real data; the next one may be tomorrow's Fajr.
  void _loadPrayers(List<DayPrayerTimes> days) {
    final now = DateTime.now();
    DayPrayerTimes? today;
    DayPrayerTimes? tomorrow;
    for (final d in days) {
      final l = d.date.toLocal();
      if (l.year == now.year && l.month == now.month && l.day == now.day) {
        today = d;
      } else if (today != null && tomorrow == null) {
        tomorrow = d;
      }
    }
    today ??= days.isNotEmpty ? days.first : null;
    if (today == null) return;
    final list = <_PrayerEntry>[];
    DateTime? next;
    var nextIdx = -1;
    var i = 0;
    for (final key in _names.keys) {
      final t = today.times[key]?.toLocal();
      if (t == null) continue;
      final passed = t.isBefore(now);
      if (!passed && next == null) {
        next = t;
        nextIdx = i;
      }
      list.add(_PrayerEntry(_names[key]![0], _names[key]![1], _hm(t), passed));
      i++;
    }
    if (next == null && tomorrow != null) {
      final f = tomorrow.times['Fajr']?.toLocal();
      if (f != null) {
        next = f;
        nextIdx = 0;
      }
    }
    _prayers = list;
    _nextAt = next;
    _nextIdx = nextIdx < 0 ? 0 : nextIdx;
  }

  int _nextIdx = 0;
  int get _nextPrayerIndex =>
      _prayers.isEmpty ? 0 : _nextIdx.clamp(0, _prayers.length - 1);

  Duration get _countdownToNext {
    final t = _nextAt;
    if (t == null) return Duration.zero;
    final diff = t.difference(_now);
    return diff.isNegative ? Duration.zero : diff;
  }

  String get _hijriDate {
    // Real implementation uses hijri package; here we show a fixed demo
    return '١٢ ربيع الأول ١٤٤٦';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(aodSettingsProvider);
    final color = _aodColorValue(settings.color);
    final dimColor = color.withOpacity(0.45);
    final days = ref.watch(prayerTimesProvider).valueOrNull;
    if (days != null) _loadPrayers(days);
    if (_prayers.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF5FB59B)),
          ),
        ),
      );
    }
    final countdown = _countdownToNext;
    final nextPrayer = _prayers[_nextPrayerIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            // Top row: time + hijri
            if (settings.showClock || settings.showHijriDate)
              Positioned(
                top: MediaQuery.of(context).padding.top + 24,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    if (settings.showClock)
                      Text(
                        _formatTime(_now),
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 22,
                          color: dimColor,
                          letterSpacing: 2,
                        ),
                      ),
                    if (settings.showHijriDate)
                      Text(
                        _hijriDate,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: dimColor,
                        ),
                      ),
                  ],
                ),
              ),

            // Center: next prayer
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nextPrayer.name,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 56,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextPrayer.time,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 32,
                      color: color.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, color: dimColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _formatCountdown(countdown),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          color: dimColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom: 5 prayers row
            if (settings.showPrayersRow)
              Positioned(
                bottom: 48,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_prayers.length, (i) {
                    final p = _prayers[i];
                    final isNext = i == _nextPrayerIndex;
                    final isPassed = p.passed;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.abbr,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: isNext ? 15 : 13,
                            color: isNext
                                ? color
                                : isPassed
                                    ? color.withOpacity(0.35)
                                    : color.withOpacity(0.6),
                            fontWeight: isNext
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: isNext ? 24 : 16,
                          height: 2,
                          decoration: BoxDecoration(
                            color: isNext
                                ? color
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),

            // Battery indicator (top-right)
            if (settings.showBattery)
              Positioned(
                top: MediaQuery.of(context).padding.top + 24,
                right: 20,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.battery_charging_full,
                        color: dimColor, size: 16),
                    const SizedBox(width: 2),
                    Text('78%',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: dimColor)),
                  ],
                ),
              ),

            // "Tap to close" hint
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Text(
                'اضغط للخروج من المعاينة',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: color.withOpacity(0.25)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
