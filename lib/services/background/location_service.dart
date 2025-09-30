import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
// import 'auth_service.dart';

class LocationService extends ChangeNotifier {
  Position? _current;
  Position? get current => _current;
  StreamSubscription<Position>? _sub;

  Future<void> startTracking(String token, {int intervalSeconds = 30}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _sub = Geolocator.getPositionStream().listen((pos) {
      _current = pos;
      notifyListeners();
      _sendLocationToServer(pos, token);
    });
  }

  Future<void> stopTracking() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _sendLocationToServer(Position pos, String token) async {
    final body = {
      'device_id': 'device_001', // replace with unique id logic
      'latitude': pos.latitude,
      'longitude': pos.longitude,
    };

    try {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/locations'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
    } catch (e) {
      // ignore network errors for now
    }
  }
}
