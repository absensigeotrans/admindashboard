import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:geolocator/geolocator.dart';
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
  Position? _lastGpsPosition;

  bool get isTracking => _isTracking;
  double get currentDistance => _currentDistance;
  bool get isInRadius => _isInRadius;
  bool get isMocked => _isMocked;
  bool get permissionDenied => _permissionDenied;
  bg.Location? get currentLocation => _currentLocation;
  Position? get lastGpsPosition => _lastGpsPosition;

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
      // [FIX] location.mock adalah non-nullable bool di versi library ini,
      // tidak perlu null-aware operator ??
      _isMocked = location.mock;
      
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

      // [FIX] Menggunakan locationSettings (API baru) menggantikan
      // desiredAccuracy yang sudah deprecated sejak geolocator v10+
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _permissionDenied = false;

      _lastGpsPosition = position;

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

    // Suspiciously perfect accuracy (< 1 meter) — fake GPS often reports 0.0
    if (position.accuracy < 1.0) {
      debugPrint('[LocationService] Flagged mocked: accuracy=${position.accuracy} (< 1.0)');
      return true;
    }

    if (position.accuracy < 5.0 && position.altitude == 0) {
      debugPrint('[LocationService] Flagged mocked: accuracy=${position.accuracy}, altitude=0');
      return true;
    }

    return false;
  }

  /// Build JSON location data for check-in payload
  Map<String, dynamic>? buildLocationData() {
    final pos = _lastGpsPosition;
    if (pos == null) return null;

    return {
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'accuracy': pos.accuracy,
      'altitude': pos.altitude,
      'speed': pos.speed,
      'speed_accuracy': pos.speedAccuracy,
      'heading': pos.heading,
      'is_mocked': pos.isMocked,
      'timestamp': pos.timestamp.toIso8601String(),
    };
  }

  Future<bool> isServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<bool> isLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    if (_permissionDenied) return false;

    return _currentLocation != null;
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
