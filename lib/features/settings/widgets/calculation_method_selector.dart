import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/prayer/prayer_calculator.dart';

class CalculationMethodInfo {
  final CalculationMethod method;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String detailsAr;
  final String region;

  const CalculationMethodInfo({
    required this.method,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.detailsAr,
    required this.region,
  });
}

const List<CalculationMethodInfo> calculationMethodsList = [
  CalculationMethodInfo(
    method: CalculationMethod.ummAlQura,
    titleAr: 'جامعة أم القرى (مكة المكرمة)',
    titleEn: 'Umm Al-Qura University, Makkah',
    subtitleAr: 'الفجر ١٨.٥° • العشاء ٩٠ دقيقة بعد المغرب',
    detailsAr:
        'المعيار الرسمي في المملكة العربية السعودية ومعظم دول الخليج العربي. يحدد العشاء بعد ٩٠ دقيقة من المغرب (١٢٠ دقيقة في رمضان).',
    region: 'السعودية والخليج',
  ),
  CalculationMethodInfo(
    method: CalculationMethod.egyptian,
    titleAr: 'الهيئة المصرية العامة للمساحة',
    titleEn: 'Egyptian General Authority of Survey',
    subtitleAr: 'الفجر ١٩.٥° • العشاء ١٧.٥°',
    detailsAr:
        'المعتمد رسمياً في جمهورية مصر العربية وبعض دول شمال إفريقيا والشرق الأوسط والقرن الإفريقي.',
    region: 'مصر وإفريقيا',
  ),
  CalculationMethodInfo(
    method: CalculationMethod.mwl,
    titleAr: 'رابطة العالم الإسلامي (MWL)',
    titleEn: 'Muslim World League',
    subtitleAr: 'الفجر ١٨° • العشاء ١٧°',
    detailsAr:
        'المعيار المعتمد على نطاق واسع في أوروبا والشرق الأقصى وأجزاء من الولايات المتحدة الأمريكية.',
    region: 'عالمي وأوروبا',
  ),
  CalculationMethodInfo(
    method: CalculationMethod.karachi,
    titleAr: 'جامعة العلوم الإسلامية بكراتشي',
    titleEn: 'University of Islamic Sciences, Karachi',
    subtitleAr: 'الفجر ١٨° • العشاء ١٨°',
    detailsAr:
        'المعتمد في باكستان والهند وبنغلاديش وأفغانستان وأجزاء من وسط وجنوب آسيا مع المذهب الحنفي.',
    region: 'شبه القارة الهندية',
  ),
  CalculationMethodInfo(
    method: CalculationMethod.isna,
    titleAr: 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)',
    titleEn: 'Islamic Society of North America',
    subtitleAr: 'الفجر ١٥° • العشاء ١٥°',
    detailsAr:
        'معتمد لدى معظم المساجد والمراكز الإسلامية في الولايات المتحدة وكندا.',
    region: 'أمريكا الشمالية',
  ),
  CalculationMethodInfo(
    method: CalculationMethod.diyanet,
    titleAr: 'رئاسة الشؤون الدينية التركية (Diyanet)',
    titleEn: 'Diyanet İşleri Başkanlığı',
    subtitleAr: 'الفجر ١٨° • العشاء ١٧°',
    detailsAr:
        'المعيار الرسمي المعمول به في الجمهورية التركية والمساجد التركية في أوروبا.',
    region: 'تركيا',
  ),
  CalculationMethodInfo(
    method: CalculationMethod.dubai,
    titleAr: 'دائرة الشؤون الإسلامية بدبي',
    titleEn: 'Dubai Islamic Affairs',
    subtitleAr: 'الفجر ١٨.٢° • العشاء ١٨.٢°',
    detailsAr:
        'المعيار المعتمد رسمياً في إمارة دبي ودولة الإمارات العربية المتحدة.',
    region: 'الإمارات',
  ),
  CalculationMethodInfo(
    method: CalculationMethod.kuwait,
    titleAr: 'وزارة الأوقاف والشؤون الإسلامية بالكويت',
    titleEn: 'Kuwait Ministry of Awqaf',
    subtitleAr: 'الفجر ١٨° • العشاء ١٧.٥°',
    detailsAr:
        'الحساب المعتمد رسمياً في دولة الكويت وفق تقويم العجيري والمساجد الرسمية.',
    region: 'الكويت',
  ),
  CalculationMethodInfo(
    method: CalculationMethod.qatar,
    titleAr: 'وزارة الأوقاف القطرية',
    titleEn: 'Qatar Ministry of Awqaf',
    subtitleAr: 'الفجر ١٨° • العشاء ٩٠ دقيقة بعد المغرب',
    detailsAr:
        'الحساب المعتمد في التقويم القطري الرسمي وفقاً لوزارة الأوقاف والشؤون الإسلامية.',
    region: 'قطر',
  ),
  CalculationMethodInfo(
    method: CalculationMethod.singapore,
    titleAr: 'المجلس الإسلامي بسنغافورة (MUIS)',
    titleEn: 'Majlis Ugama Islam Singapura',
    subtitleAr: 'الفجر ٢٠° • العشاء ١٨°',
    detailsAr:
        'المعتمد في سنغافورة وماليزيا وبروناي وإندونيسيا والمناطق الاستوائية المجاورة.',
    region: 'جنوب شرق آسيا',
  ),
  CalculationMethodInfo(
    method: CalculationMethod.tehran,
    titleAr: 'معهد الجيوفيزياء بجامعة طهران',
    titleEn: 'Institute of Geophysics, Tehran',
    subtitleAr: 'الفجر ١٧.٧° • العشاء ١٤° • المغرب ٤.٥°',
    detailsAr:
        'حساب تقويم طهران المعمول به في إيران والمجتمعات الجعفرية مع زاوية الشفق ٤.٥ درجات للمغرب.',
    region: 'إيران والعراق',
  ),
  CalculationMethodInfo(
    method: CalculationMethod.custom,
    titleAr: 'تخصيص يدوي',
    titleEn: 'Custom Method',
    subtitleAr: 'ضبط زوايا الفجر والعشاء يدوياً',
    detailsAr:
        'يتيح لك تحديد زوايا الفجر والعشاء والإزاحات الزمنية الخاصة بما يناسب موقعك الجغرافي الخاص.',
    region: 'مخصص',
  ),
];

