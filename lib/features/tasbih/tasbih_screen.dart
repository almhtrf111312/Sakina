import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/alarm_bridge.dart';
import '../../data/settings/settings_repository.dart';

/// Suggested Azkar phrases for the electronic Tasbih
class TasbihPhrase {
  final String text;
  final String virtue;
  final int defaultGoal;

  const TasbihPhrase({
    required this.text,
    required this.virtue,
    required this.defaultGoal,
  });
}

const List<TasbihPhrase> _suggestedPhrases = [
  TasbihPhrase(
    text: 'سُبْحَانَ اللَّهِ',
    virtue: 'تَمْلَأُ نِصْفَ الْمِيزَانِ',
    defaultGoal: 33,
  ),
  TasbihPhrase(
    text: 'الْحَمْدُ لِلَّهِ',
    virtue: 'تَمْلَأُ الْمِيزَانَ',
    defaultGoal: 33,
  ),
  TasbihPhrase(
    text: 'اللَّهُ أَكْبَرُ',
    virtue: 'خَيْرٌ مِمَّا طَلَعَتْ عَلَيْهِ الشَّمْسُ',
    defaultGoal: 34,
  ),
  TasbihPhrase(
    text: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    virtue: 'مَنْ لَزِمَ الِاسْتِغْفَارَ جَعَلَ اللَّهُ لَهُ مِنْ كُلِّ ضِيقٍ مَخْرَجًا',
    defaultGoal: 100,
  ),
  TasbihPhrase(
    text: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    virtue: 'أَفْضَلُ مَا قُلْتُ أَنَا وَالنَّبِيُّونَ مِنْ قَبْلِي',
    defaultGoal: 100,
  ),
  TasbihPhrase(
    text: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    virtue: 'مَنْ صَلَّى عَلَيَّ صَلَاةً صَلَّى اللَّهُ عَلَيْهِ بِهَا عَشْرًا',
    defaultGoal: 100,
  ),
  TasbihPhrase(
    text: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    virtue: 'كَنْزٌ مِنْ كُنُوزِ الْجَنَّةِ',
    defaultGoal: 33,
  ),
];

class TasbihScreen extends ConsumerStatefulWidget {
  const TasbihScreen({super.key});

