import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/azkar/azkar_repository.dart';
import '../../domain/models/azkar_model.dart';

/// Full screen reading and counting experience for a single Dhikr,
/// with auto-advance, haptics, font scaling, and smooth transitions.
class AzkarDetailScreen extends ConsumerStatefulWidget {
  const AzkarDetailScreen({
    super.key,
    required this.azkarList,
    required this.initialIndex,
    required this.categoryTitle,
  });

  final List<AzkarModel> azkarList;
  final int initialIndex;
  final String categoryTitle;

  @override
  ConsumerState<AzkarDetailScreen> createState() => _AzkarDetailScreenState();
}

class _AzkarDetailScreenState extends ConsumerState<AzkarDetailScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  late List<AzkarModel> _items;

  double _fontSize = 26.0;
  bool _autoAdvance = true;
  bool _keepScreenOn = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _items = List.of(widget.azkarList);
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTapCount(AzkarModel zikr) async {
    if (zikr.isCompleted) return;

    // Gentle haptic feedback
    HapticFeedback.lightImpact();

    final repo = ref.read(azkarRepositoryProvider);
    final updated = await repo.incrementZikr(zikr.id);

    setState(() {
      final idx = _items.indexWhere((item) => item.id == zikr.id);
      if (idx != -1) {
        _items[idx] = updated;
      }
    });

    // Check if newly completed
    if (updated.isCompleted) {
      HapticFeedback.mediumImpact();

      if (_autoAdvance && _currentIndex < _items.length - 1) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
            );
          }
        });
      }
    }
  }

  void _copyToClipboard(AzkarModel zikr) {
    final text = '${zikr.text}\n\n[${zikr.source ?? 'حصن المسلم'}]';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم نسخ الذكر إلى الحافظة',
          style: TextStyle(fontFamily: AppConstants.fontCairo),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showFontSizeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'حجم الخط العربي',
                style: TextStyle(
                  fontFamily: AppConstants.fontCairo,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('أ', style: TextStyle(fontFamily: AppConstants.fontAmiri, fontSize: 18)),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 20.0,
                      max: 36.0,
                      divisions: 8,
                      label: '${_fontSize.toInt()}sp',
                      onChanged: (val) {
                        setSheetState(() => _fontSize = val);
                        setState(() => _fontSize = val);
                      },
                    ),
                  ),
                  const Text('أ', style: TextStyle(fontFamily: AppConstants.fontAmiri, fontSize: 30, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text(
                  'الانتقال التلقائي عند اكتمال العدد',
                  style: TextStyle(fontFamily: AppConstants.fontCairo, fontSize: 15),
                ),
                value: _autoAdvance,
                onChanged: (val) {
                  setSheetState(() => _autoAdvance = val);
                  setState(() => _autoAdvance = val);
                },
              ),
              SwitchListTile(
                title: const Text(
                  'إبقاء الشاشة مضاءة أثناء القراءة',
                  style: TextStyle(fontFamily: AppConstants.fontCairo, fontSize: 15),
                ),
                value: _keepScreenOn,
                onChanged: (val) {
                  setSheetState(() => _keepScreenOn = val);
                  setState(() => _keepScreenOn = val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '${widget.categoryTitle} (${_currentIndex + 1} / ${_items.length})',
          style: const TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size_rounded),
            tooltip: 'تغيير حجم الخط',
            onPressed: _showFontSizeSheet,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'مشاركة الذكر',
            onPressed: () => _copyToClipboard(_items[_currentIndex]),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _items.length,
        onPageChanged: (idx) {
          setState(() => _currentIndex = idx);
        },
        itemBuilder: (context, index) {
          final zikr = _items[index];
          return _buildZikrReadingView(context, zikr);
        },
      ),
    );
  }

  Widget _buildZikrReadingView(BuildContext context, AzkarModel zikr) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDone = zikr.isCompleted;

    return SafeArea(
      child: Column(
        children: [
          // Top bar: Progress indicator of current zikr list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _items.length,
                minHeight: 4,
                backgroundColor: theme.dividerColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.nightPrimary : AppColors.dayPrimary,
                ),
              ),
            ),
          ),

          // Scrollable reader containing virtue, text, and source
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Virtue / فضل الذكر Box
                  if (zikr.virtue != null && zikr.virtue!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.nightSecondary : AppColors.daySecondary)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isDark ? AppColors.nightSecondary : AppColors.daySecondary)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: isDark ? AppColors.nightSecondary : AppColors.daySecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              zikr.virtue!,
                              style: TextStyle(
                                fontFamily: AppConstants.fontCairo,
                                fontSize: 13,
                                height: 1.5,
                                color: isDark ? AppColors.nightSecondary : AppColors.daySecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Main Arabic Text with full Tashkeel
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      zikr.text,
                      style: TextStyle(
                        fontFamily: AppConstants.fontAmiri,
                        fontSize: _fontSize,
                        height: 2.0,
                        fontWeight: FontWeight.normal,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Source / Hadith reference below
                  if (zikr.source != null && zikr.source!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'المصدر: ${zikr.source!}',
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Interactive Counter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded), // RTL forward is back
                  tooltip: 'السابق',
                  onPressed: _currentIndex > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),

                // Giant Tap Counter Button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onTapCount(zikr),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: isDone
                                ? const LinearGradient(
                                    colors: [Color(0xFF2A9D8F), Color(0xFF4CAF88)],
                                  )
                                : LinearGradient(
                                    colors: isDark
                                        ? [AppColors.nightPrimary, const Color(0xFF4A9B83)]
                                        : [AppColors.dayPrimary, const Color(0xFF246654)],
                                  ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (isDone
                                        ? AppColors.success
                                        : (isDark ? AppColors.nightPrimary : AppColors.dayPrimary))
                                    .withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isDone
                                    ? 'تم الانتهاء ✓'
                                    : '${zikr.currentCount} من ${zikr.count}',
                                style: const TextStyle(
                                  fontFamily: AppConstants.fontCairo,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (!isDone)
                                const Text(
                                  'اضغط للتسبيح',
                                  style: TextStyle(
                                    fontFamily: AppConstants.fontCairo,
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Next button
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded), // RTL back is next
                  tooltip: 'التالي',
                  onPressed: _currentIndex < _items.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
