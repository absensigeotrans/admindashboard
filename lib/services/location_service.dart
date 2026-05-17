import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'notification_service.dart';

class LocationService extends ChangeNotifier {
  bool _isTracking = false;
  double _currentDistance = 0.0;
  bool _isInRadius = false;
  bool _isMocked = false;
  bool _wasMocked = false;
  bool _permissionDenied = false;
  bg.Location? _currentLocation;

  bool get isTracking => _isTracking;
  double get currentDistance => _currentDistance;
  bool get isInRadius => _isInRadius;
  bool get isMocked => _isMocked;
  bool get permissionDenied => _permissionDenied;
  bg.Location? get currentLocation => _currentLocation;

  LocationService() {
    _checkPermission();
    _initBackgroundGeolocation();
  }

  Future<void> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _permissionDenied = true;
      notifyListeners();
    }
  }

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _permissionDenied = false;
      notifyListeners();
      return true;
    }
    _permissionDenied = true;
    notifyListeners();
    return false;
  }

  void _initBackgroundGeolocation() {
    // Configure background geolocation
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      _currentLocation = location;
      _isMocked = location.mock ?? false;
      
      if (_isMocked && !_wasMocked) {
        NotificationService().showMockLocationAlert();
      }
      _wasMocked = _isMocked;

      notifyListeners();
      debugPrint('[location] - $location');
    });

    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      debugPrint('[motionchange] - $location');
    });

    bg.BackgroundGeolocation.onHeartbeat((bg.HeartbeatEvent event) {
      debugPrint('[heartbeat] - $event');
      // Logic for heartbeat ping to server can be added here
    });

    bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 10.0,
      stopOnTerminate: false,
      startOnBoot: true,
      debug: false,
      logLevel: bg.Config.LOG_LEVEL_OFF,
      heartbeatInterval: 300, // 5 minutes heartbeat
      notification: bg.Notification(
        title: "GeoAttend PTK Aktif",
        text: "Pelacakan lokasi sedang berjalan untuk absensi.",
      )
    )).then((bg.State state) {
      _isTracking = state.enabled;
      notifyListeners();
    });
  }

  // Haversine Formula for Distance Calculation
  double calculateDistance(double startLat, double startLon, double endLat, double endLon) {
    const p = 0.017453292519943295;
    const c = math.cos;
    final a = 0.5 - c((endLat - startLat) * p) / 2 +
        c(startLat * p) * c(endLat * p) *
            (1 - c((endLon - startLon) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)) * 1000; // Returns meters
  }

  Future<void> updateDistance(double officeLat, double officeLon, double radius) async {
    try {
      // Check permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _permissionDenied = true;
        notifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      _permissionDenied = false;

      // Enhanced mock detection
      _isMocked = _detectMockLocation(position);
      if (_isMocked && !_wasMocked) {
        NotificationService().showMockLocationAlert();
      }
      _wasMocked = _isMocked;

      _currentDistance = calculateDistance(
        position.latitude,
        position.longitude,
        officeLat,
        officeLon
      );

      _isInRadius = _currentDistance <= radius;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating distance: $e');
      // Check if it's a permission error
      if (e.toString().contains('permission')) {
        _permissionDenied = true;
        notifyListeners();
      }
    }
  }

  // Enhanced mock location detection
  bool _detectMockLocation(Position position) {
    // Check native isMocked flag
    if (position.isMocked) return true;

    // Check for suspiciously perfect accuracy (common in fake GPS apps)
    if (position.accuracy != null && position.accuracy! < 1.0) {
      // Very high accuracy (< 1 meter) could indicate spoofing
      debugPrint('[LocationService] Suspicious accuracy: ${position.accuracy}');
    }

    // Check if altitude is 0 (common default in mock locations)
    // Only flag if other indicators are present
    // Note: We don't block based on altitude alone as real GPS can also show 0

    return false;
  }

  Future<void> startTracking() async {
    await bg.BackgroundGeolocation.start();
    _isTracking = true;
    notifyListeners();
  }

  Future<void> stopTracking() async {
    await bg.BackgroundGeolocation.stop();
    _isTracking = false;
    notifyListeners();
  }
}
