import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/compass_widget.dart';

/// Full Qibla compass screen with real-time sensor fusion,
/// distance calculation to Holy Kaaba, accuracy calibration prompts,
/// and haptic alignment feedback.
class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen>
    with TickerProviderStateMixin {
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<dynamic>? _tiltSubscription;
  static const _tiltChannel = EventChannel('com.sakina.app/device_tilt');
  double? _tiltDegrees;

  double _deviceHeading = 0.0;
  double _qiblaBearing = 135.0; // Default calculated bearing
  double _distanceToMeccaKm = 0.0;

  bool _isAligned = false;
  bool _wasAligned = false;
  bool _hasPermissions = false;
  bool _lowAccuracy = false;
  bool _hasSensor = true;

  double? _userLatitude;
  double? _userLongitude;
  String _cityName = 'جاري تحديد الموقع...';

  late final AnimationController _calibController;
  late final AnimationController _headingController;

  @override
  void initState() {
    super.initState();
    _calibController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _headingController = AnimationController.unbounded(vsync: this);
    _tiltSubscription = _tiltChannel.receiveBroadcastStream().listen((angle) {
      if (mounted && angle is num && (_tiltDegrees == null ||
          (angle.toDouble() - _tiltDegrees!).abs() > 3)) {
        setState(() => _tiltDegrees = angle.toDouble());
      }
    }, onError: (_) {});

    _initLocationAndCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _tiltSubscription?.cancel();
    _calibController.dispose();
    _headingController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndCompass() async {
    // 1. Try to load cached location first for instant offline readiness
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final cachedLat = prefs.getDouble(AppConstants.keyLastLatitude);
    final cachedLon = prefs.getDouble(AppConstants.keyLastLongitude);
    final cachedCity = prefs.getString(AppConstants.keyLastCity);

    if (cachedLat != null && cachedLon != null) {
      _updateCoordinates(cachedLat, cachedLon, cachedCity ?? 'موقع محفوظ');
    }

    // 2. Request GPS location if available
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        if (!mounted) return;
        setState(() => _hasPermissions = true);
        // Start the compass right away; the GPS fix can take a while and must
        // not delay (or block) the sensor.
        _startCompassStream();
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        ).catchError((_) => Geolocator.getLastKnownPosition());

        if (!mounted) return;
        if (pos != null) {
          _updateCoordinates(pos.latitude, pos.longitude, 'الموقع الحالي');
          await prefs.setDouble(AppConstants.keyLastLatitude, pos.latitude);
          await prefs.setDouble(AppConstants.keyLastLongitude, pos.longitude);
        }
      } else {
        // Fallback default coordinates (e.g. Cairo or Riyadh if no permission)
        if (_userLatitude == null) {
          _updateCoordinates(24.7136, 46.6753, 'الرياض (افتراضي)');
        }
      }
    } catch (_) {
      if (_userLatitude == null) {
        _updateCoordinates(24.7136, 46.6753, 'الرياض (افتراضي)');
      }
    }

    // 3. Start Compass sensor stream (no-op if already started)
    if (mounted) _startCompassStream();
  }

  void _updateCoordinates(double lat, double lon, String city) {
    if (!mounted) return;
    setState(() {
      _userLatitude = lat;
      _userLongitude = lon;
      _cityName = city;
      _qiblaBearing = _calculateQiblaBearing(lat, lon);
      _distanceToMeccaKm = _calculateDistanceToMecca(lat, lon);
    });
  }

  int _lastUiMs = 0;

  void _startCompassStream() {
    if (_compassSubscription != null) return;
    final stream = FlutterCompass.events;
    if (stream == null) {
      setState(() => _hasSensor = false);
      return;
    }

    _compassSubscription = stream.listen((event) {
      if (!mounted) return;

      // The sensor can fire far faster than the screen can use; rebuilding
      // the whole page on every event stalled the UI thread. ~20 updates/s.
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - _lastUiMs < 50) return;

      final heading = event.heading;
      if (heading == null) {
        if (_hasSensor) setState(() => _hasSensor = false);
        return;
      }
      _lastUiMs = nowMs;

      final accuracy = event.accuracy;
      final isLowAcc = accuracy != null && accuracy > 25.0;

      // Low-pass filter on the circular heading to remove jitter.
      final raw = (heading + 360) % 360;
      final delta = ((raw - _deviceHeading + 540) % 360) - 180;
      final normalizedHeading =
          delta.abs() > 90 ? raw : (_deviceHeading + delta * 0.35 + 360) % 360;
      // Animate the shortest arc across 0° without forcing 60 page rebuilds/s.
      final animatedHeading = _headingController.value;
      final animatedDelta = ((normalizedHeading - animatedHeading + 540) % 360) - 180;
      _headingController.animateTo(animatedHeading + animatedDelta,
          duration: const Duration(milliseconds: 110), curve: Curves.easeOutCubic);

      final diff = ((_qiblaBearing - normalizedHeading + 180) % 360) - 180;
      final aligned = diff.abs() <= AppConstants.qiblaFacingThresholdDegrees;

      if (aligned && !_wasAligned) {
        HapticFeedback.heavyImpact();
      }

      if (isLowAcc && !_calibController.isAnimating) {
        _calibController.repeat();
      } else if (!isLowAcc && _calibController.isAnimating) {
        _calibController.stop();
      }

      // Skip rebuilds when nothing visible changed.
      if ((normalizedHeading - _deviceHeading).abs() < 0.4 &&
          aligned == _isAligned &&
          isLowAcc == _lowAccuracy &&
          _hasSensor) {
        return;
      }

      setState(() {
        _deviceHeading = normalizedHeading;
        _isAligned = aligned;
        _wasAligned = aligned;
        _lowAccuracy = isLowAcc;
        _hasSensor = true;
      });
    }, onError: (_) {
      if (mounted) setState(() => _hasSensor = false);
    });
  }

  /// Great-Circle initial bearing from (lat, lon) to Mecca (21.4225° N, 39.8262° E)
  double _calculateQiblaBearing(double lat, double lon) {
    const meccaLat = AppConstants.meccaLatitude * (math.pi / 180.0);
    const meccaLon = AppConstants.meccaLongitude * (math.pi / 180.0);

    final userLat = lat * (math.pi / 180.0);
    final userLon = lon * (math.pi / 180.0);

    final dLon = meccaLon - userLon;

    final y = math.sin(dLon) * math.cos(meccaLat);
    final x = math.cos(userLat) * math.sin(meccaLat) -
        math.sin(userLat) * math.cos(meccaLat) * math.cos(dLon);

    final initialBearingRad = math.atan2(y, x);
    final initialBearingDeg = initialBearingRad * (180.0 / math.pi);

    return (initialBearingDeg + 360.0) % 360.0;
  }

  /// Haversine distance in kilometers to Mecca
  double _calculateDistanceToMecca(double lat, double lon) {
    const meccaLat = AppConstants.meccaLatitude * (math.pi / 180.0);
    const meccaLon = AppConstants.meccaLongitude * (math.pi / 180.0);

    final userLat = lat * (math.pi / 180.0);
    final userLon = lon * (math.pi / 180.0);

    final dLat = meccaLat - userLat;
    final dLon = meccaLon - userLon;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(userLat) *
            math.cos(meccaLat) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return AppConstants.earthRadiusKm * c;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final relativeDeg = ((_qiblaBearing - _deviceHeading + 180) % 360) - 180;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'اتجاه القبلة الشريفة',
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Location and distance bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: isDark ? AppColors.nightPrimary : AppColors.dayPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _cityName,
                          style: const TextStyle(
                            fontFamily: AppConstants.fontCairo,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          size: 16,
                          color: isDark ? AppColors.nightSecondary : AppColors.daySecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_distanceToMeccaKm.toStringAsFixed(0)} كم لمكة',
                          style: TextStyle(
                            fontFamily: AppConstants.fontCairo,
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Low accuracy or sensor warning banner
            if (!_hasSensor)
              _buildWarningBanner(
                icon: Icons.sensors_off_rounded,
                text: 'جهازك لا يحتوي على مستشعر بوصلة مغناطيسي (Magnetometer)',
                color: Colors.redAccent,
              )
            else if (_lowAccuracy)
              _buildCalibrationGraphic(theme),

            if (_tiltDegrees != null && _tiltDegrees! > 25)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Semantics(
                  label: 'ارفع الهاتف حتى يصبح عمودياً لاستخدام البوصلة بدقة',
                  child: Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.screen_rotation_rounded, color: theme.colorScheme.onPrimaryContainer),
                          const SizedBox(width: 8),
                          Flexible(child: Text('ارفع الهاتف عمودياً ↑  (${_tiltDegrees!.round()}° ميل)',
                            style: TextStyle(fontFamily: AppConstants.fontCairo,
                              color: theme.colorScheme.onPrimaryContainer))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Main Compass View
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _headingController,
                  builder: (context, _) => CompassWidget(
                    heading: _headingController.value,
                    qiblaBearing: _qiblaBearing,
                    isAligned: _isAligned,
                    size: 290.0,
                  ),
                ),
              ),
            ),

            // Status message and bearing degrees
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _isAligned
                      ? AppColors.success.withOpacity(0.15)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isAligned
                        ? AppColors.success
                        : theme.dividerColor.withOpacity(0.1),
                    width: _isAligned ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isAligned
                          ? Icons.check_circle_rounded
                          : Icons.explore_rounded,
                      color: _isAligned
                          ? AppColors.success
                          : (isDark ? AppColors.nightPrimary : AppColors.dayPrimary),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isAligned
                          ? 'أنت تواجه القبلة الآن بدقة'
                          : relativeDeg > 0
                              ? 'أدر هاتفك يميناً بمقدار ${relativeDeg.abs().toStringAsFixed(0)}°'
                              : 'أدر هاتفك يساراً بمقدار ${relativeDeg.abs().toStringAsFixed(0)}°',
                      style: TextStyle(
                        fontFamily: AppConstants.fontCairo,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isAligned
                            ? AppColors.success
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom information bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAngleCard(
                    title: 'زاوية القبلة',
                    value: '${_qiblaBearing.toStringAsFixed(1)}°',
                  ),
                  _buildAngleCard(
                    title: 'اتجاه الهاتف',
                    value: '${_deviceHeading.toStringAsFixed(0)}°',
                  ),
                  _buildAngleCard(
                    title: 'الحالة',
                    value: _isAligned ? 'متطابق' : 'غير متطابق',
                    isHighlight: _isAligned,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppConstants.fontCairo,
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationGraphic(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          RotationTransition(
            turns: _calibController,
            child: const Icon(Icons.all_inclusive_rounded, color: AppColors.warning, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دقة البوصلة منخفضة',
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'حرّك الهاتف على شكل رقم 8 في الهواء لمعايرة الحساس والمغناطيسية',
                  style: TextStyle(
                    fontFamily: AppConstants.fontCairo,
                    fontSize: 10.5,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAngleCard({
    required String title,
    required String value,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontSize: 11,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppConstants.fontCairo,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.success : theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}
