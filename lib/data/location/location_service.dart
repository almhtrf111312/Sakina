// lib/data/location/location_service.dart
// GPS location service using geolocator, fallback to manual city selection,
// and auto-update trigger at 20km movement. Riverpod provider.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings_repository.dart';
import 'world_locations.dart';

// ─────────────────────────── Models ─────────────────────────────────────────

class AppLocation {
  final double latitude;
  final double longitude;
  final double elevation;
  final String cityName;
  final String countryName;
  final bool isManual;

  const AppLocation({
    required this.latitude,
    required this.longitude,
    this.elevation = 0.0,
    required this.cityName,
    this.countryName = '',
    this.isManual = false,
  });

  /// Default fallback: Mecca Al-Mukarramah
  static const mecca = AppLocation(
    latitude: 21.4225,
    longitude: 39.8262,
    elevation: 277.0,
    cityName: 'مكة المكرمة',
    countryName: 'المملكة العربية السعودية',
    isManual: true,
  );

  static const medina = AppLocation(
    latitude: 24.4672,
    longitude: 39.6112,
    elevation: 608.0,
    cityName: 'المدينة المنورة',
    countryName: 'المملكة العربية السعودية',
    isManual: true,
  );

  static const cairo = AppLocation(
    latitude: 30.0444,
    longitude: 31.2357,
    elevation: 23.0,
    cityName: 'القاهرة',
    countryName: 'مصر',
    isManual: true,
  );

  static const riyadh = AppLocation(
    latitude: 24.7136,
    longitude: 46.6753,
    elevation: 612.0,
    cityName: 'الرياض',
    countryName: 'المملكة العربية السعودية',
    isManual: true,
  );

  static const jerusalem = AppLocation(
    latitude: 31.7683,
    longitude: 35.2137,
    elevation: 754.0,
    cityName: 'القدس الشريف',
    countryName: 'فلسطين',
    isManual: true,
  );

  static const dubai = AppLocation(
    latitude: 25.2048,
    longitude: 55.2708,
    elevation: 5.0,
    cityName: 'دبي',
    countryName: 'الإمارات العربية المتحدة',
    isManual: true,
  );

  static const istanbul = AppLocation(
    latitude: 41.0082,
    longitude: 28.9784,
    elevation: 39.0,
    cityName: 'إسطنبول',
    countryName: 'تركيا',
    isManual: true,
  );

  static const List<AppLocation> defaultCities = [
    mecca,
    medina,
    riyadh,
    cairo,
    jerusalem,
    dubai,
    istanbul,
  ];

  AppLocation copyWith({
    double? latitude,
    double? longitude,
    double? elevation,
    String? cityName,
    String? countryName,
    bool? isManual,
  }) {
    return AppLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevation: elevation ?? this.elevation,
      cityName: cityName ?? this.cityName,
      countryName: countryName ?? this.countryName,
      isManual: isManual ?? this.isManual,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'elevation': elevation,
        'cityName': cityName,
        'countryName': countryName,
        'isManual': isManual,
      };

  factory AppLocation.fromJson(Map<String, dynamic> json) {
    return AppLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      elevation: (json['elevation'] as num?)?.toDouble() ?? 0.0,
      cityName: json['cityName'] as String? ?? 'مكة المكرمة',
      countryName: json['countryName'] as String? ?? '',
      isManual: json['isManual'] as bool? ?? false,
    );
  }
}

// ─────────────────────────── Location Service ───────────────────────────────

class LocationService {
  static const double movementThresholdMeters = 20000.0; // 20 km

  /// Check GPS service and request location permissions.
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current GPS position with timeout.
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('LocationService error: $e');
      return null;
    }
  }

  /// Calculates distance in meters between two points.
  double distanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}

// ─────────────────────────── Location Notifier ──────────────────────────────

class LocationNotifier extends StateNotifier<AppLocation> {
  static const _locationKey = 'sakina_saved_location';
  final SharedPreferences _prefs;
  final LocationService _locationService;

  LocationNotifier(this._prefs, this._locationService)
      : super(AppLocation.mecca) {
    _init();
  }

  void _init() {
    final raw = _prefs.getString(_locationKey);
    if (raw == null) {
      // First launch: start from Mecca but in *automatic* mode so that the
      // first GPS fix replaces it.
      state = AppLocation.mecca.copyWith(isManual: false);
    }
    if (raw != null) {
      try {
        state = AppLocation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        state = AppLocation.mecca;
      }
    }
    // Attempt automatic update if not manual
    if (!state.isManual) {
      if (state.cityName == 'الموقع الحالي') _resolveSavedName();
      refreshLocationIfMoved();
    }
  }

  /// Name of the nearest province/country for a GPS fix (offline).
  Future<(String, String)> _placeName(double lat, double lon) async {
    try {
      final world = await WorldLocations.load();
      final n = world.nearest(lat, lon);
      if (n != null) return (n.label, n.country.name);
    } catch (_) {}
    return ('الموقع الحالي', '');
  }

  Future<void> _resolveSavedName() async {
    final place = await _placeName(state.latitude, state.longitude);
    if (place.$2.isEmpty || state.isManual) return;
    state = state.copyWith(cityName: place.$1, countryName: place.$2);
    await _save();
  }

  Future<void> _save() async {
    await _prefs.setString(_locationKey, jsonEncode(state.toJson()));
  }

  /// Refresh GPS location and update if moved > 20 km or if first GPS fix
  Future<bool> refreshLocationIfMoved() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return false;

    if (!state.isManual) {
      final distance = _locationService.distanceBetween(
        startLatitude: state.latitude,
        startLongitude: state.longitude,
        endLatitude: position.latitude,
        endLongitude: position.longitude,
      );

      // If moved more than 20km or default coords
      if (distance >= LocationService.movementThresholdMeters ||
          (state.latitude == AppLocation.mecca.latitude &&
              state.longitude == AppLocation.mecca.longitude)) {
        final place = await _placeName(position.latitude, position.longitude);
        state = AppLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          elevation: position.altitude,
          cityName: place.$1,
          countryName: place.$2,
          isManual: false,
        );
        await _save();
        return true;
      }
    }
    return false;
  }

  /// Force fetch GPS location
  Future<bool> updateGpsLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return false;

    final place = await _placeName(position.latitude, position.longitude);
    state = AppLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      elevation: position.altitude,
      cityName: place.$1,
      countryName: place.$2,
      isManual: false,
    );
    await _save();
    return true;
  }

  /// Set manual city location
  Future<void> setManualLocation(AppLocation location) async {
    state = location.copyWith(isManual: true);
    await _save();
  }
}

// ─────────────────────────── Providers ──────────────────────────────────────

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationNotifierProvider =
    StateNotifierProvider<LocationNotifier, AppLocation>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = ref.watch(locationServiceProvider);
  return LocationNotifier(prefs, service);
});

final locationProvider = Provider<AppLocation>((ref) {
  return ref.watch(locationNotifierProvider);
});
