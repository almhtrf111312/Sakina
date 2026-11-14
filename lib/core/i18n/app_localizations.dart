import 'package:flutter/material.dart';

import 'strings_ar.dart';
import 'strings_en.dart';
import 'strings_tr.dart';

// ---------------------------------------------------------------------------
// AppLocalizations
// ---------------------------------------------------------------------------

/// Full localization class for Arabic (default / RTL), English and Turkish.
///
/// Usage:
///   final l10n = AppLocalizations.of(context);
///   Text(l10n.prayerFajr)
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  // Map of locale code → string table.
  static const Map<String, Map<String, String>> _tables = {
    'ar': StringsAr.strings,
    'en': StringsEn.strings,
    'tr': StringsTr.strings,
  };

  Map<String, String> get _strings =>
      _tables[locale.languageCode] ?? _tables['ar']!;

  String _t(String key) => _strings[key] ?? StringsAr.strings[key] ?? key;

  // ----------------------------------------------------------------
  // Delegate
  // ----------------------------------------------------------------

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static bool isRtl(Locale locale) => locale.languageCode == 'ar';

  // ================================================================
  // All string getters — add new keys here and in every strings_*.dart
  // ================================================================

  // ---- App & General ----
  String get appName => _t('appName');
  String get ok => _t('ok');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get close => _t('close');
  String get retry => _t('retry');
  String get loading => _t('loading');
  String get error => _t('error');
  String get success => _t('success');
  String get permissionDenied => _t('permissionDenied');
  String get openSettings => _t('openSettings');
  String get yes => _t('yes');
  String get no => _t('no');
  String get next => _t('next');
  String get back => _t('back');
  String get done => _t('done');
  String get reset => _t('reset');
  String get confirm => _t('confirm');

  // ---- Bottom Nav ----
  String get home => _t('home');
  String get azkar => _t('azkar');
  String get qibla => _t('qibla');
  String get tasbih => _t('tasbih');
  String get settings => _t('settings');

  // ---- Prayer Names ----
  String get prayerFajr => _t('prayerFajr');
  String get prayerSunrise => _t('prayerSunrise');
  String get prayerDhuhr => _t('prayerDhuhr');
  String get prayerAsr => _t('prayerAsr');
  String get prayerMaghrib => _t('prayerMaghrib');
  String get prayerIsha => _t('prayerIsha');

  // ---- Home Screen ----
  String get nextPrayer => _t('nextPrayer');
  String get prayerTimes => _t('prayerTimes');
  String get hijriDate => _t('hijriDate');
  String get gregorianDate => _t('gregorianDate');
  String get countdown => _t('countdown');
  String get remainingTime => _t('remainingTime');
  String get todaysPrayers => _t('todaysPrayers');
  String get locationNotFound => _t('locationNotFound');
  String get enableLocation => _t('enableLocation');
  String get locationPermissionTitle => _t('locationPermissionTitle');
  String get locationPermissionBody => _t('locationPermissionBody');
  String get calculating => _t('calculating');
  String get prayedAlready => _t('prayedAlready');

  // ---- Azkar Screen ----
  String get azkarMorning => _t('azkarMorning');
  String get azkarEvening => _t('azkarEvening');
  String get azkarSleep => _t('azkarSleep');
  String get azkarWakeup => _t('azkarWakeup');
  String get azkarAfterPrayer => _t('azkarAfterPrayer');
  String get azkarMisc => _t('azkarMisc');
  String get azkarCount => _t('azkarCount');
  String get azkarSource => _t('azkarSource');
  String get azkarVirtue => _t('azkarVirtue');
  String get azkarTranslation => _t('azkarTranslation');
  String get timesRemaining => _t('timesRemaining');
  String get completed => _t('completed');
  String get azkarCategories => _t('azkarCategories');

  // ---- Qibla Screen ----
  String get qiblaDirection => _t('qiblaDirection');
  String get qiblaAccuracy => _t('qiblaAccuracy');
  String get qiblaFacing => _t('qiblaFacing');
  String get qiblaDegrees => _t('qiblaDegrees');
  String get compassCalibrate => _t('compassCalibrate');
  String get compassCalibrateHint => _t('compassCalibrateHint');
  String get magnetometerUnavailable => _t('magnetometerUnavailable');
  String get qiblaFromLocation => _t('qiblaFromLocation');
  String get meccaCity => _t('meccaCity');
  String get yourLocation => _t('yourLocation');
  String get distance => _t('distance');
  String get km => _t('km');

  // ---- Tasbih Screen ----
  String get tasbihCounter => _t('tasbihCounter');
  String get tasbihTarget => _t('tasbihTarget');
  String get tasbihCycles => _t('tasbihCycles');
  String get tasbihReset => _t('tasbihReset');
  String get tasbihHaptic => _t('tasbihHaptic');
  String get tasbihSound => _t('tasbihSound');
  String get tasbihSubhanAllah => _t('tasbihSubhanAllah');
  String get tasbihAlhamdulillah => _t('tasbihAlhamdulillah');
  String get tasbihAllahuAkbar => _t('tasbihAllahuAkbar');
  String get tasbihLaIlahaIllallah => _t('tasbihLaIlahaIllallah');
  String get tasbihAstaghfirullah => _t('tasbihAstaghfirullah');
  String get tasbihCustom => _t('tasbihCustom');
  String get tasbihReachedTarget => _t('tasbihReachedTarget');

  // ---- Settings Screen ----
  String get settingsAppearance => _t('settingsAppearance');
  String get settingsTheme => _t('settingsTheme');
  String get settingsThemeNight => _t('settingsThemeNight');
  String get settingsThemeDay => _t('settingsThemeDay');
  String get settingsThemeAmoled => _t('settingsThemeAmoled');
  String get settingsLanguage => _t('settingsLanguage');
  String get settingsLanguageArabic => _t('settingsLanguageArabic');
  String get settingsLanguageEnglish => _t('settingsLanguageEnglish');
  String get settingsLanguageTurkish => _t('settingsLanguageTurkish');
  String get settingsPrayer => _t('settingsPrayer');
  String get settingsCalcMethod => _t('settingsCalcMethod');
  String get settingsMadhab => _t('settingsMadhab');
  String get settingsMadhabHanafi => _t('settingsMadhabHanafi');
  String get settingsMadhabShafi => _t('settingsMadhabShafi');
  String get settingsPrayerAdjust => _t('settingsPrayerAdjust');
  String get settingsNotifications => _t('settingsNotifications');
  String get settingsNotifType => _t('settingsNotifType');
  String get settingsNotifTypeAdhan => _t('settingsNotifTypeAdhan');
  String get settingsNotifTypeBeep => _t('settingsNotifTypeBeep');
  String get settingsNotifTypeSilent => _t('settingsNotifTypeSilent');
  String get settingsNotifTypeOff => _t('settingsNotifTypeOff');
  String get settingsAdhanSound => _t('settingsAdhanSound');
  String get settingsAod => _t('settingsAod');
  String get settingsAodEnabled => _t('settingsAodEnabled');
  String get settingsAodBrightness => _t('settingsAodBrightness');
  String get settingsAodShowHijri => _t('settingsAodShowHijri');
  String get settingsAodShowNext => _t('settingsAodShowNext');
  String get settingsPermissions => _t('settingsPermissions');
  String get settingsPermNotif => _t('settingsPermNotif');
  String get settingsPermLocation => _t('settingsPermLocation');
  String get settingsPermAlarm => _t('settingsPermAlarm');
  String get settingsPermBattery => _t('settingsPermBattery');
  String get settingsPermFullScreen => _t('settingsPermFullScreen');
  String get settingsPermDrawOver => _t('settingsPermDrawOver');
  String get settingsAbout => _t('settingsAbout');
  String get settingsVersion => _t('settingsVersion');
  String get settingsPrivacyPolicy => _t('settingsPrivacyPolicy');
  String get settingsRate => _t('settingsRate');
  String get settingsShare => _t('settingsShare');

  // ---- Calculation Methods ----
  String get calcMethodMwl => _t('calcMethodMwl');
  String get calcMethodIsna => _t('calcMethodIsna');
  String get calcMethodEgyptian => _t('calcMethodEgyptian');
  String get calcMethodMakkah => _t('calcMethodMakkah');
  String get calcMethodKarachi => _t('calcMethodKarachi');
  String get calcMethodTehran => _t('calcMethodTehran');
  String get calcMethodJafari => _t('calcMethodJafari');
  String get calcMethodTurkey => _t('calcMethodTurkey');
  String get calcMethodCustom => _t('calcMethodCustom');

  // ---- Permissions ----
  String get permGranted => _t('permGranted');
  String get permDenied => _t('permDenied');
  String get permRestricted => _t('permRestricted');
  String get permPermanentlyDenied => _t('permPermanentlyDenied');
  String get permRequest => _t('permRequest');

  // ---- Date / Time ----
  String get today => _t('today');
  String get tomorrow => _t('tomorrow');
  String get yesterday => _t('yesterday');
  String get hours => _t('hours');
  String get minutes => _t('minutes');
  String get seconds => _t('seconds');

  // ---- Hijri Months ----
  String get hijriMonthMuharram => _t('hijriMonthMuharram');
  String get hijriMonthSafar => _t('hijriMonthSafar');
  String get hijriMonthRabiAl => _t('hijriMonthRabiAl');
  String get hijriMonthRabiAth => _t('hijriMonthRabiAth');
  String get hijriMonthJumadaAl => _t('hijriMonthJumadaAl');
  String get hijriMonthJumadaAth => _t('hijriMonthJumadaAth');
  String get hijriMonthRajab => _t('hijriMonthRajab');
  String get hijriMonthShaaban => _t('hijriMonthShaaban');
  String get hijriMonthRamadan => _t('hijriMonthRamadan');
  String get hijriMonthShawwal => _t('hijriMonthShawwal');
  String get hijriMonthDhuAlQadah => _t('hijriMonthDhuAlQadah');
  String get hijriMonthDhuAlHijjah => _t('hijriMonthDhuAlHijjah');
}

// ---------------------------------------------------------------------------
// Delegate
// ---------------------------------------------------------------------------

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
