import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/azkar/azkar_repository.dart';
import '../../domain/models/azkar_model.dart';
import 'azkar_detail_screen.dart';

/// Screen listing all Azkar items inside a selected category
class AzkarListScreen extends ConsumerWidget {
  const AzkarListScreen({
    super.key,
    required this.category,
    this.isFavoritesOnly = false,
  });

  final AzkarCategory category;
  final bool isFavoritesOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = isFavoritesOnly ? 'أذكاري المفضلة' : category.titleAr;
    final state = ref.watch(azkarListProvider(category.id));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isFavoritesOnly)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'إعادة ضبط الأذكار',
              onPressed: () => _confirmResetAll(context, ref),
            ),
        ],
      ),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Text(
            'حدث خطأ أثناء تحميل الأذكار: $err',
            style: const TextStyle(fontFamily: AppConstants.fontCairo),
          ),
        ),
        data: (rawAzkar) {
          final azkar = isFavoritesOnly
              ? rawAzkar.where((z) => z.isFavorite).toList()
              : rawAzkar;

          if (azkar.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFavoritesOnly
                        ? Icons.favorite_border_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isFavoritesOnly
                        ? 'لم تقم بإضافة أي أذكار للمفضلة بعد'
                        : 'لا توجد أذكار في هذا القسم',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          final completedCount = azkar.where((z) => z.isCompleted).length;
          final totalCount = azkar.length;
          final overallProgress = totalCount > 0 ? completedCount / totalCount : 0.0;

          return Column(
            children: [
              // Overall category progress banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الإنجاز اليومي',
                          style: TextStyle(
                            fontFamily: AppConstants.fontCairo,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          '$completedCount من $totalCount ذِكْر ($completedCount / $totalCount)',
                          style: TextStyle(
                            fontFamily: AppConstants.fontCairo,
                            fontWeight: FontWeight.bold,
                            color: overallProgress >= 1.0
                                ? AppColors.success
                                : isDark
                                    ? AppColors.nightPrimary
                                    : AppColors.dayPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: overallProgress,
                        minHeight: 8,
                        backgroundColor: theme.dividerColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          overallProgress >= 1.0
                              ? AppColors.success
                              : isDark
                                  ? AppColors.nightPrimary
                                  : AppColors.dayPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Azkar list
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: azkar.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final zikr = azkar[index];
                    return _buildZikrTile(context, ref, zikr, index, azkar);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildZikrTile(
    BuildContext context,
    WidgetRef ref,
    AzkarModel zikr,
    int index,
    List<AzkarModel> fullList,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDone = zikr.isCompleted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => AzkarDetailScreen(
                azkarList: fullList,
                initialIndex: index,
                categoryTitle: category.titleAr,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isDone
                ? (isDark
                    ? AppColors.nightSurface.withOpacity(0.5)
                    : AppColors.daySurface.withOpacity(0.8))
                : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDone
                  ? AppColors.success.withOpacity(0.4)
                  : theme.dividerColor.withOpacity(0.08),
              width: isDone ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row: index and target counter badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.success.withOpacity(0.15)
                          : (isDark ? AppColors.nightPrimary : AppColors.dayPrimary)
                              .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'الذِّكْر ${index + 1}',
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDone
                            ? AppColors.success
                            : (isDark ? AppColors.nightPrimary : AppColors.dayPrimary),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Favorite button
                      IconButton(
                        icon: Icon(
                          zikr.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 20,
                          color: zikr.isFavorite ? Colors.red : theme.disabledColor,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(azkarListProvider(category.id).notifier).toggleFav(zikr.id);
                        },
                      ),
                      // Target count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'التكرار: ${zikr.count}',
                          style: TextStyle(
                            fontFamily: AppConstants.fontCairo,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Arabic Dhikr text with Tashkeel
              Text(
                zikr.text,
                style: TextStyle(
                  fontFamily: AppConstants.fontAmiri,
                  fontSize: 19,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                  color: isDone
                      ? theme.textTheme.bodyLarge?.color?.withOpacity(0.65)
                      : theme.textTheme.bodyLarge?.color,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),

              const SizedBox(height: 12),

              // Bottom row: Quick action counter button & progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (zikr.virtue != null && zikr.virtue!.isNotEmpty)
                    Expanded(
                      child: Text(
                        zikr.virtue!,
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 8),

                  // Mini tap counter button
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(azkarListProvider(category.id).notifier).increment(zikr.id);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.success.withOpacity(0.2)
                            : (isDark ? AppColors.nightPrimary : AppColors.dayPrimary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDone)
                            const Icon(Icons.check_rounded, color: AppColors.success, size: 16)
                          else
                            const Icon(Icons.touch_app_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            isDone ? 'مكتمل' : '${zikr.currentCount} / ${zikr.count}',
                            style: TextStyle(
                              fontFamily: AppConstants.fontCairo,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDone ? AppColors.success : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmResetAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'إعادة ضبط العدادات',
          style: TextStyle(fontFamily: AppConstants.fontCairo, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل تريد إعادة تصفير عدادات جميع الأذكار في هذا القسم؟',
          style: TextStyle(fontFamily: AppConstants.fontCairo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: AppConstants.fontCairo)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(azkarListProvider(category.id).notifier).resetAll();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('إعادة ضبط', style: TextStyle(fontFamily: AppConstants.fontCairo, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
