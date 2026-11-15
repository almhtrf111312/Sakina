// lib/features/aod/always_on_screen.dart
// "الشاشة الدائمة": clock, date and next prayer shown when the phone is locked.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/alarm_bridge.dart';
import 'aod_settings_screen.dart';

class AlwaysOnConfig {
  final bool enabled;
  final String dateMode; // none | gregorian | hijri | both
  final double textScale; // 1.0 | 1.3 | 1.6
  final double brightness; // 0.02 .. 0.30
  final bool showPrayers;
  final int timeoutMin; // 0 = until unlock

  const AlwaysOnConfig({
    this.enabled = false,
    this.dateMode = 'both',
    this.textScale = 1.3,
    this.brightness = 0.08,
    this.showPrayers = true,
    this.timeoutMin = 10,
  });

  AlwaysOnConfig copyWith({
    bool? enabled,
    String? dateMode,
    double? textScale,
    double? brightness,
    bool? showPrayers,
    int? timeoutMin,
  }) =>
      AlwaysOnConfig(
        enabled: enabled ?? this.enabled,
        dateMode: dateMode ?? this.dateMode,
        textScale: textScale ?? this.textScale,
        brightness: brightness ?? this.brightness,
        showPrayers: showPrayers ?? this.showPrayers,
        timeoutMin: timeoutMin ?? this.timeoutMin,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'dateMode': dateMode,
        'textScale': textScale,
        'brightness': brightness,
        'showPrayers': showPrayers,
        'timeoutMin': timeoutMin,
      };

  factory AlwaysOnConfig.fromJson(Map<String, dynamic> j) => AlwaysOnConfig(
        enabled: j['enabled'] as bool? ?? false,
        dateMode: j['dateMode'] as String? ?? 'both',
        textScale: (j['textScale'] as num?)?.toDouble() ?? 1.3,
        brightness: (j['brightness'] as num?)?.toDouble() ?? 0.08,
        showPrayers: j['showPrayers'] as bool? ?? true,
        timeoutMin: (j['timeoutMin'] as num?)?.toInt() ?? 10,
      );
}

class AlwaysOnNotifier extends StateNotifier<AlwaysOnConfig> {
  AlwaysOnNotifier() : super(const AlwaysOnConfig()) {
    _load();
  }

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

  /// Send the config (with the current accent colour) to the native service.
  Future<void> push() async {
    await AlarmBridge.setAlwaysOn({
      ...state.toJson(),
      'color': AppColors.nightPrimary.value,
    });
  }
}

final alwaysOnProvider =
    StateNotifierProvider<AlwaysOnNotifier, AlwaysOnConfig>(
        (ref) => AlwaysOnNotifier());

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
          ListTile(
            leading: const Icon(Icons.wallpaper_outlined),
            title: const Text('خلفية شاشة القفل الحيّة',
                style: TextStyle(fontFamily: 'Cairo')),
            subtitle: const Text('خيار إضافي: خلفية تعرض الصلاة القادمة بدون خدمة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AodSettingsScreen())),
          ),
        ],
      ),
    );
  }
}
