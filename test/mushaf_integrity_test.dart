import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/features/mushaf/mushaf_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reader reuses fully decoded data across tab visits', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final first = await container.read(mushafDataProvider.future);
    final second = await container.read(mushafDataProvider.future);
    expect(second, same(first));
    final pages = first['pages'] as List<dynamic>;
    expect(pages.length, 604);
    expect((pages.first as List).first[2], contains('بِسْمِ'));
    expect([for (final page in pages) ...(page as List)].length, 6236);
  });

  test('offline mushaf contains every ayah exactly once in 604 pages', () async {
    final index = jsonDecode(await rootBundle.loadString(
        'assets/data/mushaf_pages.json')) as Map<String, dynamic>;
    final pages = index['pages'] as List<dynamic>;
    final surahs = index['surahs'] as List<dynamic>;
    final parts = await Future.wait([
      for (var i = 0; i < 16; i++)
        rootBundle.loadString('assets/data/mushaf/part_${i.toString().padLeft(2, '0')}.txt'),
    ]);
    final text = utf8.decode(gzip.decode(base64Decode(parts.join())));

    expect(pages.length, 604);
    expect(surahs.length, 114);
    expect(text.contains('Tanzil Quran Text (Uthmani, Version 1.1)'), isTrue);

    final verses = <String, String>{};
    for (final line in const LineSplitter().convert(text)) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final first = line.indexOf('|');
      final second = line.indexOf('|', first + 1);
      expect(first, greaterThan(0));
      expect(second, greaterThan(first));
      final key = '${line.substring(0, first)}:${line.substring(first + 1, second)}';
      expect(verses.containsKey(key), isFalse, reason: key);
      verses[key] = line.substring(second + 1);
      expect(verses[key], isNotEmpty);
    }

    final indexKeys = <String>[];
    for (final page in pages) {
      expect(page, isNotEmpty);
      for (final entry in page as List<dynamic>) {
        final ayah = entry as List<dynamic>;
        indexKeys.add('${ayah[0]}:${ayah[1]}');
      }
    }
    final expected = <String>[
      for (var chapter = 1; chapter <= surahs.length; chapter++)
        for (var ayah = 1;
            ayah <= ((surahs[chapter - 1] as Map<String, dynamic>)['count'] as int);
            ayah++)
          '$chapter:$ayah',
    ];
    expect(indexKeys, expected);
    expect(verses.keys.toList(), expected);
    expect(verses.length, 6236);
    expect(indexKeys.first, '1:1');
    expect(indexKeys.last, '114:6');
  });
}
