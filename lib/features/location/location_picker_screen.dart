// lib/features/location/location_picker_screen.dart
// Pick a country, then one of its provinces / governorates / states.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/location/location_service.dart';
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

  @override
  void initState() {
    super.initState();
    WorldLocations.load().then((w) {
      if (mounted) setState(() => _world = w);
    });
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
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: country == null
                          ? 'ابحث عن دولة...'
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
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final c = items[i];
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
            leading: const Icon(Icons.star_rounded, color: AppColors.nightPrimary),
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
