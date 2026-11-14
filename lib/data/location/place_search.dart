// lib/data/location/place_search.dart
// Search any city / town / village worldwide (Arabic or English) using the
// free Open-Meteo geocoding service (no API key).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class PlaceResult {
  final String name;
  final String admin1;
  final String admin2;
  final String country;
  final double lat;
  final double lon;
  final double elevation;

  const PlaceResult({
    required this.name,
    required this.admin1,
    required this.admin2,
    required this.country,
    required this.lat,
    required this.lon,
    required this.elevation,
  });

  /// "إدلب، سوريا" style description under the name.
  String get subtitle => [admin2, admin1, country]
      .where((e) => e.isNotEmpty && e != name)
      .toSet()
      .join('، ');
}

class PlaceSearch {
  static Future<List<PlaceResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final isArabic = RegExp(r'[؀-ۿ]').hasMatch(q);
    final langs = isArabic ? ['ar', 'en'] : ['en', 'ar'];

    final all = <PlaceResult>[];
    final seen = <String>{};
    for (final lang in langs) {
      final list = await _fetch(q, lang);
      for (final r in list) {
        final key = '${r.lat.toStringAsFixed(2)},${r.lon.toStringAsFixed(2)}';
        if (seen.add(key)) all.add(r);
      }
      if (all.length >= 10) break;
    }
    return all;
  }

  static Future<List<PlaceResult>> _fetch(String q, String lang) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': q,
        'count': '20',
        'language': lang,
        'format': 'json',
      });
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const [];
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? const [];
      return results.map((e) {
        final m = e as Map<String, dynamic>;
        return PlaceResult(
          name: (m['name'] as String?) ?? '',
          admin1: (m['admin1'] as String?) ?? '',
          admin2: (m['admin2'] as String?) ?? '',
          country: (m['country'] as String?) ?? '',
          lat: (m['latitude'] as num).toDouble(),
          lon: (m['longitude'] as num).toDouble(),
          elevation: (m['elevation'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (_) {
      return const [];
    } finally {
      client.close(force: true);
    }
  }
}
