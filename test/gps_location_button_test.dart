import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/data/location/location_service.dart';
import 'package:sakina/features/location/gps_location_button.dart';

class _LocationNotifier extends LocationNotifier {
  _LocationNotifier(super.prefs, super.service);
  Completer<bool> result = Completer<bool>();
  int calls = 0;
  @override
  Future<bool> updateGpsLocation() { calls++; return result.future; }
}

void main() {
  testWidgets('GPS button prevents duplicate requests and offers retry on failure',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'sakina_saved_location': jsonEncode(AppLocation.cairo.toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    final notifier = _LocationNotifier(prefs, LocationService());
    var located = 0;
    await tester.pumpWidget(ProviderScope(overrides: [
      locationNotifierProvider.overrideWith((ref) => notifier),
    ], child: MaterialApp(home: Scaffold(body:
      GpsLocationButton(onLocated: () => located++)))));
    await tester.tap(find.text('تحديد موقعي عبر GPS'));
    await tester.pump();
    expect(notifier.calls, 1);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    notifier.result.complete(false);
    await tester.pumpAndSettle();
    expect(located, 0);
    expect(find.text('إعدادات الموقع'), findsOneWidget);
    notifier.result = Completer<bool>();
    await tester.tap(find.text('تحديد موقعي عبر GPS'));
    await tester.pump();
    notifier.result.complete(true);
    await tester.pumpAndSettle();
    expect(notifier.calls, 2);
    expect(located, 1);
    expect(find.text('إعدادات الموقع'), findsNothing);
  });
}
