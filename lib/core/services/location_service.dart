// core/services/location_service.dart
import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

import '../network/api_client.dart';
import '../storage/local_storage.dart';
import '../constants/storage_keys.dart';


abstract class LocationService {
  Future<bool> initialize();
  Future<Position?> getCurrentPosition();
  Future<bool> updateLocationToServer(Position position);
  Stream<Position> getLocationStream();
  Future<bool> startLocationTracking();
  Future<bool> stopLocationTracking();
  Future<bool> isLocationTrackingEnabled();
  Future<LocationSettings> getLocationSettings();
}

class LocationServiceImpl implements LocationService {
  final LocalStorage _localStorage;
  final ApiClient _apiClient;
  
  StreamController<Position>? _locationStreamController;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _locationTimer;
  
  static const MethodChannel _methodChannel = MethodChannel('com.famisafe.child/location');

  LocationServiceImpl(this._localStorage, this._apiClient);

  @override
  Future<bool> initialize() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Position?> getCurrentPosition() async {
    try {
      final bool initialized = await initialize();
      if (!initialized) return null;

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Save last known location
      await _saveLastLocation(position);
      
      return position;
    } catch (e) {
      // Try to get last known position if current fails
      return await Geolocator.getLastKnownPosition();
    }
  }

  @override
  Future<bool> updateLocationToServer(Position position) async {
    try {
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
        'timestamp': position.timestamp.toIso8601String(),
      };

      await _apiClient.updateLocation(locationData);
      
      // Save timestamp of last successful update
      await _localStorage.setString(
        StorageKeys.lastLocationUpdate,
        DateTime.now().toIso8601String(),
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<Position> getLocationStream() {
    _locationStreamController?.close();
    _locationStreamController = StreamController<Position>.broadcast();

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
      timeLimit: const Duration(seconds: 30),
    );

    _locationSubscription?.cancel();
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _locationStreamController?.add(position);
        _saveLastLocation(position);
        
        // Auto-update to server every position change
        updateLocationToServer(position);
      },
      onError: (error) {
        // Handle location stream errors
      },
    );

    return _locationStreamController!.stream;
  }

  @override
  Future<bool> startLocationTracking() async {
    try {
      final bool initialized = await initialize();
      if (!initialized) return false;

      // Enable location tracking flag
      await _localStorage.setBool(StorageKeys.locationTrackingEnabled, true);
      
      // Start location stream
      getLocationStream();
      
      // Start periodic location updates (fallback)
      _startPeriodicLocationUpdates();
      
      // Start native background location tracking
      if (Platform.isAndroid) {
        await _methodChannel.invokeMethod('startLocationTracking');
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> stopLocationTracking() async {
    try {
      // Disable location tracking flag
      await _localStorage.setBool(StorageKeys.locationTrackingEnabled, false);
      
      // Stop location stream
      await _locationSubscription?.cancel();
      _locationStreamController?.close();
      
      // Stop periodic timer
      _locationTimer?.cancel();
      
      // Stop native background location tracking
      if (Platform.isAndroid) {
        await _methodChannel.invokeMethod('stopLocationTracking');
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isLocationTrackingEnabled() async {
    return _localStorage.getBool(StorageKeys.locationTrackingEnabled) ?? false;
  }

  @override
  Future<LocationSettings> getLocationSettings() async {
    // Get device-specific optimal settings
    if (Platform.isIOS) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        timeLimit: Duration(seconds: 30),
      );
    } else {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 30),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Famisafe sedang melacak lokasi untuk keamanan',
          notificationTitle: 'Pelacakan Lokasi Aktif',
          enableWakeLock: true,
        ),
      );
    }
  }

  void _startPeriodicLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) async {
        final position = await getCurrentPosition();
        if (position != null) {
          await updateLocationToServer(position);
        }
      },
    );
  }

  Future<void> _saveLastLocation(Position position) async {
    final locationJson = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'timestamp': position.timestamp.toIso8601String(),
    };
    
    await _localStorage.setString(
      'last_known_location',
      locationJson.toString(),
    );
  }

  void dispose() {
    _locationSubscription?.cancel();
    _locationStreamController?.close();
    _locationTimer?.cancel();
  }
}
