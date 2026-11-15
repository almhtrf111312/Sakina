import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/alarm_bridge.dart';

class AdhanSoundOption {
  final String id;
  final String nameAr;
  final String muadhinAr;
  final String durationText;
  final String descriptionAr;
  final bool fajrOnly;

  const AdhanSoundOption({
    required this.id,
    required this.nameAr,
    required this.muadhinAr,
    required this.durationText,
    required this.descriptionAr,
    this.fajrOnly = false,
  });
}

/// Default sound: the shortest adhan (الأذان الخامس, ~11 s).
const String kDefaultAdhanSound = 'adhan_5';

/// Known sounds. A sound only appears in the picker when its file
/// `assets/audio/<id>.mp3` exists (any extra `adhan_*.mp3` is added too).
const List<AdhanSoundOption> adhanSoundList = [
  AdhanSoundOption(
    id: 'adhan_1',
    nameAr: 'الأذان الأول',
    muadhinAr: '',
    durationText: '٢٢ ثانية',
    descriptionAr: 'الأذان كاملاً.',
  ),
  AdhanSoundOption(
    id: 'adhan_2',
    nameAr: 'الأذان الثاني',
    muadhinAr: '',
    durationText: '٣٠ ثانية',
    descriptionAr: 'الأذان كاملاً.',
  ),
  AdhanSoundOption(
    id: 'adhan_3',
    nameAr: 'الأذان الثالث',
    muadhinAr: '',
    durationText: '١٨ ثانية',
    descriptionAr: 'الأذان كاملاً.',
  ),
  AdhanSoundOption(
    id: 'adhan_4',
    nameAr: 'حي على الصلاة للفجر',
    muadhinAr: '',
    durationText: '١٩ ثانية',
    descriptionAr: 'الأذان كاملاً.',
    fajrOnly: true,
  ),
  AdhanSoundOption(
    id: 'adhan_5',
    nameAr: 'الأذان الخامس (الافتراضي)',
    muadhinAr: 'الأقصر',
    durationText: '١١ ثانية',
    descriptionAr: 'الأذان الأقصر مدة، وهو الصوت الافتراضي.',
  ),
  AdhanSoundOption(id: 'adhan_6', nameAr: 'أذان إضافي ١', muadhinAr: '',
    durationText: '١١ ثانية', descriptionAr: ''),
  AdhanSoundOption(id: 'adhan_7', nameAr: 'أذان إضافي ٢', muadhinAr: '',
    durationText: '١٧ ثانية', descriptionAr: ''),
  AdhanSoundOption(id: 'adhan_8', nameAr: 'أذان إضافي ٣', muadhinAr: '',
    durationText: '٣٠ ثانية', descriptionAr: ''),
  AdhanSoundOption(id: 'adhan_9', nameAr: 'أذان الحرم المدني', muadhinAr: '',
    durationText: '٢٠ ثانية', descriptionAr: ''),
  AdhanSoundOption(id: 'adhan_10', nameAr: 'الله أكبر', muadhinAr: '',
    durationText: '٣٠ ثانية', descriptionAr: ''),
];

/// Display name for a stored sound id.
String adhanSoundName(String id) {
  if (id.startsWith('custom|')) {
    final parts = id.split('|');
    if (parts.length == 3) return Uri.decodeComponent(parts[1]);
  }
  for (final o in adhanSoundList) {
    if (o.id == id) return o.nameAr;
  }
  return id;
}

class SoundSelectorSheet extends StatefulWidget {
  final String selectedSoundId;
  final double initialVolume;
  final bool fajr;

  const SoundSelectorSheet({
    super.key,
    required this.selectedSoundId,
    this.initialVolume = 1.0,
    this.fajr = false,
  });

  static Future<String?> show(
    BuildContext context, {
    required String selectedSoundId,
    double initialVolume = 1.0,
    bool fajr = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SoundSelectorSheet(
        selectedSoundId: selectedSoundId,
        initialVolume: initialVolume,
        fajr: fajr,
      ),
    );
  }

  @override
  State<SoundSelectorSheet> createState() => _SoundSelectorSheetState();
}

class _SoundSelectorSheetState extends State<SoundSelectorSheet> {
  late String _currentSelectedId;
  String? _currentlyPlayingId;
  late double _previewVolume;
  List<AdhanSoundOption> _options = const [];

  @override
  void initState() {
    super.initState();
    _currentSelectedId = widget.selectedSoundId;
    _previewVolume = widget.initialVolume;
    _loadAvailableSounds();
  }

