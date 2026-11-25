import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/alarm_bridge.dart';

class PermissionItemData {
  final String key;
  final String titleAr;
  final String descriptionAr;
  final IconData icon;
  final bool isEssential;
  final String whyNeededAr;

  const PermissionItemData({
    required this.key,
    required this.titleAr,
    required this.descriptionAr,
    required this.icon,
    required this.isEssential,
    required this.whyNeededAr,
  });
}

class PermissionCheckScreen extends StatefulWidget {
  const PermissionCheckScreen({super.key});

  @override
  State<PermissionCheckScreen> createState() => _PermissionCheckScreenState();
}

class _PermissionCheckScreenState extends State<PermissionCheckScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  int _permissionCheckId = 0;
  Map<String, bool> _permissionStatus = const {};
  List<PermissionItemData> get _permissions => _permissionItems
      .where((item) => item.key != 'doNotDisturb' ||
          _permissionStatus['prayerSilenceSupported'] != false)
      .toList();

  static const _permissionItems = [
    PermissionItemData(
      key: 'notifications',
      titleAr: 'إشعارات الأذان والذكر',
      descriptionAr: 'لإرسال تنبيهات الأذان والأذكار في مواعيدها المحددة بدقة.',
      icon: Icons.notifications_active_outlined,
      isEssential: true,
      whyNeededAr: 'بدون هذا الإذن لن يتمكن التطبيق من تنبيهك عند دخول الوقت.',
    ),
    PermissionItemData(
      key: 'exactAlarm',
      titleAr: 'المنبه الدقيق (Exact Alarms)',
      descriptionAr: 'لجدولة إطلاق الأذان في الثانية المحددة حتى لو كان الجهاز في وضع الخمول العميق.',
      icon: Icons.alarm_on_outlined,
      isEssential: true,
      whyNeededAr: 'ضروري جداً في أندرويد 12+ لضمان عدم تأخر الأذان دقيقة واحدة.',
    ),
    PermissionItemData(
      key: 'batteryOptimizationIgnored',
      titleAr: 'تجاهل تحسين البطارية',
      descriptionAr: 'لمنع نظام أندرويد من قتل خدمة الأذان في الخلفية لتوفير الشحن.',
      icon: Icons.battery_charging_full_outlined,
      isEssential: true,
      whyNeededAr: 'يضمن استمرار عمل التطبيق في الخلفية دون أن يوقفه النظام.',
    ),
    PermissionItemData(
      key: 'location',
      titleAr: 'الموقع الجغرافي (GPS)',
      descriptionAr: 'لتحديد إحداثيات مدينتك وحساب مواقيت الصلاة واتجاه القبلة بدقة متناهية.',
      icon: Icons.location_on_outlined,
      isEssential: true,
      whyNeededAr: 'يستخدم فقط لحساب الزوايا الشمسية واتجاه الكعبة المشرفة.',
    ),
    PermissionItemData(
      key: 'fullScreenIntent',
      titleAr: 'واجهة الأذان بملء الشاشة',
      descriptionAr: 'لإظهار شاشة الأذان التفاعلية عند رنين الأذان والشاشة مقفلة.',
      icon: Icons.fullscreen_outlined,
      isEssential: false,
      whyNeededAr: 'يتيح لك رؤية اسم الصلاة وخيار كتم الصوت من شاشة القفل فوراً.',
    ),
    PermissionItemData(
      key: 'drawOverApps',
      titleAr: 'الظهور فوق التطبيقات',
      descriptionAr: 'يُستخدم لإظهار الشاشة الدائمة أثناء قفل الهاتف.',
      icon: Icons.layers_outlined,
      isEssential: false,
      whyNeededAr: 'مطلوب فقط إذا كنت ترغب في تشغيل ميزة شاشة القفل الدائمة.',
    ),
    PermissionItemData(
      key: 'doNotDisturb',
      titleAr: 'التحكم في «عدم الإزعاج»',
      descriptionAr: 'لتفعيل الصامت أثناء الصلاة حسب الأوقات التي تختارها.',
      icon: Icons.do_not_disturb_on_outlined,
      isEssential: false,
      whyNeededAr: 'يتيح تشغيل الصامت وإيقافه تلقائياً حسب جدولك.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    if (!mounted) return;
    final checkId = ++_permissionCheckId;
    setState(() => _isLoading = true);

    final status = await _readPermissionStatus();

    if (mounted && checkId == _permissionCheckId) {
      setState(() {
        _permissionStatus = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _fixPermission(String key) async {
    switch (key) {
      case 'doNotDisturb':
        try {
          await AlarmBridge.requestPrayerSilenceAccess();
        } catch (_) {
          await openAppSettings();
        }
        break;
      case 'notifications':
        final status = await Permission.notification.request();
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        break;
      case 'exactAlarm':
        try {
          await AlarmBridge.requestExactAlarmPermission();
        } catch (_) {
          await openAppSettings();
        }
        break;
      case 'batteryOptimizationIgnored':
        try {
          await AlarmBridge.requestBatteryOptimizationExemption();
        } catch (_) {
          await Permission.ignoreBatteryOptimizations.request();
        }
        break;
      case 'location':
        final status = await Permission.locationWhenInUse.request();
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        break;
      case 'fullScreenIntent':
        var opened = false;
        try {
          opened = await AlarmBridge.openFullScreenIntentSettings();
        } catch (_) {}
        if (!opened) await openAppSettings();
        break;
      case 'drawOverApps':
        try {
          await AlarmBridge.requestDrawOverApps();
        } catch (_) {
          await Permission.systemAlertWindow.request();
        }
        break;
    }
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkAllPermissions();
  }

  int get _grantedCount =>
      _permissions.where((p) => _permissionStatus[p.key] == true).length;

  bool get _allEssentialGranted {
    for (final p in _permissions.where((p) => p.isEssential)) {
      if (!(_permissionStatus[p.key] ?? false)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.nightBackground : AppColors.dayBackground,
        appBar: AppBar(
          backgroundColor:
              isDark ? AppColors.nightSurface : AppColors.daySurface,
          elevation: 0,
          title: Text(
            'فحص وضبط الأذونات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.nightTextPrimary
                  : AppColors.dayTextPrimary,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: primary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: primary),
              tooltip: 'إعادة الفحص',
              onPressed: _checkAllPermissions,
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: primary,
                ),
              )
            : ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Status summary card
                  _buildSummaryHeader(isDark, primary),
                  const SizedBox(height: 16),

                  // Section Title
                  Text(
                    'أذونات التشغيل والتنبيه',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.nightPrimary
                          : AppColors.dayPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Permission list
                  ..._permissions.map((p) {
                    final isGranted = _permissionStatus[p.key];
                    return _buildPermissionCard(p, isGranted, isDark, primary);
                  }),

                  const SizedBox(height: 20),

                  // Manufacturer notes
                  _buildManufacturerGuide(isDark, primary),

                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryHeader(bool isDark, Color primary) {
    final allGood = _allEssentialGranted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: allGood
            ? (isDark
                ? AppColors.nightPrimary.withOpacity(0.12)
                : const Color(0xFFE8F5E9))
            : (isDark
                ? AppColors.error.withOpacity(0.12)
                : const Color(0xFFFFEBEE)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: allGood
              ? (isDark ? AppColors.nightPrimary : AppColors.dayPrimary)
              : AppColors.error,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: allGood ? AppColors.success : AppColors.error,
            ),
            child: Icon(
              allGood ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allGood
                      ? 'جميع الأذونات الأساسية مكتملة'
                      : 'راجع حالة الأذونات الأساسية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.nightTextPrimary
                        : AppColors.dayTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  allGood
                      ? 'أذونات التشغيل الأساسية مفعّلة.'
                      : 'فعّل الأذونات المطلوبة من القائمة أدناه.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: isDark
                        ? AppColors.nightTextSecondary
                        : AppColors.dayTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$_grantedCount/${_permissions.length}',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: allGood ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(
    PermissionItemData p,
    bool? status,
    bool isDark,
    Color primary,
  ) {
    final isGranted = status == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : AppColors.daySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? (isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06))
              : (p.isEssential
                  ? AppColors.error.withOpacity(0.4)
                  : Colors.transparent),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Status icon indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGranted
                        ? AppColors.success.withOpacity(0.18)
                        : AppColors.error.withOpacity(0.18),
                  ),
                  child: Center(
                    child: Icon(
                      status == null ? Icons.help_outline : (isGranted ? Icons.check : Icons.close),
                      color: isGranted ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title + essential tag
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.titleAr,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.nightTextPrimary
                                    : AppColors.dayTextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (p.isEssential)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'مهم',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.descriptionAr,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: isDark
                              ? AppColors.nightTextSecondary
                              : AppColors.dayTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Fix / Grant button
                if (!isGranted)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.isEssential ? primary : AppColors.nightElevated,
                      foregroundColor: p.isEssential
                          ? (isDark ? Colors.black : Colors.white)
                          : primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      minimumSize: const Size(60, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _fixPermission(p.key),
                    child: Text(
                      status == null ? 'غير مؤكّد' : 'يحتاج تفعيل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    'مفعّل ✔',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManufacturerGuide(bool isDark, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightElevated : AppColors.dayChip,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(Icons.settings_suggest_outlined, color: primary),
        title: Text(
          'تعليمات الشركات المصنعة لمنع إيقاف الأذان',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.nightTextPrimary
                : AppColors.dayTextPrimary,
          ),
        ),
        subtitle: Text(
          'شاومي، سامسونج، هواوي، أوبو / ريلمي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: isDark
                ? AppColors.nightTextSecondary
                : AppColors.dayTextSecondary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildManufacturerItem(
                  brand: 'Xiaomi / Poco / Redmi (MIUI / HyperOS)',
                  tips:
                      '١. افتح شاشة التطبيقات الحديثة واضغط مطولاً على "المؤذان" ثم اختر أيقونة القفل 🔒.\n٢. الضبط > التطبيقات > إدارة التطبيقات > المؤذان > تفعيل "التشغيل التلقائي" (Autostart).\n٣. موفر البطارية > اختر "لا توجد قيود" (No restrictions).',
                  isDark: isDark,
                  primary: primary,
                ),
                const Divider(height: 20),
                _buildManufacturerItem(
                  brand: 'Samsung (One UI)',
                  tips:
                      '١. الضبط > العناية بالجهاز > البطارية > حدود استخدام الخلفية.\n٢. تأكد من عدم وجود "المؤذان" في "تطبيقات في وضع السكون العميق".\n٣. معلومات تطبيق المؤذان > البطارية > اختر "غير مقيد" (Unrestricted).',
                  isDark: isDark,
                  primary: primary,
                ),
                const Divider(height: 20),
                _buildManufacturerItem(
                  brand: 'Huawei / Honor (EMUI / MagicOS)',
                  tips:
                      '١. الإعدادات > البطارية > بدء تشغيل التطبيقات (App Launch).\n٢. ابحث عن المؤذان وقم بتعطيل الإدارة التلقائية واختر "إدارة يدوية".\n٣. فعّل: التشغيل التلقائي، التشغيل الثانوي، والتشغيل في الخلفية.',
                  isDark: isDark,
                  primary: primary,
                ),
                const Divider(height: 20),
                _buildManufacturerItem(
                  brand: 'Oppo / Realme / OnePlus (ColorOS / OxygenOS)',
                  tips:
                      '١. الإعدادات > البطارية > إدارة بطارية التطبيقات > المؤذان > السماح بنشاط الخلفية.\n٢. إدارة التطبيقات > بدء التشغيل التلقائي > فعّل المؤذان.\n٣. قفل التطبيق في قائمة المهام الحديثة.',
                  isDark: isDark,
                  primary: primary,
                ),
                const SizedBox(height: 12),
                Center(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text(
                      'فتح إعدادات النظام للتطبيق',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    ),
                    onPressed: () => openAppSettings(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManufacturerItem({
    required String brand,
    required String tips,
    required bool isDark,
    required Color primary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.phone_android, size: 16, color: primary),
            const SizedBox(width: 6),
            Text(
              brand,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.nightTextPrimary
                    : AppColors.dayTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          tips,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            height: 1.5,
            color: isDark
                ? AppColors.nightTextSecondary
                : AppColors.dayTextSecondary,
          ),
        ),
      ],
    );
  }
}


Future<Map<String, bool>> _readPermissionStatus() async {
  try {
    return await AlarmBridge.checkPermissions();
  } catch (_) {
    return const {};
  }
}

class PermissionShortcut extends StatefulWidget {
  const PermissionShortcut({super.key});

  @override
  State<PermissionShortcut> createState() => _PermissionShortcutState();
}

class _PermissionShortcutState extends State<PermissionShortcut>
    with WidgetsBindingObserver {
  int _missing = 0;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final revision = ++_revision;
    final status = await _readPermissionStatus();
    if (!mounted || revision != _revision) return;
    setState(() {
      _missing = _PermissionCheckScreenState._permissionItems
          .where((item) => status[item.key] == false)
          .length;
    });
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: _missing > 0
            ? 'فحص الأذونات، $_missing تحتاج تفعيل'
            : 'فحص الأذونات',
        icon: Badge(
          isLabelVisible: _missing > 0,
          label: Text('$_missing'),
          child: const Icon(Icons.security_outlined),
        ),
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const PermissionCheckScreen(),
          ));
          if (mounted) _refresh();
        },
      );
}
