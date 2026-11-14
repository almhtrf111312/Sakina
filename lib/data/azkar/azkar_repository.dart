import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/azkar_model.dart';

/// Repository for Hisn Al Muslim Azkar database, reading from JSON,
/// caching, and tracking daily progress with smart prayer-time based resets.
class AzkarRepository {
  AzkarRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  List<AzkarModel>? _cachedAzkar;

  static const String _keyPrefix = 'sakina_zikr_count_';
  static const String _favPrefix = 'sakina_zikr_fav_';
  static const String _lastResetMorningKey = 'sakina_azkar_last_reset_morning';
  static const String _lastResetEveningKey = 'sakina_azkar_last_reset_evening';

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Initialize and load azkar from bundled JSON asset
  Future<List<AzkarModel>> getAllAzkar({bool forceReload = false}) async {
    if (_cachedAzkar != null && !forceReload) {
      await _checkAndPerformAutoResets();
      return _applyProgressToCached();
    }

    try {
      final jsonString = await rootBundle.loadString(AppConstants.azkarJsonPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> list = data['azkar'] as List<dynamic>? ?? [];

      _cachedAzkar = list.map((item) {
        return AzkarModel.fromJson(item as Map<String, dynamic>);
      }).toList();

      await _checkAndPerformAutoResets();
      return _applyProgressToCached();
    } catch (e) {
      // Fallback if asset loading fails
      return _cachedAzkar ?? [];
    }
  }

  /// Get azkar filtered by category identifier
  Future<List<AzkarModel>> getAzkarByCategory(String categoryId) async {
    final all = await getAllAzkar();
    final cat = AzkarCategory.fromId(categoryId);
    return all.where((z) => z.categoryId == cat.id).toList();
  }

  /// Check and reset morning azkar after Fajr, and evening azkar after Asr
  Future<void> _checkAndPerformAutoResets() async {
    final prefs = await _getPrefs();
    final now = DateTime.now();

    // Morning reset threshold: around 4:00 AM (Fajr time)
    final morningResetThreshold = DateTime(now.year, now.month, now.day, 4, 0);
    final lastMorningResetMs = prefs.getInt(_lastResetMorningKey) ?? 0;
    final lastMorningReset = DateTime.fromMillisecondsSinceEpoch(lastMorningResetMs);

    if (now.isAfter(morningResetThreshold) && lastMorningReset.isBefore(morningResetThreshold)) {
      await resetCategory(AzkarCategory.morning.id);
      await prefs.setInt(_lastResetMorningKey, now.millisecondsSinceEpoch);
    }

    // Evening reset threshold: around 15:30 (Asr time)
    final eveningResetThreshold = DateTime(now.year, now.month, now.day, 15, 30);
    final lastEveningResetMs = prefs.getInt(_lastResetEveningKey) ?? 0;
    final lastEveningReset = DateTime.fromMillisecondsSinceEpoch(lastEveningResetMs);

    if (now.isAfter(eveningResetThreshold) && lastEveningReset.isBefore(eveningResetThreshold)) {
      await resetCategory(AzkarCategory.evening.id);
      await prefs.setInt(_lastResetEveningKey, now.millisecondsSinceEpoch);
    }
  }

  /// Apply stored counts and favorites from SharedPreferences
  Future<List<AzkarModel>> _applyProgressToCached() async {
    if (_cachedAzkar == null) return [];
    final prefs = await _getPrefs();

    return _cachedAzkar!.map((zikr) {
      final count = prefs.getInt('$_keyPrefix${zikr.id}') ?? 0;
      final isFav = prefs.getBool('$_favPrefix${zikr.id}') ?? false;
      return zikr.copyWith(
        currentCount: count,
        isFavorite: isFav,
      );
    }).toList();
  }

  /// Increment count for a specific Zikr
  Future<AzkarModel> incrementZikr(String id) async {
    final prefs = await _getPrefs();
    final key = '$_keyPrefix$id';
    final current = prefs.getInt(key) ?? 0;

    final all = await getAllAzkar();
    final itemIndex = all.indexWhere((z) => z.id == id);
    if (itemIndex == -1) {
      throw Exception('Zikr not found: $id');
    }

    final item = all[itemIndex];
    if (current < item.count) {
      final newCount = current + 1;
      await prefs.setInt(key, newCount);
      return item.copyWith(currentCount: newCount);
    }
    return item;
  }

  /// Reset count for a specific Zikr
  Future<void> resetZikr(String id) async {
    final prefs = await _getPrefs();
    await prefs.remove('$_keyPrefix$id');
  }

  /// Reset all azkar in a category
  Future<void> resetCategory(String categoryId) async {
    final items = await getAzkarByCategory(categoryId);
    final prefs = await _getPrefs();
    for (final item in items) {
      await prefs.remove('$_keyPrefix${item.id}');
    }
  }

  /// Toggle favorite status of a Zikr
  Future<bool> toggleFavorite(String id) async {
    final prefs = await _getPrefs();
    final key = '$_favPrefix$id';
    final isFav = prefs.getBool(key) ?? false;
    final newFav = !isFav;
    await prefs.setBool(key, newFav);
    return newFav;
  }

  /// Get favorite azkar
  Future<List<AzkarModel>> getFavorites() async {
    final all = await getAllAzkar();
    return all.where((z) => z.isFavorite).toList();
  }

  /// Get category progress (0.0 to 1.0)
  Future<double> getCategoryProgress(String categoryId) async {
    final items = await getAzkarByCategory(categoryId);
    if (items.isEmpty) return 0.0;
    int completed = 0;
    for (final item in items) {
      if (item.isCompleted) completed++;
    }
    return completed / items.length;
  }

  /// Get total completed azkar count across all categories today
  Future<int> getTotalCompletedCount() async {
    final all = await getAllAzkar();
    return all.where((z) => z.isCompleted).length;
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

final azkarRepositoryProvider = Provider<AzkarRepository>((ref) {
  return AzkarRepository();
});

/// Notifier to manage dynamic state of Azkar list for a category
class AzkarListNotifier extends StateNotifier<AsyncValue<List<AzkarModel>>> {
  AzkarListNotifier(this._repository, this._categoryId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final AzkarRepository _repository;
  final String _categoryId;

  Future<void> load() async {
    try {
      final list = await _repository.getAzkarByCategory(_categoryId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> increment(String id) async {
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    final updated = await _repository.incrementZikr(id);
    state = AsyncValue.data([
      for (final item in currentList)
        if (item.id == id) updated else item,
    ]);
  }

  Future<void> resetSingle(String id) async {
    await _repository.resetZikr(id);
    await load();
  }

  Future<void> resetAll() async {
    await _repository.resetCategory(_categoryId);
    await load();
  }

  Future<void> toggleFav(String id) async {
    await _repository.toggleFavorite(id);
    await load();
  }
}

final azkarListProvider = StateNotifierProvider.family<AzkarListNotifier,
    AsyncValue<List<AzkarModel>>, String>((ref, categoryId) {
  final repo = ref.watch(azkarRepositoryProvider);
  return AzkarListNotifier(repo, categoryId);
});

/// All favorite azkar across all categories
final favoritesAzkarProvider =
    FutureProvider<List<AzkarModel>>((ref) async {
  final repo = ref.watch(azkarRepositoryProvider);
  return repo.getFavorites();
});

/// Progress map for all categories: Map<category_id, double 0.0..1.0>
final azkarCategoriesProgressProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final repo = ref.watch(azkarRepositoryProvider);
  final map = <String, double>{};
  for (final cat in AzkarCategory.values) {
    map[cat.id] = await repo.getCategoryProgress(cat.id);
  }
  return map;
});
