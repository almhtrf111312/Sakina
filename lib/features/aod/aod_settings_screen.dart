import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/alarm_bridge.dart';

/// Native preferences are authoritative, including stops from the notification.
class AodSettingsScreen extends StatefulWidget {
  const AodSettingsScreen({super.key});
  @override
  State<AodSettingsScreen> createState() => _AodSettingsScreenState();
}

class _AodSettingsScreenState extends State<AodSettingsScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _settings;
  bool _busy = false;
  String? _error;
  static const _colors = <int, String>{
    0xFF5FB59B: 'أخضر',
    0xFFC9A86A: 'ذهبي',
    0xFFFFFFFF: 'أبيض',
    0xFF5B9BD5: 'أزرق',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final settings = await AlarmBridge.getLockDisplaySettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'تعذّر قراءة حالة الشاشة الدائمة. حاول مجدداً.',
        );
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) {
        final message = e is PlatformException ? e.message : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message ?? 'تعذّر تنفيذ الطلب. حاول مجدداً.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(bool enabled) => _run(() async {
        if (enabled && _settings?['permission'] != true) {
          await AlarmBridge.requestDrawOverApps();
          return;
        }
        await AlarmBridge.setLockDisplayEnabled(enabled);
      });

  Future<void> _save(String key, dynamic value) =>
      _run(() => AlarmBridge.saveLockDisplaySettings({key: value}));

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    final enabled = s?['enabled'] == true;
    final permission = s?['permission'] == true;
    final brightness = (s?['brightness'] as num?)?.toDouble() ?? 0.1;
    return Scaffold(
      appBar: AppBar(title: const Text('الشاشة الدائمة (AOD)')),
      body: s == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : TextButton(onPressed: _load, child: Text(_error!)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'شاشة سكينة بعد إطفاء الشاشة',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ساعة ومواقيت الصلاة على خلفية سوداء خافتة، بدون تغيير خلفية هاتفك. اضغط مرتين للعودة إلى شاشة القفل؛ يبقى رمز القفل والبصمة كما هما.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'هذا عرض من التطبيق وليس وضع AOD الأصلي منخفض الطاقة، وقد يستهلك بطارية أكثر. يحتاج إذن الظهور فوق التطبيقات، وقد تمنع بعض الأجهزة ظهوره أثناء القفل.',
                ),
                if (_error != null) Text(_error!),
                const SizedBox(height: 16),
                Card(
                  child: SwitchListTile(
                    title: const Text('التشغيل بعد إطفاء الشاشة'),
                    subtitle: Text(
                      !permission
                          ? 'اسمح بالظهور فوق التطبيقات ثم فعّل الخيار'
                          : enabled && s['running'] != true
                              ? 'الخدمة متوقفة؛ أوقف الخيار وأعد تفعيله'
                              : enabled
                                  ? 'مفعّلة؛ أطفئ الشاشة للتجربة'
                                  : 'متوقفة',
                    ),
                    value: enabled,
                    onChanged: _busy ? null : _toggle,
                  ),
                ),
                if (!permission)
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(AlarmBridge.requestDrawOverApps),
                    icon: const Icon(Icons.security),
                    label: const Text('السماح بالظهور فوق التطبيقات'),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'المظهر',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: _colors.entries
                      .map(
                        (entry) => ChoiceChip(
                          label: Text(entry.value),
                          avatar: CircleAvatar(
                            backgroundColor: Color(entry.key),
                            radius: 8,
                          ),
                          selected: s['color'] == entry.key,
                          onSelected:
                              _busy ? null : (_) => _save('color', entry.key),
                        ),
                      )
                      .toList(),
                ),
                ListTile(
                  title: const Text('سطوع الشاشة الدائمة'),
                  subtitle: Slider(
                    value: brightness.clamp(0.02, 0.3),
                    min: 0.02,
                    max: 0.3,
                    divisions: 14,
                    label: '${(brightness * 100).round()}%',
                    onChanged: _busy
                        ? null
                        : (value) => setState(
                              () => _settings = {...s, 'brightness': value},
                            ),
                    onChangeEnd: (value) => _save('brightness', value),
                  ),
                ),
                SwitchListTile(
                  title: const Text('عرض التاريخ الهجري'),
                  value: s['showHijri'] == true,
                  onChanged: _busy ? null : (v) => _save('showHijri', v),
                ),
                SwitchListTile(
                  title: const Text('عرض مواقيت الصلوات الخمس'),
                  value: s['showPrayers'] == true,
                  onChanged: _busy ? null : (v) => _save('showPrayers', v),
                ),
                const Text(
                  'تتحرك العناصر قليلاً كل دقيقة لتقليل ثبات البكسلات. يتوقف العرض في وضع توفير الطاقة أو عند وصول البطارية إلى 10٪ دون شحن. إعدادات المواقيت والتاريخ والأرقام تؤخذ من إعدادات التطبيق.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed:
                      _busy ? null : () => _run(AlarmBridge.previewLockDisplay),
                  icon: const Icon(Icons.preview),
                  label: const Text('معاينة الشاشة الفعلية'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'إذا لم تظهر عند القفل',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'في شاومي وبعض الأجهزة: من إعدادات سكينة اسمح بالعرض على شاشة القفل والنوافذ المنبثقة في الخلفية إن وُجدت، واختر عدم تقييد البطارية. تختلف أسماء الخيارات حسب الجهاز. بعد إعادة تشغيل الهاتف أو إيقاف التطبيق إجبارياً، افتح سكينة لاستئناف الخدمة.',
                ),
                OutlinedButton(
                  onPressed:
                      _busy ? null : () => _run(AlarmBridge.openAppSettings),
                  child: const Text('فتح إعدادات سكينة في النظام'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'إذا سبق أن عيّنت سكينة كخلفية، أعد اختيار خلفيتك من إعدادات الهاتف؛ التفعيل الجديد لا يغيّر الخلفية القديمة.',
                ),
              ],
            ),
    );
  }
}
