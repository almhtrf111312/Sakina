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

  String _offsetLabel(int offset) {
    if (offset == 0) return 'عند الأذان';
    return '${offset.abs()} د ${offset < 0 ? 'قبل الأذان' : 'بعد الأذان'}';
  }

  Future<void> _edit(String name, String label, PrayerSilence rule) async {
    final interval = await showDialog<(int, int)>(
      context: context,
      builder: (_) => _IntervalDialog(label: label, rule: rule),
    );
    if (interval == null || !mounted) return;
    await _saveRule(
      name,
      (current) => current.copyWith(start: interval.$1, end: interval.$2),
    );
  }

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
                    ListTile(
                      title: const Text('بداية الصامت ونهايته'),
                      subtitle: Text(
                        'البداية ${_offsetLabel(settings.prayerSilence[entry.key]!.start)}\n'
                        'النهاية ${_offsetLabel(settings.prayerSilence[entry.key]!.end)}',
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _edit(
                        entry.key,
                        entry.value,
                        settings.prayerSilence[entry.key]!,
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

class _IntervalDialog extends StatefulWidget {
  const _IntervalDialog({required this.label, required this.rule});

  final String label;
  final PrayerSilence rule;

  @override
  State<_IntervalDialog> createState() => _IntervalDialogState();
}

class _IntervalDialogState extends State<_IntervalDialog> {
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
    Navigator.of(context).pop((start, end));
  }

  Widget _offset({
    required String label,
    required int direction,
    required TextEditingController controller,
    required ValueChanged<int> onChanged,
  }) =>
      Column(
        children: [
          DropdownButtonFormField<int>(
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
          if (direction != 0)
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد الدقائق'),
              validator: (text) {
                final value = _minutes(text);
                return value == null || value < 1 || value > PrayerSilence.maxOffset
                    ? 'أدخل عدداً من 1 إلى ${PrayerSilence.maxOffset}.'
                    : null;
              },
            ),
        ],
      );

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('فترة الصامت لصلاة ${widget.label}'),
          scrollable: true,
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _offset(
                  label: 'بداية الصامت',
                  direction: _startDirection,
                  controller: _start,
                  onChanged: (direction) => setState(() {
                    _startDirection = direction;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 12),
                _offset(
                  label: 'نهاية الصامت',
                  direction: _endDirection,
                  controller: _end,
                  onChanged: (direction) => setState(() {
                    _endDirection = direction;
                    _error = null;
                  }),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(onPressed: _save, child: const Text('حفظ')),
          ],
        ),
      );
}
