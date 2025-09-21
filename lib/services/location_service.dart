import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class LocationService {
  final ApiService _apiService;
  Timer? _locationTimer;
  Position? _lastKnownPosition;
  bool _isTracking = false;

  LocationService(this._apiService);

  bool get isTracking => _isTracking;

  // ✅ SIMPLIFIED: Basic location permission check
  Future<bool> requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return false;
      }

      print('Location permission granted: $permission');
      return true;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  // ✅ SIMPLIFIED: Start basic location tracking without foreground service
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('Cannot start tracking - no permission');
        return false;
      }

      _isTracking = true;

      // ✅ Simple periodic location updates without background service
      _startSimpleLocationUpdates();

      print('Location tracking started');
      return true;
    } catch (e) {
      print('Failed to start location tracking: $e');
      return false;
    }
  }

  // Stop location tracking
  Future<void> stopTracking() async {
    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;
    print('Location tracking stopped');
  }

  // ✅ SIMPLE: Basic location updates without foreground service
  void _startSimpleLocationUpdates() {
    // Get location immediately
    _getCurrentLocationSimple();

    // Then get location every 5 minutes when app is active
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }
      await _getCurrentLocationSimple();
    });
  }

  // ✅ SIMPLE: Get location without complex configuration
  Future<void> _getCurrentLocationSimple() async {
    try {
      print('Getting current location...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _lastKnownPosition = position;
      await _saveLocationLocally(position);

      print('Location: ${position.latitude}, ${position.longitude}');

      // TODO: Send to server when API is ready
      // await _apiService.updateLocation(...);
    } catch (e) {
      print('Failed to get location: $e');
    }
  }

  // Save location locally
  Future<void> _saveLocationLocally(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_latitude', position.latitude);
      await prefs.setDouble('last_longitude', position.longitude);
      await prefs.setString(
        'last_location_time',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Failed to save location: $e');
    }
  }

  // ✅ SIMPLE: Emergency location without foreground service complications
  Future<Position?> getEmergencyLocation() async {
    try {
      print('Getting emergency location...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 5),
      );

      return position;
    } catch (e) {
      print('Failed to get emergency location: $e');
      return _lastKnownPosition;
    }
  }

  // Get last known location
  Future<Position?> getLastKnownLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_latitude');
      final lon = prefs.getDouble('last_longitude');

      if (lat != null && lon != null) {
        return Position(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.now(),
          accuracy: 100,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    } catch (e) {
      print('Failed to get last known location: $e');
    }
    return null;
  }

  // Check if location is available
  Future<bool> isLocationServiceAvailable() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get location status
  LocationStatus getLocationStatus() {
    if (!_isTracking) return LocationStatus.stopped;
    if (_lastKnownPosition == null) return LocationStatus.searching;
    return LocationStatus.active;
  }

  void dispose() {
    _locationTimer?.cancel();
  }
}

enum LocationStatus { stopped, searching, active, stale }
