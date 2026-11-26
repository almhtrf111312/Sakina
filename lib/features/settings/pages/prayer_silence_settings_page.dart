import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/alarm_bridge.dart';
import '../../../data/settings/prayer_silence_settings.dart';
import '../../../data/settings/settings_repository.dart';

class PrayerSilenceSettingsPage extends ConsumerStatefulWidget {
  const PrayerSilenceSettingsPage({super.key});

  @override
  ConsumerState<PrayerSilenceSettingsPage> createState() =>
      _PrayerSilenceSettingsPageState();
}

class _PrayerSilenceSettingsPageState
    extends ConsumerState<PrayerSilenceSettingsPage> with WidgetsBindingObserver {
  Map<String, bool>? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    Map<String, bool> status;
    try {
      status = await AlarmBridge.prayerSilenceStatus();
    } on PlatformException {
      status = const {};
    } on MissingPluginException {
      status = const {};
    }
    if (mounted) setState(() => _status = status);
  }

  Future<void> _openPermission(Future<void> Function() open) async {
    try {
      await open();
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('افتح أذونات التطبيق من إعدادات الهاتف.'),
      ));
    }
  }

  Future<void> _saveRule(
    String name,
    PrayerSilence Function(PrayerSilence) update,
  ) =>
      ref.read(settingsNotifierProvider.notifier).update((settings) {
        final current = settings.prayerSilence[name] ?? const PrayerSilence();
        return settings.copyWith(prayerSilence: {
          ...settings.prayerSilence,
          name: update(current),
        });
      });

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final status = _status;
    final supported = status?['supported'] == true;
    final hasAccess = status?['access'] == true;
    final hasExactAlarm = status?['exactAlarm'] == true;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الصامت أثناء الصلاة')),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            if (status == null)
              const Center(child: CircularProgressIndicator())
            else if (!supported)
              const ListTile(title: Text('تتطلب الميزة أندرويد 10 أو أحدث.'))
            else ...[
              SwitchListTile(
                title: const Text('الصامت أثناء الصلاة'),
                subtitle: const Text(
                  'يكتم المكالمات والإشعارات خلال الفترات المحددة ويسمح بصوت المنبّه والأذان.',
                ),
                value: settings.prayerSilenceEnabled,
                onChanged: (enabled) => notifier.update(
                  (s) => s.copyWith(prayerSilenceEnabled: enabled),
                ),
              ),
              if (!hasAccess)
                ListTile(
                  leading: const Icon(Icons.do_not_disturb_on_outlined),
                  title: const Text('السماح بالتحكم في «عدم الإزعاج»'),
                  subtitle: const Text('فعّل الإذن لتطبيق المؤذن من إعدادات الهاتف.'),
                  onTap: () => _openPermission(AlarmBridge.requestPrayerSilenceAccess),
                ),
              if (!hasExactAlarm)
                ListTile(
                  leading: const Icon(Icons.alarm),
                  title: const Text('السماح بالمنبّه الدقيق'),
                  onTap: () => _openPermission(AlarmBridge.requestExactAlarmPermission),
                ),
              if (settings.prayerSilenceEnabled)
                for (final entry in prayerSilenceNames.entries) ...[
                  const Divider(),
                  SwitchListTile(
                    title: Text(entry.value),
                    value: settings.prayerSilence[entry.key]?.enabled ?? false,
                    onChanged: (enabled) => _saveRule(
                      entry.key,
                      (rule) => rule.copyWith(enabled: enabled),
                    ),
                  ),
                  if (settings.prayerSilence[entry.key]?.enabled == true)
                    _IntervalEditor(
                      key: ValueKey(entry.key),
                      rule: settings.prayerSilence[entry.key]!,
                      onSave: (start, end) => _saveRule(
                        entry.key,
                        (rule) => rule.copyWith(start: start, end: end),
                      ),
                    ),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

class _IntervalEditor extends StatefulWidget {
  const _IntervalEditor({super.key, required this.rule, required this.onSave});

  final Future<void> Function(int start, int end) onSave;
  final PrayerSilence rule;

  @override
  State<_IntervalEditor> createState() => _IntervalEditorState();
}

class _IntervalEditorState extends State<_IntervalEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _start = TextEditingController(text: '${widget.rule.start.abs()}');
  late final _end = TextEditingController(text: '${widget.rule.end.abs()}');
  late int _startDirection = widget.rule.start.sign;
  late int _endDirection = widget.rule.end.sign;
  String? _error;

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  int? _minutes(String? text) {
    const numerals = '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹';
    return int.tryParse((text ?? '').trim().replaceAllMapped(
      RegExp('[٠-٩۰-۹]'),
      (match) => '${numerals.indexOf(match[0]!) % 10}',
    ));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final start = _startDirection == 0 ? 0 : _startDirection * _minutes(_start.text)!;
    final end = _endDirection == 0 ? 0 : _endDirection * _minutes(_end.text)!;
    if (end <= start) {
      setState(() => _error = 'اختر نهاية بعد وقت البداية.');
      return;
    }
    setState(() => _error = null);
    widget.onSave(start, end);
    FocusScope.of(context).unfocus();
  }

  Widget _offset({
    required String label,
    required int direction,
    required TextEditingController controller,
    required ValueChanged<int> onChanged,
  }) =>
      Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              initialValue: direction,
              isExpanded: true,
              decoration: InputDecoration(labelText: label),
              items: const [
                DropdownMenuItem(value: -1, child: Text('قبل الأذان')),
                DropdownMenuItem(value: 0, child: Text('عند الأذان')),
                DropdownMenuItem(value: 1, child: Text('بعد الأذان')),
              ],
              onChanged: (value) => onChanged(value!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              enabled: direction != 0,
              decoration: const InputDecoration(labelText: 'دقائق'),
              validator: (text) {
                if (direction == 0) return null;
                final value = _minutes(text);
                return value == null || value < 1 || value > PrayerSilence.maxOffset
                    ? 'أدخل عدداً من 1 إلى ${PrayerSilence.maxOffset}.'
                    : null;
              },
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('بداية الصامت ونهايته'),
                _offset(
                  label: 'البداية',
                  direction: _startDirection,
                  controller: _start,
                  onChanged: (direction) => setState(() {
                    _startDirection = direction;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 8),
                _offset(
                  label: 'النهاية',
                  direction: _endDirection,
                  controller: _end,
                  onChanged: (direction) => setState(() {
                    _endDirection = direction;
                    _error = null;
                  }),
                ),
                if (_error != null)
                  Text(_error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(onPressed: _save, child: const Text('حفظ الفترة')),
                ),
              ],
            ),
          ),
        ),
      );
}
