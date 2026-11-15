# تطبيق سَكِينة (Sakina) — الدليل الشامل والتوثيق التقني

تطبيق إسلامي هادئ وخفيف تم تصميمه وبناؤه بالكامل وفق مواصفات وثيقة `adhan-app-prompt.md`، يجمع بين مواقيت الصلاة والأذان، الأذكار، القبلة، السبحة الإلكترونية، ووضع العرض الدائم (Always-on Display).

---

## 🌟 أبرز مميزات التطبيق

1. **مواقيت الصلاة والأذان (بدون إنترنت 100%):**
   - حساب فلكي محلي دقيق يدعم 12 طريقة حسابية عالمية (أم القرى، رابطة العالم الإسلامي، الهيئة المصرية، كراتشي، ديانت، وغيرها).
   - مذهب العصر: الشافعي/الجمهور (ظل مثل) والحنفي (ظلان).
   - قواعد خطوط العرض العالية.
   - تعديل يدوي مستقل لكل صلاة (−30 إلى +30 دقيقة).
   - تخزين مسبق للمواقيت لمدة 60 يوماً.

2. **الشاشة الدائمة (Always-on Display):**
   - تظهر الساعة والتاريخ والصلاة القادمة والعد التنازلي عند إطفاء الشاشة، بخلفية سوداء حقيقية (`#000000`) وسطوع منخفض يناسب شاشات AMOLED.
   - **طريقة التفعيل والظهور:** عند إطفاء الشاشة، أو حول وقت الأذان فقط (قبل/بعد بدقائق قابلة للضبط)، أو أثناء الشحن فقط، أو ضمن جدول زمني يومي.
   - **شكل الساعة:** 4 أنماط (رقمي عصري، خط كلاسيكي، بسيط ناعم، إطار هندسي)، مع نوع الأرقام (لاتينية/عربية) واللون المميز (4 ألوان).
   - **التاريخ الهجري** يتبع إزاحة الأيام (−2 إلى +2) المضبوطة في إعدادات المواقيت.
   - **حماية من احتراق الشاشة (Burn-in Protection):** تنقّل بطيء مستمر لكتلة العرض كاملة.

3. **شاشة القفل التفاعلية وقت الأذان (`AodActivity`):**
   - تعمل بنظام `setShowWhenLocked(true)` و`setTurnScreenOn(true)` و`fullScreenIntent` لتجاوز قفل الشاشة وقت دخول وقت الصلاة وعرض الأذان مباشرة بدون الحاجة لفتح القفل.
   - أزرار تفاعلية: إيقاف الأذان، تأجيل 5 دقائق، وصليت.

4. **تنبيهات وأذان موثوقة (Android Native Kotlin):**
   - جدولة دقيقة عبر `AlarmManager.setExactAndAllowWhileIdle`.
   - خدمة أمامية (`AdhanForegroundService`) لتشغيل صوت الأذان مع خيار رفع الصوت تدريجياً.
   - مستقبلات النظام: `BootReceiver` لإعادة الجدولة التلقائية فور إعادة تشغيل الجهاز، و`TimeChangeReceiver` لتحديث المواقيت عند تغيير المنطقة الزمنية أو الوقت.

5. **الأذكار وحصن المسلم:**
   - قاعدة بيانات متكاملة محلياً (`azkar.json`) بنصوص موثوقة ومشكلة بالكامل.
   - أذكار الصباح، المساء، بعد الصلاة، النوم، والاستيقاظ.
   - عداد تفاعلي، اهتزاز هادئ، انتقال تلقائي، وتصفير ذكي بعد الفجر وبعد العصر.

6. **بوصلة القبلة:**
   - بوصلة دائرية هادئة بحساسات الجهاز ومحاذاة بزاوية ±3° مع اهتزاز وإضاءة خضراء عند الاتجاه الصحيح إلى الكعبة المشرفة.

7. **السبحة الإلكترونية:**
   - عداد لمس كبير، أهداف 33/99/100/مخصص، حفظ إحصائيات يومية وأسبوعية.

8. **نظام التصميم (Design System):**
   - 3 أوضاع ثيم: الليلي الافتراضي (`#0E1514`)، النهاري (`#F6F4EE`)، وAMOLED الأسود (`#000000`).
   - خطوط أصيلة: خط **Cairo** لواجهة المستخدم وخط **Amiri** للنصوص القرآنية والأذكار، متضمنة بملفات TTF حقيقية.

---

## 🗂 بنية الملفات المُنجزة (Structure)

