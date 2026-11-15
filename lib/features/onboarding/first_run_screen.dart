import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/location/location_service.dart';
import '../../data/settings/settings_repository.dart';
import '../aod/always_on_screen.dart';
import '../location/location_picker_screen.dart';
import '../settings/widgets/settings_common.dart';

/// The walkthrough is shown only after a fresh install. Existing users keep
/// their current preferences and go straight to the app.
class FirstRunGate extends StatefulWidget {
  const FirstRunGate({super.key, required this.child});
  final Widget child;

  @override
  State<FirstRunGate> createState() => _FirstRunGateState();
}

class _FirstRunGateState extends State<FirstRunGate> {
  bool? done;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() {
        // Prior installations already stored settings; don't show onboarding
        // after an update, even though this flag is new.
        done = p.getBool('first_run_complete') ?? p.containsKey('app_settings_v1');
      });
    });
  }

  @override
  Widget build(BuildContext context) => done == null
      ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      : done!
          ? widget.child
          : FirstRunScreen(onDone: () => setState(() => done = true));
}

class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  int step = 0;

  Future<void> finish() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('first_run_complete', true);
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appSettingsProvider);
    final aod = ref.watch(alwaysOnProvider);
    final location = ref.watch(locationProvider);
    final hasLocation = ref.read(sharedPreferencesProvider)
        .containsKey('sakina_saved_location');
    final primary = Theme.of(context).colorScheme.primary;
    final title = ['مرحباً بك في المؤذن', 'موقعك ومواقيت الصلاة',
      'المظهر والخط', 'الشاشة الدائمة'][step];
    return Scaffold(
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          LinearProgressIndicator(value: (step + 1) / 4),
          const SizedBox(height: 20),
          Expanded(child: ListView(children: [
            if (step == 0) ...[
              Icon(Icons.mosque_rounded, size: 84, color: primary),
              const SizedBox(height: 24),
              const Text('المؤذن يعرض مواقيت الصلاة، ينبهك عند وقتها، '
                  'ويساعدك في الأذكار والتسبيح واتجاه القبلة.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 19)),
              const SizedBox(height: 16),
              const Text('اختر موقعك ومظهر التطبيق، ثم قرر إن كنت تريد الشاشة الدائمة.',
                  textAlign: TextAlign.center),
            ],
            if (step == 1) ...[
              Text(!hasLocation ? 'اختر منطقة لحساب مواقيت الصلاة بدقة' :
                  '${location.cityName}، ${location.countryName}'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const LocationPickerScreen())),
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('اختر البلد والمدينة'),
              ),
              const SizedBox(height: 8),
              const Text('يمكن تغيير الموقع لاحقاً من الإعدادات.'),
            ],
            if (step == 2) ...[
              const Text('المظهر'),
              DropdownButton<AppThemeMode>(
                isExpanded: true, value: s.themeMode,
                items: AppThemeMode.values.map((m) => DropdownMenuItem(
                    value: m, child: Text(themeName(m)))).toList(),
                onChanged: (m) { if (m != null) {
                  ref.read(settingsNotifierProvider.notifier).setThemeMode(m);
                } },
              ),
              const SizedBox(height: 18),
              const Text('اللون'),
              const SizedBox(height: 8),
              Wrap(spacing: 12, runSpacing: 12, children: [
                for (final c in AccentColor.values)
                  IconButton.filledTonal(
                    tooltip: accentName(c),
                    style: IconButton.styleFrom(backgroundColor: accentColorValue(c)),
                    onPressed: () => ref.read(settingsNotifierProvider.notifier)
                        .update((v) => v.copyWith(accentColor: c)),
                    icon: Icon(s.accentColor == c ? Icons.check : Icons.circle_outlined,
                        color: Colors.black),
                  ),
              ]),
              const SizedBox(height: 20),
              Text('حجم الخط: ${(s.fontSize * 100).round()}%'),
              Slider(value: s.fontSize, min: 0.8, max: 1.4, divisions: 6,
                onChanged: (v) => ref.read(settingsNotifierProvider.notifier)
                    .update((s) => s.copyWith(fontSize: v))),
              const Text('مثال: موعد الصلاة القادمة'),
            ],
            if (step == 3) ...[
              SwitchListTile(
                title: const Text('تفعيل الشاشة الدائمة'),
                subtitle: const Text('ساعة ومواقيت صلاة على شاشة سوداء خافتة عند القفل'),
                value: aod.enabled,
                onChanged: (v) => ref.read(alwaysOnProvider.notifier)
                    .update((c) => c.copyWith(enabled: v)),
              ),
              if (aod.enabled) ...[
                const SizedBox(height: 12),
                const Text('شكل الساعة'),
                DropdownButton<int>(isExpanded: true, value: aod.clockStyle,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('رقمي عصري')),
                    DropdownMenuItem(value: 1, child: Text('كلاسيكي')),
                    DropdownMenuItem(value: 2, child: Text('بسيط')),
                    DropdownMenuItem(value: 3, child: Text('إطار هندسي')),
                    DropdownMenuItem(value: 4, child: Text('رقمي رفيع')),
                    DropdownMenuItem(value: 5, child: Text('رقمي مستدير')),
                    DropdownMenuItem(value: 6, child: Text('تناظري كلاسيكي')),
                    DropdownMenuItem(value: 7, child: Text('تناظري بسيط')),
                  ],
                  onChanged: (v) { if (v != null) {
                    ref.read(alwaysOnProvider.notifier).update((c) => c.copyWith(clockStyle: v));
                  } },
                ),
                const Text('ستجد الألوان والتوقيت وخيارات البطارية في إعدادات الشاشة الدائمة.'),
              ],
            ],
          ])),
          Row(children: [
            if (step > 0) TextButton(onPressed: () => setState(() => step--),
                child: const Text('رجوع')),
            const Spacer(),
            FilledButton(onPressed: step == 1 && !hasLocation
                    ? null : step == 3 ? finish : () => setState(() => step++),
                child: Text(step == 3 ? 'ابدأ' : 'التالي')),
          ]),
        ]),
      )),
    );
  }
}
