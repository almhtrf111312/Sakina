import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/data/azkar/azkar_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first morning and evening visit resets counts once without recursion', () async {
    SharedPreferences.setMockInitialValues({
      'sakina_zikr_count_sabah_001': 1,
      'sakina_zikr_count_masa_001': 1,
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = AzkarRepository(
      prefs: prefs,
      now: () => DateTime(2026, 11, 15, 16),
    );

    final first = await repo.getAllAzkar().timeout(const Duration(seconds: 5));
    expect(first, isNotEmpty);
    expect(prefs.getInt('sakina_zikr_count_sabah_001'), isNull);
    expect(prefs.getInt('sakina_zikr_count_masa_001'), isNull);
    expect(prefs.getInt('sakina_azkar_last_reset_morning'), isNotNull);
    expect(prefs.getInt('sakina_azkar_last_reset_evening'), isNotNull);

    await prefs.setInt('sakina_zikr_count_sabah_001', 1);
    final second = await repo.getAllAzkar().timeout(const Duration(seconds: 5));
    expect(second.firstWhere((item) => item.id == 'sabah_001').currentCount, 1);
    expect(prefs.getInt('sakina_zikr_count_sabah_001'), 1);
  });
}
