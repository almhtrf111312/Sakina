import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/aod/always_on_screen.dart';

void main() {
  test('existing settings keep the same clock style and visible elements', () {
    final config = AlwaysOnConfig.fromJson({
      'clockStyle': 7,
      'showPrayers': false,
      'dateMode': 'gregorian',
    });

    expect(config.layout, 'classic');
    expect(config.hiddenElements, isEmpty);
    expect(config.clockStyle, 7);
    expect(config.showPrayers, isFalse);
    expect(config.dateMode, 'gregorian');
  });

  test('layout choices and hidden elements survive a round trip', () {
    final config = const AlwaysOnConfig().copyWith(
      layout: 'split',
      clockStyle: 2,
      timeoutMin: 1,
      showAgainWhenLocked: false,
      hiddenElements: {'wifi', 'caption', 'remaining'},
    );
    final restored = AlwaysOnConfig.fromJson(config.toJson());

    expect(restored.layout, 'split');
    expect(restored.hiddenElements, config.hiddenElements);
    expect(restored.clockStyle, 2);
    expect(restored.timeoutMin, 1);
    expect(restored.showAgainWhenLocked, isFalse);
  });
}
