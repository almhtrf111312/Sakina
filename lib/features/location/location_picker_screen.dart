// lib/features/location/location_picker_screen.dart
// Pick a country, then one of its provinces / governorates / states.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'dart:async';

import '../../data/location/location_service.dart';
import '../../data/location/place_search.dart';
import '../../data/location/world_locations.dart';
import '../../data/prayer/prayer_repository.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  WorldLocations? _world;
  WorldCountry? _country;
  String _query = '';
  Timer? _debounce;
  List<PlaceResult> _places = const [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    WorldLocations.load().then((w) {
      if (mounted) setState(() => _world = w);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String v) {
    setState(() => _query = v);
    _debounce?.cancel();
    if (_country != null || v.trim().length < 2) {
      setState(() {
        _places = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final r = await PlaceSearch.search(v);
      if (!mounted || v != _query) return;
      setState(() {
        _places = r;
        _searching = false;
      });
    });
  }

  Future<void> _choosePlace(PlaceResult p) async {
    final loc = AppLocation(
      latitude: p.lat,
      longitude: p.lon,
      elevation: p.elevation,
      cityName: p.name,
      countryName: [p.admin1, p.country]
          .where((e) => e.isNotEmpty && e != p.name)
          .join('، '),
      isManual: true,
    );
    await ref.read(locationNotifierProvider.notifier).setManualLocation(loc);
    await ref.read(prayerRepositoryProvider).invalidateCache();
    ref.invalidate(prayerTimesProvider);
    ref.invalidate(todayPrayerTimesProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _choose(WorldCountry c, {WorldRegion? region}) async {
    final loc = AppLocation(
      latitude: region?.lat ?? c.lat,
      longitude: region?.lon ?? c.lon,
      cityName: region?.name ?? (c.capital.isNotEmpty ? c.capital : c.name),
      countryName: c.name,
      isManual: true,
    );
    await ref.read(locationNotifierProvider.notifier).setManualLocation(loc);
    await ref.read(prayerRepositoryProvider).invalidateCache();
    ref.invalidate(prayerTimesProvider);
    ref.invalidate(todayPrayerTimesProvider);
    if (mounted) Navigator.of(context).pop();
  }

  bool _match(String a, String b) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty ||
        a.toLowerCase().contains(q) ||
        b.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final world = _world;
    final country = _country;
    final title = country == null ? 'اختر الدولة' : country.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontFamily: 'Cairo')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (country != null) {
              setState(() {
                _country = null;
                _query = '';
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: world == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    key: ValueKey(country?.code ?? 'countries'),
                    onChanged: _onQuery,
                    decoration: InputDecoration(
                      hintText: country == null
                          ? 'ابحث عن دولة أو مدينة أو قرية...'
                          : 'ابحث عن محافظة / ولاية...',
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: country == null
                      ? _countryList(world)
                      : _regionList(country),
                ),
              ],
            ),
    );
  }

  Widget _countryList(WorldLocations world) {
    final items =
        world.countries.where((c) => _match(c.nameAr, c.nameEn)).toList();
    final showPlaces = _query.trim().length >= 2;
    final extra = showPlaces ? 1 + (_places.isEmpty ? 1 : _places.length) : 0;
    return ListView.builder(
      itemCount: extra + items.length,
      itemBuilder: (_, i) {
        if (showPlaces && i < extra) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                _searching
                    ? 'جارٍ البحث عن المدن والقرى...'
                    : 'مدن وقرى ومحافظات مطابقة',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
              ),
            );
          }
          if (_places.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _searching ? '' : 'لا توجد نتائج (يلزم اتصال بالإنترنت للبحث)',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
              ),
            );
          }
          final p = _places[i - 1];
          return ListTile(
            leading: const Icon(Icons.location_city_outlined),
            title: Text(p.name, style: const TextStyle(fontFamily: 'Cairo')),
            subtitle: Text(p.subtitle,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
            onTap: () => _choosePlace(p),
          );
        }
        final c = items[i - extra];
        return ListTile(
          title: Text(c.name, style: const TextStyle(fontFamily: 'Cairo')),
          subtitle: c.nameAr.isNotEmpty
              ? Text(c.nameEn, style: const TextStyle(fontSize: 11))
              : null,
          trailing: const Icon(Icons.chevron_left),
          onTap: () {
            if (c.regions.isEmpty) {
              _choose(c);
            } else {
              setState(() {
                _country = c;
                _query = '';
              });
            }
          },
        );
      },
    );
  }

  Widget _regionList(WorldCountry c) {
    final items = c.regions.where((r) => _match(r.nameAr, r.nameEn)).toList();
    return ListView(
      children: [
        if (_query.isEmpty)
          ListTile(
            leading: Icon(Icons.star_rounded, color: AppColors.nightPrimary),
            title: Text(
              c.capital.isNotEmpty ? 'العاصمة: ${c.capital}' : 'مركز ${c.name}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            onTap: () => _choose(c),
          ),
        for (final r in items)
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(r.name, style: const TextStyle(fontFamily: 'Cairo')),
            subtitle: r.nameAr.isNotEmpty
                ? Text(r.nameEn, style: const TextStyle(fontSize: 11))
                : null,
            onTap: () => _choose(c, region: r),
          ),
      ],
    );
  }
}
