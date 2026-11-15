// lib/features/aod/always_on_screen.dart
// "الشاشة الدائمة": clock, date and next prayer shown when the phone is locked.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/alarm_bridge.dart';
import '../../data/settings/settings_repository.dart';

/// Accent colours offered for the always-on screen.
const alwaysOnColorKeys = ['green', 'gold', 'white', 'blue'];

Color alwaysOnColor(String key) {
  switch (key) {
    case 'gold':
      return const Color(0xFFC9A86A);
    case 'white':
      return const Color(0xFFFFFFFF);
    case 'blue':
      return const Color(0xFF5B9BD5);
    default:
      return AppColors.nightPrimary;
  }
}

class AlwaysOnConfig {
  final bool enabled;
  final String dateMode; // none | gregorian | hijri | both
  final double textScale; // 1.0 | 1.3 | 1.6
  final double brightness; // 0.02 .. 0.30
  final bool showPrayers;
  final int timeoutMin; // 0 = until unlock
  final int clockStyle; // 0 digital | 1 classic | 2 minimal | 3 boxed
  final bool arabicNumerals;
  final String colorKey; // green | gold | white | blue
  final String showWhen; // always | adhan | charging | schedule
  final int beforeAdhanMin;
  final int afterAdhanMin;
  final int scheduleFromMin; // minutes since midnight
  final int scheduleToMin;

  const AlwaysOnConfig({
    this.enabled = false,
    this.dateMode = 'both',
    this.textScale = 1.3,
    this.brightness = 0.08,
    this.showPrayers = true,
    this.timeoutMin = 10,
    this.clockStyle = 0,
    this.arabicNumerals = false,
    this.colorKey = 'green',
    this.showWhen = 'always',
    this.beforeAdhanMin = 10,
    this.afterAdhanMin = 15,
    this.scheduleFromMin = 22 * 60,
    this.scheduleToMin = 6 * 60,
  });

  AlwaysOnConfig copyWith({
    bool? enabled,
    String? dateMode,
    double? textScale,
    double? brightness,
    bool? showPrayers,
    int? timeoutMin,
    int? clockStyle,
    bool? arabicNumerals,
    String? colorKey,
    String? showWhen,
    int? beforeAdhanMin,
    int? afterAdhanMin,
    int? scheduleFromMin,
    int? scheduleToMin,
  }) =>
      AlwaysOnConfig(
        enabled: enabled ?? this.enabled,
        dateMode: dateMode ?? this.dateMode,
        textScale: textScale ?? this.textScale,
        brightness: brightness ?? this.brightness,
        showPrayers: showPrayers ?? this.showPrayers,
        timeoutMin: timeoutMin ?? this.timeoutMin,
        clockStyle: clockStyle ?? this.clockStyle,
        arabicNumerals: arabicNumerals ?? this.arabicNumerals,
        colorKey: colorKey ?? this.colorKey,
        showWhen: showWhen ?? this.showWhen,
        beforeAdhanMin: beforeAdhanMin ?? this.beforeAdhanMin,
        afterAdhanMin: afterAdhanMin ?? this.afterAdhanMin,
        scheduleFromMin: scheduleFromMin ?? this.scheduleFromMin,
        scheduleToMin: scheduleToMin ?? this.scheduleToMin,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'dateMode': dateMode,
        'textScale': textScale,
        'brightness': brightness,
        'showPrayers': showPrayers,
        'timeoutMin': timeoutMin,
        'clockStyle': clockStyle,
        'arabicNumerals': arabicNumerals,
        'colorKey': colorKey,
        'showWhen': showWhen,
        'beforeAdhanMin': beforeAdhanMin,
        'afterAdhanMin': afterAdhanMin,
        'scheduleFromMin': scheduleFromMin,
        'scheduleToMin': scheduleToMin,
      };