class CalculationMethodSelector {
  static Future<CalculationMethod?> show(
    BuildContext context, {
    required CalculationMethod selectedMethod,
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return showModalBottomSheet<CalculationMethod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurface : AppColors.daySurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag handle
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.nightTextSecondary.withOpacity(0.3)
                          : AppColors.dayTextSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title & Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'طريقة الحساب الفلكي',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.nightTextPrimary
                                    : AppColors.dayTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'اختر الهيئة أو التقويم المتبع في مدينتك',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.nightTextSecondary
                                    : AppColors.dayTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: isDark
                                ? AppColors.nightTextSecondary
                                : AppColors.dayTextSecondary,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20, thickness: 1),
                  // List of methods
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: calculationMethodsList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = calculationMethodsList[index];
                        final isSelected = item.method == selectedMethod;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.pop(ctx, item.method);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primary.withOpacity(isDark ? 0.16 : 0.12)
                                    : (isDark
                                        ? AppColors.nightElevated
                                        : const Color(0xFFF0EFEA)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? primary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Radio indicator
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? primary
                                            : (isDark
                                                ? AppColors.nightTextSecondary
                                                : AppColors.dayTextSecondary),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  // Text details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.titleAr,
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 15,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  color: isSelected
                                                      ? primary
                                                      : (isDark
                                                          ? AppColors
                                                              .nightTextPrimary
                                                          : AppColors
                                                              .dayTextPrimary),
                                                ),
                                              ),
                                            ),
                                            // Region tag badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF142421)
                                                    : const Color(0xFFE2EBE7),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                item.region,
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? AppColors.nightPrimary
                                                      : AppColors.dayPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.subtitleAr,
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? AppColors.nightSecondary
                                                : AppColors.daySecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.detailsAr,
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            height: 1.35,
                                            color: isDark
                                                ? AppColors.nightTextSecondary
                                                : AppColors.dayTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
