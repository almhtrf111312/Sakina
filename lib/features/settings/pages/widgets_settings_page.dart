import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WidgetsSettingsPage extends StatefulWidget {
  const WidgetsSettingsPage({super.key});

  @override
  State<WidgetsSettingsPage> createState() => _WidgetsSettingsPageState();
}

class _WidgetsSettingsPageState extends State<WidgetsSettingsPage> {
  static const _channel = MethodChannel('com.sakina.app/alarm');
  late final _catalogue = _channel.invokeListMethod<Map<Object?, Object?>>(
    'widgetCatalogue',
  );

  Future<void> _pin(String id) async {
    bool requested;
    try {
      requested = await _channel.invokeMethod<bool>('pinWidget', {'id': id}) ?? false;
    } on PlatformException {
      requested = false;
    }
    if (mounted && !requested) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('أضف الودجت من قائمة الأدوات في الشاشة الرئيسية.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ودجت الشاشة الرئيسية')),
        body: FutureBuilder(
          future: _catalogue,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data;
            if (items == null || items.isEmpty) {
              return const Center(child: Text('تعذّر عرض الودجت.'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (items.first['canPin'] != true)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'الإضافة المباشرة غير متاحة. يمكنك الإضافة من قائمة الأدوات في الشاشة الرئيسية.',
                    ),
                  ),
                for (final item in items)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.memory(
                            item['preview'] as Uint8List,
                            height: 140,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                        ListTile(
                          title: Text(item['title'] as String),
                          trailing: item['canPin'] == true
                              ? OutlinedButton(
                                  onPressed: () => _pin(item['id'] as String),
                                  child: const Text('إضافة'),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      );
}