  @override
  ConsumerState<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends ConsumerState<TasbihScreen> with SingleTickerProviderStateMixin {
  int _counter = 0;
  int _targetGoal = 33;
  int _roundsCompleted = 0;
  int _dailyTotal = 0;
  int _weeklyTotal = 0;

  int _selectedPhraseIndex = 0;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _loadStats();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _dailyKey(DateTime day) =>
      'sakina_tasbih_daily_${day.year}_${day.month}_${day.day}';

  DateTime? _statsDay;

  void _loadStats() {
    final prefs = ref.read(sharedPreferencesProvider);
    _counter = prefs.getInt(AppConstants.keyTasbihCount) ?? 0;
    _targetGoal = prefs.getInt(AppConstants.keyTasbihTarget) ?? 33;
    _roundsCompleted = prefs.getInt('sakina_tasbih_rounds') ?? 0;
    _selectedPhraseIndex = (prefs.getInt('sakina_tasbih_phrase') ?? 0)
        .clamp(0, _suggestedPhrases.length - 1);
    _refreshCalendarTotals();
  }

  void _refreshCalendarTotals() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_statsDay == today) return;
    _statsDay = today;
    final prefs = ref.read(sharedPreferencesProvider);
    _dailyTotal = prefs.getInt(_dailyKey(today)) ?? 0;
    _weeklyTotal = 0;
    for (var daysAgo = 0; daysAgo < today.weekday; daysAgo++) {
      final day = DateTime(today.year, today.month, today.day - daysAgo);
      _weeklyTotal += prefs.getInt(_dailyKey(day)) ?? 0;
    }
  }

  Future<void> _saveStats() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await Future.wait([
      prefs.setInt(AppConstants.keyTasbihCount, _counter),
      prefs.setInt(AppConstants.keyTasbihTarget, _targetGoal),
      prefs.setInt(_dailyKey(_statsDay!), _dailyTotal),
      prefs.setInt('sakina_tasbih_rounds', _roundsCompleted),
      prefs.setInt('sakina_tasbih_phrase', _selectedPhraseIndex),
    ]);
  }

  void _increment() {
    final settings = ref.read(appSettingsProvider);
    final completed = _counter + 1 >= _targetGoal;
    AlarmBridge.tapFeedback(
      sound: settings.tapSound,
      haptic: settings.tapHaptic,
      volume: settings.tapVolume,
      intensity: settings.tapHapticIntensity,
      completion: completed,
    );

    _pulseController.forward().then((_) => _pulseController.reverse());

    setState(() {
      _refreshCalendarTotals();
      _counter++;
      _dailyTotal++;
      _weeklyTotal++;

      if (_counter >= _targetGoal) {
        _roundsCompleted++;
        _counter = 0;
        _showGoalCompletionCelebration();
      }
    });

    _saveStats();
  }

  void _showGoalCompletionCelebration() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amber),
            const SizedBox(width: 8),
            Flexible(child: Text(
              'ما شاء الله! اكتمل الهدف ($_targetGoal) - دورة رقم $_roundsCompleted',
              style: const TextStyle(fontFamily: AppConstants.fontCairo),
            )),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2A9D8F),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تصفير المسبحة',
          style: TextStyle(fontFamily: AppConstants.fontCairo, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل تريد إعادة تصفير العداد الحالي؟ (لن يتم حذف إجمالي اليوم والأسبوع)',
          style: TextStyle(fontFamily: AppConstants.fontCairo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: AppConstants.fontCairo)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _counter = 0;
              });
              _saveStats();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('تصفير', style: TextStyle(fontFamily: AppConstants.fontCairo, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCustomGoalDialog() {
    final textController = TextEditingController(text: '$_targetGoal');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تحديد عدد التسبيحات',
          style: TextStyle(fontFamily: AppConstants.fontCairo, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'العدد المطلوب',
            hintText: 'مثال: 50 أو 500',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: AppConstants.fontCairo)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(textController.text.trim());
              if (val != null && val > 0) {
                setState(() {
                  _targetGoal = val;
                  _counter = 0;
                });
                _saveStats();
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: AppConstants.fontCairo)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedbackSettings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentPhrase = _suggestedPhrases[_selectedPhraseIndex];
    final progress = _targetGoal > 0 ? (_counter / _targetGoal).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'السبحة الإلكترونية',
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              feedbackSettings.tapHaptic ? Icons.vibration_rounded : Icons.phone_android_rounded,
              color: feedbackSettings.tapHaptic
                  ? (isDark ? AppColors.nightPrimary : AppColors.dayPrimary)
                  : theme.disabledColor,
            ),
            tooltip: feedbackSettings.tapHaptic ? 'إيقاف الاهتزاز' : 'تشغيل الاهتزاز',
            onPressed: () {
              ref.read(settingsNotifierProvider.notifier).update(
                  (s) => s.copyWith(tapHaptic: !s.tapHaptic));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تصفير العداد',
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggested Azkar Horizontal Carousel
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestedPhrases.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final phrase = _suggestedPhrases[index];
                final isSelected = _selectedPhraseIndex == index;

                return ChoiceChip(
                  label: Text(
                    phrase.text,
                    style: TextStyle(
                      fontFamily: AppConstants.fontAmiri,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: isDark ? AppColors.nightPrimary : AppColors.dayPrimary,
                  backgroundColor: theme.cardColor,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPhraseIndex = index;
                        _targetGoal = phrase.defaultGoal;
                        _counter = 0;
                      });
                      _saveStats();
                    }
                  },
                );
              },
            ),
          ),

          // Virtue subtitle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              currentPhrase.virtue,
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 12,
                color: (isDark ? AppColors.nightSecondary : AppColors.daySecondary),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Goal presets selector (33, 99, 100, مخصص)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGoalChip(33),
                const SizedBox(width: 8),
                _buildGoalChip(99),
                const SizedBox(width: 8),
                _buildGoalChip(100),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.edit_rounded, size: 14),
                  label: Text(
                    _isCustomGoal() ? '$_targetGoal' : 'مخصص',
                    style: const TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: _showCustomGoalDialog,
                ),
              ],
            ),
          ),

          // Giant Tap Area & Circular Progress Ring
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _increment,
              child: Center(
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: CustomPaint(
                    painter: _TasbihRingPainter(
                      progress: progress,
                      trackColor: theme.dividerColor.withOpacity(0.12),
                      progressColor: isDark ? AppColors.nightPrimary : AppColors.dayPrimary,
                      accentColor: isDark ? AppColors.nightSecondary : AppColors.daySecondary,
                    ),
                    child: Container(
                      width: 250,
                      height: 250,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_counter',
                            style: TextStyle(
                              fontFamily: AppConstants.fontCairo,
                              fontSize: 68,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: isDark ? AppColors.nightPrimary : AppColors.dayPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'الهدف: $_targetGoal',
                              style: TextStyle(
                                fontFamily: AppConstants.fontCairo,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'اضغط في أي مكان للتسبيح',
                            style: TextStyle(
                              fontFamily: AppConstants.fontCairo,
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Stats Banner: Daily Total & Rounds Completed
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('الدورات', '$_roundsCompleted', Icons.replay_rounded),
                Container(width: 1, height: 36, color: theme.dividerColor.withOpacity(0.15)),
                _buildStatItem('تسبيح اليوم', '$_dailyTotal', Icons.today_rounded),
                Container(width: 1, height: 36, color: theme.dividerColor.withOpacity(0.15)),
                _buildStatItem('تسبيح الأسبوع', '$_weeklyTotal', Icons.date_range_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isCustomGoal() => _targetGoal != 33 && _targetGoal != 99 && _targetGoal != 100;

  Widget _buildGoalChip(int goal) {
    final isSelected = _targetGoal == goal;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(
        '$goal',
        style: TextStyle(
          fontFamily: AppConstants.fontCairo,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
        ),
      ),
      selected: isSelected,
      selectedColor: isDark ? AppColors.nightPrimary : AppColors.dayPrimary,
      backgroundColor: theme.cardColor,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _targetGoal = goal;
            _counter = 0;
          });
          _saveStats();
        }
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.textTheme.bodySmall?.color?.withOpacity(0.6)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the glowing circular progress ring with bead notches
class _TasbihRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color accentColor;

  _TasbihRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..strokeCap = StrokeCap.round;

      final startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );

      // Glowing tip
      final tipAngle = startAngle + sweepAngle;
      final tipOffset = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );
      final tipGlow = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tipOffset, 7.0, tipGlow);
    }

    // 33 decorative bead marks around the ring
    final beadMarkPaint = Paint()
      ..color = trackColor.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 33; i++) {
      final angle = (2 * math.pi / 33) * i - math.pi / 2;
      final beadOffset = Offset(
        center.dx + (radius + 14) * math.cos(angle),
        center.dy + (radius + 14) * math.sin(angle),
      );
      canvas.drawCircle(beadOffset, 1.8, beadMarkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TasbihRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
