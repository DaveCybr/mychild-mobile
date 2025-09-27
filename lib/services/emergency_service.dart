import 'dart:async';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'location_service.dart';

class EmergencyService {
  final ApiService _apiService;
  final LocationService _locationService;
  static const MethodChannel _channel = MethodChannel('emergency_service');

  EmergencyService(this._apiService, this._locationService);

  // Trigger panic emergency
  Future<void> triggerPanicEmergency({String? message}) async {
    await _triggerEmergency('panic', message);
  }

  // Trigger help emergency
  Future<void> triggerHelpEmergency({String? message}) async {
    await _triggerEmergency('help', message);
  }

  // Trigger medical emergency
  Future<void> triggerMedicalEmergency({String? message}) async {
    await _triggerEmergency('medical', message);
  }

  // Main emergency trigger method
  Future<void> _triggerEmergency(String type, String? message) async {
    try {
      // Immediate feedback
      await _provideTactileFeedback();

      // Get current location
      final position = await _locationService.getEmergencyLocation();

      if (position != null) {
        // Send emergency alert to server
        await _apiService.triggerEmergency(
          latitude: position.latitude,
          longitude: position.longitude,
          emergencyType: type,
          message: message ?? 'Emergency button pressed',
        );

        // Additional emergency actions
        await _performEmergencyActions(type, position);

        print('Emergency alert sent successfully: $type');
      } else {
        throw Exception('Could not get location for emergency');
      }
    } catch (e) {
      print('Failed to trigger emergency: $e');

      // Try to send emergency without location as fallback
      await _sendEmergencyWithoutLocation(type, message);
    }
  }

  // Provide tactile and audio feedback
  Future<void> _provideTactileFeedback() async {
    // Strong vibration pattern
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != null && hasVibrator) {
      await Vibration.vibrate(
        pattern: [0, 500, 200, 500, 200, 500], // SOS pattern
        intensities: [0, 255, 0, 255, 0, 255],
      );
    }

    // Audio feedback through system sound
    await SystemSound.play(SystemSoundType.alert);
  }

  // Perform additional emergency actions
  Future<void> _performEmergencyActions(String type, Position position) async {
    switch (type) {
      case 'panic':
        await _startContinuousLocationTracking();
        await _enableLoudMode();
        break;
      case 'medical':
        await _prepareMedicalInfo();
        break;
      case 'help':
        await _startContinuousLocationTracking();
        break;
    }
  }

  // Start continuous location tracking during emergency
  Future<void> _startContinuousLocationTracking() async {
    // Send location updates every 30 seconds during emergency
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final position = await _locationService.getEmergencyLocation();
        if (position != null) {
          await _apiService.updateLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            batteryLevel: await _getBatteryLevel(),
          );
        }
      } catch (e) {
        print('Emergency location update failed: $e');
      }

      // Stop after 30 minutes
      if (timer.tick >= 60) {
        timer.cancel();
      }
    });
  }

  // Enable loud mode for emergency
  Future<void> _enableLoudMode() async {
    try {
      await _channel.invokeMethod('enableLoudMode');
    } catch (e) {
      print('Failed to enable loud mode: $e');
    }
  }

  // Prepare medical information
  Future<void> _prepareMedicalInfo() async {
    // This could display medical ID or emergency contacts
    try {
      await _channel.invokeMethod('showMedicalInfo');
    } catch (e) {
      print('Failed to show medical info: $e');
    }
  }

  // Send emergency without location as fallback
  Future<void> _sendEmergencyWithoutLocation(
    String type,
    String? message,
  ) async {
    try {
      // Use a default location or last known location
      await _apiService.triggerAlert(
        type: 'emergency',
        priority: 'critical',
        title: 'Emergency - $type',
        message: message ?? 'Emergency triggered without location',
        data: {
          'emergency_type': type,
          'location_unavailable': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to send emergency fallback: $e');
    }
  }

  // Get battery level
  Future<int> _getBatteryLevel() async {
    try {
      final result = await _channel.invokeMethod('getBatteryLevel');
      return result ?? 100;
    } catch (e) {
      return 100;
    }
  }

  // Quick call to emergency contact
  Future<void> callEmergencyContact() async {
    try {
      // This would call the first emergency contact or local emergency number
      const emergencyNumber = 'tel:112'; // European emergency number
      final uri = Uri.parse(emergencyNumber);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('Failed to make emergency call: $e');
    }
  }
}
