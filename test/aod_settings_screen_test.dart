import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/aod/aod_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.sakina.app/aod');
  late Map<String, dynamic> stored;
  late List<MethodCall> calls;
  bool rejectStart = false;

  setUp(() {
    stored = {
      'enabled': false,
      'running': false,
      'permission': true,
      'brightness': 0.1,
      'color': 0xFF5FB59B,
      'showHijri': true,
      'showPrayers': true,
    };
    calls = [];
    rejectStart = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'getLockDisplaySettings':
          return stored;
        case 'setLockDisplayEnabled':
          if (rejectStart) {
            throw PlatformException(
              code: 'START_FAILED',
              message: 'تعذّر التشغيل',
            );
          }
          stored['enabled'] = call.arguments['enabled'];
          stored['running'] = stored['enabled'];
          return stored['enabled'];
        case 'saveLockDisplaySettings':
          stored.addAll(Map<String, dynamic>.from(call.arguments as Map));
          return true;
        default:
          return true;
      }
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AodSettingsScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'switch starts and stops native service without installing wallpaper',
    (tester) async {
      await open(tester);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(stored['enabled'], true);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(stored['enabled'], false);
      expect(
        calls.where((c) => c.method == 'setAsLockscreenWallpaper'),
        isEmpty,
      );
      expect(find.text('تعديل مواقيت الأذان (بالدقائق)'), findsNothing);
    },
  );
  testWidgets('permission request does not pretend service is enabled', (
    tester,
  ) async {
    stored['permission'] = false;
    await open(tester);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(calls.any((c) => c.method == 'requestDrawOverApps'), true);
    expect(stored['enabled'], false);
    expect(calls.where((c) => c.method == 'setLockDisplayEnabled'), isEmpty);
  });
  testWidgets('failed start leaves switch off and shows error', (tester) async {
    rejectStart = true;
    await open(tester);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(stored['enabled'], false);
    expect(find.text('تعذّر التشغيل'), findsOneWidget);
  });
  testWidgets('reads persisted native settings and saves appearance', (
    tester,
  ) async {
    stored['enabled'] = true;
    stored['running'] = true;
    await open(tester);
    expect(tester.widget<Switch>(find.byType(Switch).first).value, true);
    await tester.ensureVisible(find.text('ذهبي'));
    await tester.tap(find.text('ذهبي'));
    await tester.pumpAndSettle();
    expect(stored['color'], 0xFFC9A86A);
  });
  testWidgets('preview uses native renderer without enabling service', (
    tester,
  ) async {
    await open(tester);
    await tester.scrollUntilVisible(find.text('معاينة الشاشة الفعلية'), 250);
    await tester.tap(find.text('معاينة الشاشة الفعلية'));
    await tester.pumpAndSettle();
    expect(calls.any((c) => c.method == 'previewLockDisplay'), true);
    expect(stored['enabled'], false);
  });
}
