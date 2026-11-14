import 'package:flutter/material.dart';

/// Categories of Azkar in Hisn Al Muslim.
enum AzkarCategory {
  morning('morning', 'أذكار الصباح', 'Morning Azkar', Icons.wb_sunny_outlined),
  evening('evening', 'أذكار المساء', 'Evening Azkar', Icons.nights_stay_outlined),
  afterPrayer('after_prayer', 'أذكار بعد الصلاة', 'After Prayer Azkar', Icons.access_time_rounded),
  sleep('sleep', 'أذكار النوم', 'Azkar Before Sleep', Icons.bedtime_outlined),
  wakeup('wakeup', 'أذكار الاستيقاظ', 'Azkar Upon Waking', Icons.wb_twilight_rounded),
  misc('misc', 'أذكار وأدعية متنوعة', 'Miscellaneous Duas', Icons.auto_stories_rounded);

  final String id;
  final String titleAr;
  final String titleEn;
  final IconData icon;

  const AzkarCategory(this.id, this.titleAr, this.titleEn, this.icon);

  static AzkarCategory fromId(String id) {
    if (id == 'waking' || id == 'wakeup' || id == 'أذكار الاستيقاظ') return AzkarCategory.wakeup;
    if (id == 'morning' || id == 'أذكار الصباح') return AzkarCategory.morning;
    if (id == 'evening' || id == 'أذكار المساء') return AzkarCategory.evening;
    if (id == 'after_prayer' || id == 'afterPrayer' || id == 'أذكار بعد الصلاة') return AzkarCategory.afterPrayer;
    if (id == 'sleep' || id == 'أذكار النوم') return AzkarCategory.sleep;
    return AzkarCategory.values.firstWhere(
      (c) => c.id == id,
      orElse: () => AzkarCategory.misc,
    );
  }
}

/// Representation of an authentic Dhikr from Hisn Al Muslim.
class AzkarModel {
  final String id;
  final String categoryId;
  final String text; // Arabic with full tashkeel
  final String? translation; // English/Turkish translation
  final String? source; // Hadith source reference (e.g. البخاري ومسلم)
  final String? virtue; // فضل الذكر
  final int count; // Target repetition count (1, 3, 33, 100)
  final int currentCount; // User's completed repetitions today
  final bool isFavorite;

  const AzkarModel({
    required this.id,
    required this.categoryId,
    required this.text,
    this.translation,
    this.source,
    this.virtue,
    this.count = 1,
    this.currentCount = 0,
    this.isFavorite = false,
  });

  /// Check whether repetitions for this dhikr are satisfied.
  bool get isCompleted => currentCount >= count;

  /// Number of repetitions left.
  int get remainingCount => (count - currentCount).clamp(0, count);

  /// Progress fraction (0.0 to 1.0).
  double get progress => count == 0 ? 1.0 : (currentCount / count).clamp(0.0, 1.0);

  AzkarCategory get category => AzkarCategory.fromId(categoryId);

  AzkarModel increment() {
    if (isCompleted) return this;
    return copyWith(currentCount: currentCount + 1);
  }

  AzkarModel reset() {
    return copyWith(currentCount: 0);
  }

  AzkarModel toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  AzkarModel copyWith({
    String? id,
    String? categoryId,
    String? text,
    String? translation,
    String? source,
    String? virtue,
    int? count,
    int? currentCount,
    bool? isFavorite,
  }) {
    return AzkarModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      text: text ?? this.text,
      translation: translation ?? this.translation,
      source: source ?? this.source,
      virtue: virtue ?? this.virtue,
      count: count ?? this.count,
      currentCount: currentCount ?? this.currentCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': categoryId,
        'text': text,
        'translation': translation,
        'source': source,
        'virtue': virtue,
        'count': count,
        'currentCount': currentCount,
        'isFavorite': isFavorite,
      };

  factory AzkarModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category_key'] as String? ??
        json['category'] as String? ??
        'misc';
    final resolvedCatId = AzkarCategory.fromId(cat).id;
    return AzkarModel(
      id: json['id']?.toString() ?? '',
      categoryId: resolvedCatId,
      text: json['text'] as String? ?? '',
      translation: json['translation'] as String?,
      source: json['source'] as String?,
      virtue: json['virtue'] as String?,
      count: json['count'] as int? ?? 1,
      currentCount: json['currentCount'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
