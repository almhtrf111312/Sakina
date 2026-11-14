import 'dart:math' as math;
import '../constants/app_constants.dart';

/// Accurate spherical trigonometry & Great Circle navigation utilities
/// to compute the Qibla bearing and distance to the Holy Kaaba in Makkah.
class QiblaCalculator {
  QiblaCalculator._();

  // Holy Kaaba Coordinates
  static const double kaabaLat = AppConstants.meccaLatitude;
  static const double kaabaLng = AppConstants.meccaLongitude;
  static const double earthRadiusKm = AppConstants.earthRadiusKm;

  // ---------------------------------------------------------------------------
  // Great Circle Qibla Bearing (Forward Azimuth)
  // ---------------------------------------------------------------------------

  /// Calculates the initial bearing (forward azimuth) from the user's geographic
  /// coordinates [latitude], [longitude] to the Holy Kaaba in Mecca.
  ///
  /// Returns bearing in degrees normalized to [0.0, 360.0), where:
  ///   0° = North, 90° = East, 180° = South, 270° = West.
  static double calculateQiblaBearing(double latitude, double longitude) {
    final phi1 = _degreesToRadians(latitude);
    final phi2 = _degreesToRadians(kaabaLat);
    final deltaLambda = _degreesToRadians(kaabaLng - longitude);

    final y = math.sin(deltaLambda);
    final x = math.cos(phi1) * math.tan(phi2) -
        math.sin(phi1) * math.cos(deltaLambda);

    final initialBearingRad = math.atan2(y, x);
    final bearingDeg = _radiansToDegrees(initialBearingRad);

    return (bearingDeg + 360.0) % 360.0;
  }

  // ---------------------------------------------------------------------------
  // Haversine Distance to Mecca
  // ---------------------------------------------------------------------------

  /// Calculates the great-circle distance between the user's location and
  /// the Kaaba in kilometers using the Haversine formula.
  static double calculateDistanceToKaabaKm(double latitude, double longitude) {
    final phi1 = _degreesToRadians(latitude);
    final phi2 = _degreesToRadians(kaabaLat);
    final deltaPhi = _degreesToRadians(kaabaLat - latitude);
    final deltaLambda = _degreesToRadians(kaabaLng - longitude);

    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2) *
            math.sin(deltaLambda / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  // ---------------------------------------------------------------------------
  // Compass Alignment Helpers
  // ---------------------------------------------------------------------------

  /// Calculates the relative angle needed to rotate the phone to face the Qibla.
  /// [deviceHeading] is the compass heading of the top of the phone (0-360° from True North).
  /// [qiblaBearing] is the calculated Qibla direction from user coordinates.
  ///
  /// Returns offset in degrees [-180, 180]:
  ///   Negative = rotate left (counter-clockwise)
  ///   Positive = rotate right (clockwise)
  ///   ~0 = directly facing Qibla
  static double getRelativeAngle(double deviceHeading, double qiblaBearing) {
    double diff = (qiblaBearing - deviceHeading) % 360.0;
    if (diff > 180.0) {
      diff -= 360.0;
    } else if (diff < -180.0) {
      diff += 360.0;
    }
    return diff;
  }

  /// Determines if the device is pointing towards the Qibla within [threshold] degrees.
  /// Default threshold is 4.0 degrees.
  static bool isFacingQibla(
    double deviceHeading,
    double qiblaBearing, {
    double threshold = AppConstants.qiblaFacingThresholdDegrees,
  }) {
    final diff = getRelativeAngle(deviceHeading, qiblaBearing).abs();
    return diff <= threshold;
  }

  /// Low-pass filter to smooth jittery compass heading readings.
  /// [currentHeading] is the new raw compass reading.
  /// [previousHeading] is the filtered previous heading.
  /// [alpha] is the smoothing factor (0.0 to 1.0; e.g. 0.15).
  static double smoothHeading(
    double currentHeading,
    double previousHeading, {
    double alpha = AppConstants.compassLowPassAlpha,
  }) {
    // Handle wrap-around at 0/360 degrees
    double diff = currentHeading - previousHeading;
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    double smoothed = (previousHeading + alpha * diff) % 360.0;
    if (smoothed < 0) smoothed += 360.0;
    return smoothed;
  }

  // ---------------------------------------------------------------------------
  // Math Helpers
  // ---------------------------------------------------------------------------

  static double _degreesToRadians(double degrees) => degrees * (math.pi / 180.0);

  static double _radiansToDegrees(double radians) => radians * (180.0 / math.pi);
}
