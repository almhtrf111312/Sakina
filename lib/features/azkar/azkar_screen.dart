import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/azkar/azkar_repository.dart';
import '../../domain/models/azkar_model.dart';
import 'azkar_list_screen.dart';

/// Categories grid screen showing Hisn Al Muslim sections with daily progress.
class AzkarScreen extends ConsumerWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progressAsync = ref.watch(azkarCategoriesProgressProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'أذكار المسلم',
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header banner with daily motivation & spiritual quote
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.nightPrimary.withOpacity(0.25),
                            AppColors.nightSurface,
                          ]
                        : [
                            AppColors.dayPrimary.withOpacity(0.15),
                            AppColors.daySurface,
                          ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.nightPrimary.withOpacity(0.3)
                        : AppColors.dayPrimary.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.nightPrimary : AppColors.dayPrimary)
                            .withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: isDark ? AppColors.nightPrimary : AppColors.dayPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '«أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ»',
                            style: TextStyle(
                              fontFamily: AppConstants.fontAmiri,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'حصن نفسك يومياً بأذكار الكتاب والسنة النبوية',
                            style: TextStyle(
                              fontFamily: AppConstants.fontCairo,
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'أبواب الأذكار',
                style: TextStyle(
                  fontFamily: AppConstants.fontCairo,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // Categories Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildListDelegate([
                _buildCategoryCard(
                  context,
                  category: AzkarCategory.morning,
                  icon: Icons.wb_sunny_rounded,
                  gradient: const [Color(0xFFE76F51), Color(0xFFF4A261)],
                  description: '١٥ ذِكْر - تُقال بعد صلاة الفجر',
                  progress: progressAsync.valueOrNull?[AzkarCategory.morning.id] ?? 0.0,
                ),
                _buildCategoryCard(
                  context,
                  category: AzkarCategory.evening,
                  icon: Icons.nightlight_round,
                  gradient: [Color(0xFF2A9D8F), AppColors.nightPrimary],
                  description: '١٥ ذِكْر - تُقال بعد صلاة العصر',
                  progress: progressAsync.valueOrNull?[AzkarCategory.evening.id] ?? 0.0,
                ),
                _buildCategoryCard(
                  context,
                  category: AzkarCategory.afterPrayer,
                  icon: Icons.mosque_rounded,
                  gradient: const [Color(0xFF457B9D), Color(0xFF7B9EA8)],
                  description: '١٠ أذكار - دبر كل صلاة مكتوبة',
                  progress: progressAsync.valueOrNull?[AzkarCategory.afterPrayer.id] ?? 0.0,
                ),
                _buildCategoryCard(
                  context,
                  category: AzkarCategory.sleep,
                  icon: Icons.bedtime_rounded,
                  gradient: const [Color(0xFF3D405B), Color(0xFF5B618A)],
                  description: '٨ أذكار - قبل إغفاء العين للنوم',
                  progress: progressAsync.valueOrNull?[AzkarCategory.sleep.id] ?? 0.0,
                ),
                _buildCategoryCard(
                  context,
                  category: AzkarCategory.wakeup,
                  icon: Icons.wb_twilight_rounded,
                  gradient: [AppColors.nightSecondary, Color(0xFFE2C485)],
                  description: '٥ أذكار - عند الانتباه واليقظة',
                  progress: progressAsync.valueOrNull?[AzkarCategory.wakeup.id] ?? 0.0,
                ),
                _buildFavoritesCard(context, ref),
              ]),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required AzkarCategory category,
    required IconData icon,
    required List<Color> gradient,
    required String description,
    required double progress,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percentInt = (progress * 100).toInt();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => AzkarListScreen(category: category),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: progress >= 1.0
                  ? Colors.green.withOpacity(0.5)
                  : theme.dividerColor.withOpacity(0.08),
              width: progress >= 1.0 ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  if (progress > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: progress >= 1.0
                            ? Colors.green.withOpacity(0.15)
                            : gradient.first.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        progress >= 1.0 ? 'مكتمل' : '$percentInt%',
                        style: TextStyle(
                          fontFamily: AppConstants.fontCairo,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: progress >= 1.0 ? Colors.green : gradient.first,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.titleAr,
                    style: const TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: theme.dividerColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? Colors.green : gradient.first,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const AzkarListScreen(
                category: AzkarCategory.misc,
                isFavoritesOnly: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE63946), Color(0xFFF28482)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'أذكاري المفضلة',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الأذكار المحفوظة للرجوع السريع إليها',
                    style: TextStyle(
                      fontFamily: AppConstants.fontCairo,
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 1.0,
                  minHeight: 5,
                  backgroundColor: theme.dividerColor.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE63946)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