  factory AlwaysOnConfig.fromJson(Map<String, dynamic> j) => AlwaysOnConfig(
        enabled: j['enabled'] as bool? ?? false,
        dateMode: j['dateMode'] as String? ?? 'both',
        textScale: (j['textScale'] as num?)?.toDouble() ?? 1.3,
        brightness: (j['brightness'] as num?)?.toDouble() ?? 0.08,
        showPrayers: j['showPrayers'] as bool? ?? true,
        timeoutMin: (j['timeoutMin'] as num?)?.toInt() ?? 10,
        clockStyle: ((j['clockStyle'] as num?)?.toInt() ?? 0).clamp(0, 3).toInt(),
        arabicNumerals: j['arabicNumerals'] as bool? ?? false,
        colorKey: j['colorKey'] as String? ?? 'green',
        showWhen: j['showWhen'] as String? ?? 'always',
        beforeAdhanMin: (j['beforeAdhanMin'] as num?)?.toInt() ?? 10,
        afterAdhanMin: (j['afterAdhanMin'] as num?)?.toInt() ?? 15,
        scheduleFromMin: (j['scheduleFromMin'] as num?)?.toInt() ?? 22 * 60,
        scheduleToMin: (j['scheduleToMin'] as num?)?.toInt() ?? 6 * 60,
      );
}

class AlwaysOnNotifier extends StateNotifier<AlwaysOnConfig> {
  AlwaysOnNotifier(this._ref) : super(const AlwaysOnConfig()) {
    _load();
  }

  final Ref _ref;

  static const _key = 'always_on_config';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        state = AlwaysOnConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    await push();
  }

  Future<void> update(AlwaysOnConfig Function(AlwaysOnConfig) fn) async {
    state = fn(state);
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(state.toJson()));
    await push();
  }

  /// Send the config to the native service. The Hijri offset comes from the
  /// app-wide setting so the date matches the rest of the app.
  Future<void> push() async {
    await AlarmBridge.setAlwaysOn({
      ...state.toJson(),
      'color': alwaysOnColor(state.colorKey).value,
      'hijriOffset': _ref.read(appSettingsProvider).hijriOffset,
    });
  }
}

final alwaysOnProvider =
    StateNotifierProvider<AlwaysOnNotifier, AlwaysOnConfig>((ref) {
  final notifier = AlwaysOnNotifier(ref);
  ref.listen<int>(
    appSettingsProvider.select((s) => s.hijriOffset),
    (_, __) => notifier.push(),
  );
  return notifier;
});

class AlwaysOnScreen extends ConsumerStatefulWidget {
  const AlwaysOnScreen({super.key});

  @override
  ConsumerState<AlwaysOnScreen> createState() => _AlwaysOnScreenState();
}

