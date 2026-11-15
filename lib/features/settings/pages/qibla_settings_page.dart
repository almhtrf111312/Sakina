import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/settings/settings_repository.dart';
import '../widgets/settings_common.dart';

class QiblaSettingsPage extends ConsumerWidget {
  const QiblaSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return SettingsPageScaffold(
      title: 'بوصلة القبلة',
      children: [
        buildSettingsCard(
          isDark: isDark,
          child: Column(
            children: [
              // Distance unit
              ListTile(
                title: const Text('وحدة قياس المسافة إلى مكة',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                subtitle: Text(
                  settings.distanceInKm
                      ? 'كيلومتر (كم)'
                      : 'ميل (Mile)',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: isDark
                          ? AppColors.nightTextSecondary
                          : AppColors.dayTextSecondary),
                ),
                trailing: DropdownButton<bool>(
                  value: settings.distanceInKm,
                  underline: const SizedBox.shrink(),
                  dropdownColor: isDark
                      ? AppColors.nightElevated
                      : AppColors.daySurface,
                  items: const [
                    DropdownMenuItem(
                        value: true,
                        child: Text('كيلومتر (كم)',
                            style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(
                        value: false,
                        child: Text('ميل (mi)',
                            style: TextStyle(fontFamily: 'Cairo'))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      notifier
                          .update((s) => s.copyWith(distanceInKm: val));
                    }
                  },
                ),
              ),
              settingsDivider(isDark),

              // Vibration on align
              SwitchListTile(
                title: const Text('الاهتزاز عند محاذاة الكعبة المشرفة',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                subtitle: const Text(
                  'إشعار بالاهتزاز اللمسي الدقيق عند الوصول لاتجاه القبلة الصحيح',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                ),
                value: settings.qiblaAlignVibration,
                activeColor: primary,
                onChanged: (v) => notifier
                    .update((s) => s.copyWith(qiblaAlignVibration: v)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
