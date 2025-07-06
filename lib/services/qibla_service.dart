import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
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

  /// Get magnetometer stream as fallback
  static Stream<MagnetometerEvent> getMagnetometerStream() {
    return magnetometerEventStream();
  }

  /// Calculate heading from magnetometer data
  static double calculateHeadingFromMagnetometer(double x, double y) {
    double heading = math.atan2(y, x) * 180 / math.pi;
    return _normalizeBearing(heading);
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

  /// Check compass accuracy
  static String getAccuracyDescription(double? accuracy) {
    if (accuracy == null) return 'Unknown';
    
    if (accuracy >= 0 && accuracy <= 15) {
      return 'High';
    } else if (accuracy <= 30) {
      return 'Medium';
    } else if (accuracy <= 45) {
      return 'Low';
    } else {
      return 'Very Low - Calibrate';
    }
  }

  /// Get accuracy color
  static Color getAccuracyColor(double? accuracy) {
    if (accuracy == null) return Colors.grey;
    
    if (accuracy >= 0 && accuracy <= 15) {
      return Colors.green;
    } else if (accuracy <= 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// Trigger haptic feedback when aligned
  static void triggerAlignmentFeedback() {
    HapticFeedback.lightImpact();
  }

  /// Trigger haptic feedback for calibration prompt
  static void triggerCalibrationFeedback() {
    HapticFeedback.mediumImpact();
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
   • Speakers/headphones

2. Calibrate your compass:
   • Hold your device flat
   • Rotate it in a figure-8 motion
   • Repeat 3-4 times in different directions
   • Move to different orientations

3. For best results:
   • Use outdoors when possible
   • Keep device level
   • Avoid magnetic phone cases
   • Stay away from cars and metal structures

4. Signs you need calibration:
   • Erratic needle movement
   • Inconsistent readings
   • Slow response to rotation
''';
  }

  /// Check if calibration is needed based on accuracy
  static bool needsCalibration(double? accuracy) {
    return accuracy == null || accuracy > 30;
  }
}

/// Enhanced Qibla direction provider for state management
class QiblaProvider extends ChangeNotifier {
  double? _qiblaDirection;
  double? _deviceHeading;
  double? _accuracy;
  bool _isLoading = false;
  String? _error;
  double? _distanceToMecca;
  bool _isAligned = false;
  bool _hasTriggeredAlignmentFeedback = false;
  DateTime? _lastCalibrationPrompt;

  double? get qiblaDirection => _qiblaDirection;
  double? get deviceHeading => _deviceHeading;
  double? get accuracy => _accuracy;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double? get distanceToMecca => _distanceToMecca;
  bool get isAligned => _isAligned;

  /// Get relative Qibla direction (accounting for device orientation)
  double? get relativeQiblaDirection {
    if (_qiblaDirection == null || _deviceHeading == null) return null;
    return (_qiblaDirection! - _deviceHeading! + 360) % 360;
  }

  /// Get accuracy description
  String get accuracyDescription => QiblaService.getAccuracyDescription(_accuracy);

  /// Get accuracy color
  Color get accuracyColor => QiblaService.getAccuracyColor(_accuracy);

  /// Check if calibration is needed
  bool get needsCalibration => QiblaService.needsCalibration(_accuracy);

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
        _accuracy = event.accuracy;
        
        // Check alignment
        _checkAlignment();
        
        // Check if calibration prompt is needed
        _checkCalibrationPrompt();
        
        notifyListeners();
      });
    } else {
      // Fallback to magnetometer
      _startMagnetometerListening();
    }
  }

  void _startMagnetometerListening() {
    QiblaService.getMagnetometerStream().listen((MagnetometerEvent event) {
      _deviceHeading = QiblaService.calculateHeadingFromMagnetometer(event.x, event.y);
      _accuracy = null; // Magnetometer doesn't provide accuracy
      
      _checkAlignment();
      notifyListeners();
    });
  }

  void _checkAlignment() {
    final relative = relativeQiblaDirection;
    if (relative == null) return;

    final wasAligned = _isAligned;
    _isAligned = relative >= 350 || relative <= 10;

    // Trigger haptic feedback when first aligned
    if (_isAligned && !wasAligned && !_hasTriggeredAlignmentFeedback) {
      QiblaService.triggerAlignmentFeedback();
      _hasTriggeredAlignmentFeedback = true;
    } else if (!_isAligned) {
      _hasTriggeredAlignmentFeedback = false;
    }
  }

  void _checkCalibrationPrompt() {
    if (needsCalibration) {
      final now = DateTime.now();
      if (_lastCalibrationPrompt == null || 
          now.difference(_lastCalibrationPrompt!).inMinutes > 5) {
        QiblaService.triggerCalibrationFeedback();
        _lastCalibrationPrompt = now;
      }
    }
  }

  /// Refresh Qibla calculation
  Future<void> refresh() async {
    await initialize();
  }

  /// Reset alignment feedback (useful when screen is opened)
  void resetAlignmentFeedback() {
    _hasTriggeredAlignmentFeedback = false;
  }
}
