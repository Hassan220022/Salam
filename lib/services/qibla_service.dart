import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblaService {
  // Mecca coordinates
  static const double meccaLatitude = 21.4225;
  static const double meccaLongitude = 39.8262;

  /// Calculate Qibla direction from current location
  static Future<double> calculateQiblaDirection() async {
    try {
      final position = await _getCurrentPosition();
      return _calculateBearing(
        position.latitude,
        position.longitude,
        meccaLatitude,
        meccaLongitude,
      );
    } catch (e) {
      throw Exception('Failed to calculate Qibla direction: $e');
    }
  }

  /// Get current position with permission handling
  static Future<Position> _getCurrentPosition() async {
    // Check and request location permissions
    await _requestLocationPermissions();

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Request necessary permissions
  static Future<void> _requestLocationPermissions() async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }

    if (await Permission.location.isPermanentlyDenied) {
      throw Exception('Location permission permanently denied');
    }
  }

  /// Calculate bearing between two coordinates
  static double _calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    double lat1Rad = _toRadians(startLat);
    double lat2Rad = _toRadians(endLat);
    double deltaLngRad = _toRadians(endLng - startLng);

    double x = math.sin(deltaLngRad) * math.cos(lat2Rad);
    double y = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLngRad);

    double bearing = math.atan2(x, y);
    return _normalizeBearing(_toDegrees(bearing));
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Convert radians to degrees
  static double _toDegrees(double radians) {
    return radians * (180.0 / math.pi);
  }

  /// Normalize bearing to 0-360 degrees
  static double _normalizeBearing(double bearing) {
    return (bearing + 360) % 360;
  }

  /// Get compass stream for real-time direction
  static Stream<CompassEvent>? getCompassStream() {
    return FlutterCompass.events;
  }

  /// Check if device has compass/magnetometer
  static Future<bool> hasCompass() async {
    try {
      final events = FlutterCompass.events;
      if (events == null) return false;

      // Try to get a compass reading
      final compassEvent = await events.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Compass timeout'),
      );

      return compassEvent.heading != null;
    } catch (e) {
      return false;
    }
  }

  /// Calculate distance to Mecca
  static Future<double> calculateDistanceToMecca() async {
    try {
      final position = await _getCurrentPosition();
      return Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        meccaLatitude,
        meccaLongitude,
      );
    } catch (e) {
      throw Exception('Failed to calculate distance to Mecca: $e');
    }
  }

  /// Get formatted distance string
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else if (distanceInMeters < 1000000) {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${(distanceInMeters / 1000000).toStringAsFixed(1)} Mm';
    }
  }

  /// Get compass calibration instructions
  static String getCalibrationInstructions() {
    return '''
To improve compass accuracy:

1. Move away from magnetic interference:
   • Electronic devices
   • Metal objects
   • Wi-Fi routers

2. Calibrate your compass:
   • Hold your device flat
   • Rotate it in a figure-8 motion
   • Repeat 3-4 times

3. For best results:
   • Use outdoors when possible
   • Keep device level
   • Avoid magnetic cases
''';
  }
}

/// Qibla direction provider for state management
class QiblaProvider extends ChangeNotifier {
  double? _qiblaDirection;
  double? _deviceHeading;
  bool _isLoading = false;
  String? _error;
  double? _distanceToMecca;

  double? get qiblaDirection => _qiblaDirection;
  double? get deviceHeading => _deviceHeading;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double? get distanceToMecca => _distanceToMecca;

  /// Get relative Qibla direction (accounting for device orientation)
  double? get relativeQiblaDirection {
    if (_qiblaDirection == null || _deviceHeading == null) return null;
    return (_qiblaDirection! - _deviceHeading! + 360) % 360;
  }

  /// Initialize Qibla calculation
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Calculate Qibla direction
      _qiblaDirection = await QiblaService.calculateQiblaDirection();

      // Calculate distance to Mecca
      _distanceToMecca = await QiblaService.calculateDistanceToMecca();

      // Start listening to compass
      _startCompassListening();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startCompassListening() {
    final compassStream = QiblaService.getCompassStream();
    if (compassStream != null) {
      compassStream.listen((CompassEvent event) {
        _deviceHeading = event.heading;
        notifyListeners();
      });
    }
  }

  /// Refresh Qibla calculation
  Future<void> refresh() async {
    await initialize();
  }
}