  Future<void> _loadAvailableSounds() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets().toSet();
      final result = <AdhanSoundOption>[];
      final known = <String>{};
      for (final o in adhanSoundList) {
        known.add(o.id);
        if ((widget.fajr || !o.fajrOnly) &&
            assets.contains('assets/audio/${o.id}.mp3')) result.add(o);
      }
      // Any extra adhan_*.mp3 file the user adds shows up automatically.
      for (final a in assets) {
        final m = RegExp(r'^assets/audio/(adhan_[A-Za-z0-9_]+)\.mp3$').firstMatch(a);
        if (m != null && !known.contains(m.group(1))) {
          final id = m.group(1)!;
          final fajrOnly = id.toLowerCase().contains('fajr') || id.contains('الفجر');
          if (!widget.fajr && fajrOnly) continue;
          result.add(AdhanSoundOption(
            id: id,
            nameAr: id.replaceFirst('adhan_', '').replaceAll('_', ' '),
            muadhinAr: 'صوت مضاف',
            durationText: '',
            descriptionAr: '',
            fajrOnly: fajrOnly,
          ));
        }
      }
      if (result.isEmpty) result.addAll(adhanSoundList.take(1));
      if (_currentSelectedId.startsWith('custom|')) result.insert(0,
        AdhanSoundOption(id: _currentSelectedId,
          nameAr: adhanSoundName(_currentSelectedId), muadhinAr: 'من الجهاز',
          durationText: '', descriptionAr: 'نغمة شخصية'));
      if (mounted) setState(() => _options = result);
    } catch (_) {
      if (mounted) setState(() => _options = adhanSoundList.take(1).toList());
    }
  }

  @override
  void dispose() {
    // Stop any audio testing when sheet closes
    AlarmBridge.stopTestAdhan();
    super.dispose();
  }

  Future<void> _togglePlayback(String soundId) async {
    if (_currentlyPlayingId == soundId) {
      await AlarmBridge.stopTestAdhan();
      setState(() => _currentlyPlayingId = null);
    } else {
      await AlarmBridge.stopTestAdhan();
      setState(() => _currentlyPlayingId = soundId);
      try {
        await AlarmBridge.testAdhan(soundId: soundId, volume: _previewVolume);
      } catch (e) {
        if (mounted) {
          setState(() => _currentlyPlayingId = null);
        }
      }
    }
  }

  Future<void> _pickCustomSound() async {
    try {
      final id = await AlarmBridge.pickCustomSound();
      if (id == null || !mounted) return;
      final name = adhanSoundName(id);
      if (!widget.fajr &&
          (name.toLowerCase().contains('fajr') || name.contains('الفجر'))) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('هذا الصوت مخصص للفجر؛ اختره من صوت أذان الفجر')));
        return;
      }
      setState(() {
        _options = [
          AdhanSoundOption(id: id, nameAr: name,
            muadhinAr: 'من الجهاز', durationText: '', descriptionAr: 'نغمة شخصية'),
          ..._options.where((o) => !o.id.startsWith('custom|')),
        ];
        _currentSelectedId = id;
      });
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تعذر الوصول إلى ملف الصوت. اختر ملفاً من ملفات الجهاز.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.nightSurface : AppColors.daySurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                )
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Handle
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.nightTextSecondary.withOpacity(0.3)
                        : AppColors.dayTextSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 14),

                // Title row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fajr ? 'صوت أذان الفجر' : 'صوت الأذان والتنبيه',
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
                            'استمع للمؤذن واختر الصوت المفضل لديك',
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
                      IconButton(
                        icon: Icon(
                          Icons.check_circle,
                          color: primary,
                          size: 28,
                        ),
                        tooltip: 'تأكيد الاختيار',
                        onPressed: () {
                          Navigator.pop(context, _currentSelectedId);
                        },
                      ),
                    ],
                  ),
                ),

                // Volume slider for preview
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        _previewVolume > 0.5
                            ? Icons.volume_up
                            : (_previewVolume > 0 ? Icons.volume_down : Icons.volume_mute),
                        color: isDark
                            ? AppColors.nightSecondary
                            : AppColors.daySecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'مستوى الصوت:',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: isDark
                              ? AppColors.nightTextSecondary
                              : AppColors.dayTextSecondary,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _previewVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          activeColor: isDark
                              ? AppColors.nightSecondary
                              : AppColors.daySecondary,
                          inactiveColor: isDark
                              ? AppColors.nightElevated
                              : AppColors.dayChipStrong,
                          onChanged: (val) {
                            setState(() => _previewVolume = val);
                            if (_currentlyPlayingId != null) {
                              AlarmBridge.testAdhan(
                                  soundId: _currentlyPlayingId!,
                                  volume: _previewVolume);
                            }
                          },
                        ),
                      ),
                      Text(
                        '${(_previewVolume * 100).toInt()}%',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.nightSecondary
                              : AppColors.daySecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: _pickCustomSound,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('اختيار نغمة من الجهاز'),
                  ),
                ),

                // Sound list
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: _options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _options[index];
                      final isSelected = item.id == _currentSelectedId;
                      final isPlaying = item.id == _currentlyPlayingId;

                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primary.withOpacity(isDark ? 0.16 : 0.12)
                              : (isDark
                                  ? AppColors.nightElevated
                                  : AppColors.dayChip),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? primary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() => _currentSelectedId = item.id);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Play/Stop preview button
                                Material(
                                  color: isPlaying
                                      ? (isDark
                                          ? AppColors.nightSecondary
                                          : AppColors.daySecondary)
                                      : (isDark
                                          ? AppColors.nightChipStrong
                                          : AppColors.dayChipStrong),
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => _togglePlayback(item.id),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(
                                        isPlaying
                                            ? Icons.stop_rounded
                                            : Icons.play_arrow_rounded,
                                        color: isPlaying
                                            ? Colors.black
                                            : (isDark
                                                ? AppColors.nightPrimary
                                                : AppColors.dayPrimary),
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Information
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.nameAr,
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
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.black26
                                                  : AppColors.daySurface,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.durationText,
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 11,
                                                color: isDark
                                                    ? AppColors
                                                        .nightTextSecondary
                                                    : AppColors
                                                        .dayTextSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.muadhinAr,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? AppColors.nightSecondary
                                              : AppColors.daySecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.descriptionAr,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11,
                                          height: 1.3,
                                          color: isDark
                                              ? AppColors.nightTextSecondary
                                              : AppColors.dayTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Radio select button
                                Radio<String>(
                                  value: item.id,
                                  groupValue: _currentSelectedId,
                                  activeColor: primary,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _currentSelectedId = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom apply button
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context, _currentSelectedId);
                      },
                      child: const Text(
                        'اعتماد الصوت المختار',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
