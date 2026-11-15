import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/settings/settings_repository.dart';
import '../widgets/settings_common.dart';

class DataSettingsPage extends ConsumerWidget {
  const DataSettingsPage({super.key});

  void _showImportJsonDialog(
      BuildContext context, SettingsNotifier notifier) {
    final textController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor:
              isDark ? AppColors.nightSurface : AppColors.daySurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('استعادة الإعدادات',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'الصق نص الـ JSON الخاص بالإعدادات السابقة هنا:',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '{"calculationMethod": "ummAlQura", ...}',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.nightElevated
                      : AppColors.dayChip,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              onPressed: () async {
                final text = textController.text.trim();
                if (text.isNotEmpty) {
                  try {
                    await notifier.importJson(text);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم استعادة الإعدادات بنجاح',
                              style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('صيغة الـ JSON غير صالحة',
                              style: TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('استعادة',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsNotifier notifier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor:
              isDark ? AppColors.nightSurface : AppColors.daySurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('تأكيد إعادة التعيين',
                  style: TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من رغبتك في إعادة ضبط جميع الإعدادات إلى قيمها الافتراضية الأصلية؟ لا يمكن التراجع عن هذا الإجراء.',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await notifier.reset();
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمت إعادة تعيين الإعدادات للافتراضية',
                          style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  );
                }
              },
              child: const Text('إعادة التعيين الآن',
                  style: TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return SettingsPageScaffold(
      title: 'البيانات والنسخ الاحتياطي',
      children: [
        buildSettingsCard(
          isDark: isDark,
          child: Column(
            children: [
              // Export JSON
              ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('تصدير الإعدادات (نسخة احتياطية)',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                subtitle: const Text('حفظ الإعدادات كملف نصي JSON',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                onTap: () {
                  final jsonStr = notifier.exportJson();
                  Clipboard.setData(ClipboardData(text: jsonStr));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم نسخ بيانات الإعدادات إلى الحافظة بنجاح',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  );
                },
              ),
              settingsDivider(isDark),

              // Import JSON
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('استعادة الإعدادات من نص JSON',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                subtitle: const Text('لصق إعدادات سابقة واستعادتها',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                onTap: () => _showImportJsonDialog(context, notifier),
              ),
              settingsDivider(isDark),

              // Reset
              ListTile(
                leading: const Icon(Icons.restore, color: AppColors.error),
                title: const Text(
                  'إعادة تعيين الإعدادات للافتراضية',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      color: AppColors.error,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'استعادة جميع قيم الإعدادات إلى وضع المصنع',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                ),
                onTap: () => _showResetDialog(context, notifier),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
