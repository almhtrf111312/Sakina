// lib/data/location/world_locations.dart
// Offline worldwide list: every country with its provinces / governorates /
// states (Arabic names where available) and coordinates.

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;

class WorldRegion {
  final String nameEn;
  final String nameAr;
  final double lat;
  final double lon;
  const WorldRegion(this.nameEn, this.nameAr, this.lat, this.lon);

  String get name => nameAr.isNotEmpty ? nameAr : nameEn;
}

class WorldCountry {
  final String code;
  final String nameEn;
  final String nameAr;
  final String capital;
  final double lat;
  final double lon;
  final List<WorldRegion> regions;
  const WorldCountry(this.code, this.nameEn, this.nameAr, this.capital,
      this.lat, this.lon, this.regions);

  String get name => nameAr.isNotEmpty ? nameAr : nameEn;
}

class NearestPlace {
  final WorldCountry country;
  final WorldRegion? region;
  final double distanceKm;
  const NearestPlace(this.country, this.region, this.distanceKm);

  /// "دمشق، سوريا" style label for auto-detected locations.
  String get label => region != null ? region!.name : country.name;
}

class WorldLocations {
  WorldLocations._(this.countries);
  final List<WorldCountry> countries;

  static WorldLocations? _cache;
  static Future<WorldLocations>? _loading;

  static Future<WorldLocations> load() {
    if (_cache != null) return Future.value(_cache);
    return _loading ??= _read();
  }

  static Future<WorldLocations> _read() async {
    final raw = await rootBundle.loadString('assets/data/world_locations.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final countries = list.map((e) {
      final m = e as Map<String, dynamic>;
      final regions = (m['s'] as List<dynamic>)
          .map((r) {
            final rm = r as Map<String, dynamic>;
            return WorldRegion(rm['n'] as String, rm['a'] as String? ?? '',
                (rm['la'] as num).toDouble(), (rm['lo'] as num).toDouble());
          })
          .toList();
      return WorldCountry(
        m['c'] as String,
        m['n'] as String,
        m['a'] as String? ?? '',
        m['cap'] as String? ?? '',
        (m['la'] as num).toDouble(),
        (m['lo'] as num).toDouble(),
        regions,
      );
    }).toList();
    _cache = WorldLocations._(countries);
    return _cache!;
  }

  static double _km(double la1, double lo1, double la2, double lo2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180.0;
    final dLa = rad(la2 - la1);
    final dLo = rad(lo2 - lo1);
    final a = math.pow(math.sin(dLa / 2), 2) +
        math.cos(rad(la1)) * math.cos(rad(la2)) * math.pow(math.sin(dLo / 2), 2);
    return 2 * r * math.asin(math.sqrt(a.toDouble()));
  }

  /// Nearest province/governorate to a coordinate (falls back to the nearest
  /// country centre for countries without regions).
  NearestPlace? nearest(double lat, double lon) {
    NearestPlace? best;
    for (final c in countries) {
      if (c.regions.isEmpty) {
        final d = _km(lat, lon, c.lat, c.lon);
        if (best == null || d < best.distanceKm) {
          best = NearestPlace(c, null, d);
        }
        continue;
      }
      for (final r in c.regions) {
        final d = _km(lat, lon, r.lat, r.lon);
        if (best == null || d < best.distanceKm) {
          best = NearestPlace(c, r, d);
        }
      }
    }
    return best;
  }
}