class _AlwaysOnScreenState extends ConsumerState<AlwaysOnScreen>
    with WidgetsBindingObserver {
  Map<String, bool> _status = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final s = await AlarmBridge.alwaysOnStatus();
    if (mounted) setState(() => _status = s);
  }

  Widget _card(Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : AppColors.daySurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
      );

  Widget _hint(String t) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(t, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
      );

  Widget _choices<T>({
    required T value,
    required List<(T, String)> items,
    required ValueChanged<T> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final it in items)
          ChoiceChip(
            label: Text(it.$2, style: const TextStyle(fontFamily: 'Cairo')),
            selected: value == it.$1,
            onSelected: (_) => onChanged(it.$1),
          ),
      ],
    );
  }

  Widget _permRow(String title, String hint, bool? ok, String method) {
    final good = ok == true;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        good ? Icons.check_circle : Icons.error_outline,
        color: good ? Colors.green : Colors.orange,
      ),
      title: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
      subtitle: Text(hint, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
      trailing: good
          ? null
          : TextButton(
              onPressed: () => AlarmBridge.openSetting(method),
              child: const Text('تفعيل', style: TextStyle(fontFamily: 'Cairo')),
            ),
    );
  }

  // ─── When to show ──────────────────────────────────────────────────────────

  String _two(int v) => v.toString().padLeft(2, '0');
  String _hm(int minutes) => '${_two(minutes ~/ 60)}:${_two(minutes % 60)}';

  String _whenHint(String mode) {
    switch (mode) {
      case 'adhan':
        return 'تظهر فقط في الفترة المحيطة بكل أذان.';
      case 'charging':
        return 'تظهر فقط عندما يكون الهاتف موصولاً بالشاحن.';
      case 'schedule':
        return 'تظهر فقط ضمن الفترة الزمنية المحددة كل يوم.';
      default:
        return 'تظهر كلما انطفأت شاشة الهاتف.';
    }
  }

  Future<void> _pickTime(int current, ValueChanged<int> onPicked) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (t != null) onPicked(t.hour * 60 + t.minute);
  }

  Widget _whenCard(AlwaysOnConfig cfg, AlwaysOnNotifier n) {
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('طريقة التفعيل والظهور'),
        _choices<String>(
          value: cfg.showWhen,
          items: const [
            ('always', 'عند إطفاء الشاشة'),
            ('adhan', 'حول وقت الأذان'),
            ('charging', 'أثناء الشحن فقط'),
            ('schedule', 'جدول زمني'),
          ],
          onChanged: (v) => n.update((c) => c.copyWith(showWhen: v)),
        ),
        _hint(_whenHint(cfg.showWhen)),
        if (cfg.showWhen == 'adhan') ...[
          const SizedBox(height: 14),
          _title('قبل الأذان'),
          _choices<int>(
            value: cfg.beforeAdhanMin,
            items: const [
              (5, '5 دقائق'),
              (10, '10 دقائق'),
              (15, '15 دقيقة'),
              (30, '30 دقيقة'),
            ],
            onChanged: (v) => n.update((c) => c.copyWith(beforeAdhanMin: v)),
          ),
          const SizedBox(height: 14),
          _title('بعد الأذان'),
          _choices<int>(
            value: cfg.afterAdhanMin,
            items: const [
              (15, '15 دقيقة'),
              (30, '30 دقيقة'),
              (45, '45 دقيقة'),
              (60, 'ساعة'),
            ],
            onChanged: (v) => n.update((c) => c.copyWith(afterAdhanMin: v)),
          ),
        ],
        if (cfg.showWhen == 'schedule') ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bedtime_outlined, size: 18),
                label: Text('من ${_hm(cfg.scheduleFromMin)}',
                    style: const TextStyle(fontFamily: 'Cairo')),
                onPressed: () => _pickTime(cfg.scheduleFromMin,
                    (m) => n.update((c) => c.copyWith(scheduleFromMin: m))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                label: Text('إلى ${_hm(cfg.scheduleToMin)}',
                    style: const TextStyle(fontFamily: 'Cairo')),
                onPressed: () => _pickTime(cfg.scheduleToMin,
                    (m) => n.update((c) => c.copyWith(scheduleToMin: m))),
              ),
            ),
          ]),
        ],
      ],
    ));
  }

  // ─── Clock look ────────────────────────────────────────────────────────────

  Widget _clockTile(
    AlwaysOnConfig cfg,
    AlwaysOnNotifier n,
    int index,
    String label,
    TextStyle sample, {
    bool boxed = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final selected = cfg.clockStyle == index;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    Widget time = Text(
      cfg.arabicNumerals ? '١٢:٣٤' : '12:34',
      textDirection: TextDirection.ltr,
      style: sample.copyWith(fontSize: 18, color: textColor),
    );
    if (boxed) {
      time = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: textColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: time,
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => n.update((c) => c.copyWith(clockStyle: index)),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? primary.withOpacity(0.15)
                : (isDark ? AppColors.nightElevated : AppColors.dayChip),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              time,
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lookCard(AlwaysOnConfig cfg, AlwaysOnNotifier n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('شكل الساعة'),
        Row(children: [
          _clockTile(cfg, n, 0, 'رقمي عصري',
              const TextStyle(fontWeight: FontWeight.w800)),
          _clockTile(cfg, n, 1, 'خط كلاسيكي',
              const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
          _clockTile(cfg, n, 2, 'بسيط ناعم',
              const TextStyle(fontWeight: FontWeight.w300)),
          _clockTile(cfg, n, 3, 'إطار هندسي',
              const TextStyle(
                  fontFamily: 'monospace', fontWeight: FontWeight.bold),
              boxed: true),
        ]),
        const SizedBox(height: 18),
        _title('نوع الأرقام'),
        _choices<bool>(
          value: cfg.arabicNumerals,
          items: const [(false, 'لاتينية 123'), (true, 'عربية ١٢٣')],
          onChanged: (v) => n.update((c) => c.copyWith(arabicNumerals: v)),
        ),
        const SizedBox(height: 18),
        _title('لون الإضاءة'),
        Row(
          children: [
            for (final key in alwaysOnColorKeys)
              GestureDetector(
                onTap: () => n.update((c) => c.copyWith(colorKey: key)),
                child: Container(
                  margin: const EdgeInsetsDirectional.only(end: 12),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: alwaysOnColor(key),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cfg.colorKey == key
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey.withOpacity(0.4),
                      width: cfg.colorKey == key ? 2.5 : 1,
                    ),
                  ),
                  child: cfg.colorKey == key
                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                      : null,
                ),
              ),
          ],
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(alwaysOnProvider);
    final n = ref.read(alwaysOnProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الشاشة الدائمة', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تفعيل الشاشة الدائمة',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                subtitle: const Text(
                  'عند إطفاء الشاشة تظهر الساعة والتاريخ والصلاة القادمة بسطوع منخفض. '
                  'تستهلك بطارية أكثر من الوضع العادي.',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                ),
                value: cfg.enabled,
                activeColor: primary,
                onChanged: (v) async {
                  await n.update((c) => c.copyWith(enabled: v));
                  if (v && _status['overlay'] != true) {
                    AlarmBridge.openSetting('requestDrawOverApps');
                  }
                },
              ),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await n.push();
                      AlarmBridge.previewAlwaysOn();
                    },
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('معاينة', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ),
              ]),
            ],
          )),
          _whenCard(cfg, n),
          _lookCard(cfg, n),
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('التاريخ'),
              _choices<String>(
                value: cfg.dateMode,
                items: const [
                  ('none', 'بدون'),
                  ('gregorian', 'ميلادي'),
                  ('hijri', 'هجري'),
                  ('both', 'الاثنان'),
                ],
                onChanged: (v) => n.update((c) => c.copyWith(dateMode: v)),
              ),
              _hint('يتبع التاريخ الهجري إزاحة الأيام المضبوطة في: الإعدادات ← الموقع وحساب المواقيت.'),
            ],
          )),
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('حجم الكتابة'),
              _choices<double>(
                value: cfg.textScale,
                items: const [(1.0, 'عادي'), (1.3, 'كبير'), (1.6, 'كبير جداً')],
                onChanged: (v) => n.update((c) => c.copyWith(textScale: v)),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('عرض الصلوات الخمس',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
                value: cfg.showPrayers,
                activeColor: primary,
                onChanged: (v) => n.update((c) => c.copyWith(showPrayers: v)),
              ),
            ],
          )),
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('السطوع (${(cfg.brightness * 100).round()}%)'),
              Slider(
                value: cfg.brightness.clamp(0.02, 0.3),
                min: 0.02,
                max: 0.3,
                divisions: 14,
                onChanged: (v) => n.update((c) => c.copyWith(brightness: v)),
              ),
              const Text(
                'سقف منخفض عمداً لحماية شاشة AMOLED. العناصر تتحرك ببطء باستمرار لمنع الحرق.',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
              ),
              const SizedBox(height: 14),
              _title('مدة العرض بعد إطفاء الشاشة'),
              _choices<int>(
                value: cfg.timeoutMin,
                items: const [(5, '5 دقائق'), (10, '10 دقائق'), (30, '30 دقيقة'), (0, 'حتى فتح القفل')],
                onChanged: (v) => n.update((c) => c.copyWith(timeoutMin: v)),
              ),
            ],
          )),
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('الأذونات المطلوبة'),
              _permRow('الظهور فوق التطبيقات',
                  'يلزم ليفتح التطبيق الشاشة بعد القفل', _status['overlay'],
                  'requestDrawOverApps'),
              _permRow('عرض بملء الشاشة', 'بديل عند منع الفتح من الخلفية',
                  _status['fullScreenIntent'], 'openFullScreenIntentSettings'),
              _permRow('استثناء توفير البطارية', 'حتى لا يوقف النظام الخدمة',
                  _status['battery'], 'openBatterySettings'),
              if (_status['miui'] == true)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.phone_android),
                  title: const Text('أذونات شاومي', style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
                  subtitle: const Text(
                    'فعّل: "العرض على شاشة القفل" و"النوافذ المنبثقة أثناء التشغيل في الخلفية" و"التشغيل التلقائي".',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                  ),
                  trailing: TextButton(
                    onPressed: () => AlarmBridge.openSetting('openMiuiPermissions'),
                    child: const Text('فتح', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ),
            ],
          )),
        ],
      ),
    );
  }
}