```
sakina/
├── pubspec.yaml                          # الحزم والإعدادات والخطوط والأصول
├── android/
│   ├── build.gradle                      # إعدادات Gradle الرئيسية
│   ├── settings.gradle
│   ├── app/
│   │   ├── build.gradle                  # minSdk 24, targetSdk 35
│   │   └── src/main/
│   │       ├── AndroidManifest.xml       # كافة الصلاحيات والأنشطة والخدمات والمستقبلات
│   │       ├── res/
│   │       │   ├── xml/prayer_widget_info.xml
│   │       │   ├── layout/prayer_widget.xml
│   │       │   └── values/{strings,styles,colors}.xml
│   │       └── kotlin/com/sakina/app/
│   │           ├── MainActivity.kt       # النشاط الرئيسي وربط القنوات
│   │           ├── alarm/
│   │           │   ├── AlarmScheduler.kt # جدولة المنبهات الدقيقة 7 أيام
│   │           │   ├── AdhanReceiver.kt  # استقبال المنبه وعرض الإشعار
│   │           │   ├── BootReceiver.kt   # إعادة الجدولة عند تشغيل الجهاز
│   │           │   ├── AlarmReceiver.kt
│   │           │   └── TimeChangeReceiver.kt
│   │           ├── service/
│   │           │   └── AdhanForegroundService.kt # تشغيل صوت الأذان
│   │           ├── aod/
│   │           │   ├── AodActivity.kt           # شاشة العرض الدائم فوق القفل
│   │           │   ├── AlwaysOnService.kt       # يراقب إطفاء الشاشة ويطبق قواعد الظهور
│   │           │   └── AlwaysOnConfig.kt        # إعدادات الشاشة الدائمة
│   │           ├── widget/
│   │           │   └── PrayerWidget.kt          # ودجت الشاشة الرئيسية
│   │           └── bridge/
│   │               ├── AlarmBridgePlugin.kt     # جسر المنبهات والصلاحيات
│   │               └── AodBridgePlugin.kt       # جسر الشاشة الدائمة
├── assets/
│   ├── audio/                            # ملفات الأذان والتكبير
│   ├── data/azkar.json                   # قاعدة الأذكار الكاملة بالتشكيل
│   └── fonts/                            # خطوط Cairo و Amiri بصيغة TTF
└── lib/
    ├── main.dart                         # نقطة البداية، Theme، Navigation
    ├── core/
    │   ├── theme/{app_theme,app_colors}.dart
    │   ├── i18n/{app_localizations,strings_ar,strings_en,strings_tr}.dart
    │   ├── constants/app_constants.dart
    │   ├── utils/{alarm_bridge,date_utils,prayer_icons,qibla_calculator}.dart
    │   └── permissions/permission_service.dart
    ├── data/
    │   ├── prayer/{prayer_calculator,prayer_repository}.dart
    │   ├── azkar/azkar_repository.dart
    │   ├── location/location_service.dart
    │   ├── notifications/notification_service.dart
    │   └── settings/settings_repository.dart
    ├── domain/models/
    │   ├── prayer_time_model.dart
    │   ├── azkar_model.dart
    │   └── settings_model.dart
    └── features/
        ├── home/{home_screen.dart, widgets/..., providers/...}
        ├── azkar/{azkar_screen, azkar_list_screen, azkar_detail_screen}.dart
        ├── qibla/{qibla_screen, widgets/compass_widget}.dart
        ├── tasbih/tasbih_screen.dart
        ├── aod/always_on_screen.dart
        └── settings/{settings_screen, pages/..., widgets/...}
```

---

## 🛠 طريقة تجميع ملف الـ APK (Build Instructions)

لأنك فضّلت مرحلة التجميع لنفسك، إليك الخطوات البسيطة لبناء الـ APK على جهازك:

### 1. تثبيت الحزم وتجهيز المشروع
افتح منفذ الأوامر (Terminal) في مجلد المشروع:
```bash
cd "C:\Users\PREDATOR\.gemini\antigravity\scratch\sakina"
flutter pub get
```

### 2. بناء ملف الـ APK
لإنشاء نسخة تثبيت سريعة ومحسنة لمعالجات الهواتف الحديثة (arm64-v8a):
```bash
flutter build apk --release
```
أو لبناء حزم منفصلة لكل معمارية (حجم أصغر):
```bash
flutter build apk --split-per-abi
```

### 3. مكان ملف الـ APK الناتج:
ستجد الملف الجاهز للتثبيت على هاتفك مباشرة في المسار:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🚀 البناء الآلي عبر GitHub Actions (CI/CD)

يحتوي المشروع على سير عمل آلي مدمج في [`.github/workflows/build_apk.yml`](.github/workflows/build_apk.yml) يقوم بما يلي:
1. البناء التلقائي عند كل دفع (Push) أو طلب سحب (PR) إلى فرع `main`.
2. إمكانية التشغيل اليدوي بزر (Run workflow) من تبويب **Actions** على GitHub في أي وقت.
3. بناء نسختين كاملتين:
   - **`sakina-arm64-release.apk`**: نسخة خفيفة وسريعة مخصصة للأجهزة الحديثة (حجم ~22MB).
   - **`sakina-universal-release.apk`**: نسخة شاملة تعمل على كافة أجهزة أندرويد (حجم ~55MB).
4. رفع حزم الـ APK مباشرة كمرفقات قابلة للتنزيل فوراً تحت اسم `Sakina-APKs`.

---

