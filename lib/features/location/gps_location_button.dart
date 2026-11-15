import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/location/location_service.dart';

/// Shared by first-run setup and the city picker.
class GpsLocationButton extends ConsumerStatefulWidget {
  const GpsLocationButton({super.key, required this.onLocated});
  final VoidCallback onLocated;

  @override
  ConsumerState<GpsLocationButton> createState() => _GpsLocationButtonState();
}

class _GpsLocationButtonState extends ConsumerState<GpsLocationButton> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _locate() async {
    if (_busy) return;
    setState(() { _busy = true; _failed = false; });
    var success = false;
    try {
      success = await ref.read(locationNotifierProvider.notifier)
          .updateGpsLocation();
    } catch (_) {
      success = false;
    }
    if (!mounted) return;
    setState(() { _busy = false; _failed = !success; });
    if (success) widget.onLocated();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton.icon(
        onPressed: _busy ? null : _locate,
        icon: _busy ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.my_location),
        label: Text(_busy ? 'جارٍ تحديد موقعك…' : 'تحديد موقعي عبر GPS'),
      ),
      if (_failed) ...[
        const SizedBox(height: 8),
        const Text('تعذر تحديد موقعك. شغّل الموقع واسمح للتطبيق بالوصول إليه، '
            'ثم أعد المحاولة أو اختر المدينة يدوياً.'),
        Wrap(spacing: 8, children: [
          TextButton(onPressed: () => Geolocator.openLocationSettings(),
              child: const Text('إعدادات الموقع')),
          TextButton(onPressed: () => Geolocator.openAppSettings(),
              child: const Text('أذونات التطبيق')),
        ]),
      ],
    ],
  );
}
