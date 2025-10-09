import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:couple_guard_child/services/local/local_storage_service.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Inisialisasi FCM dan kirim token ke server
  static Future<void> initializeAndSyncToken() async {
    // Minta izin notifikasi (Android 13+)
    await _messaging.requestPermission(alert: true, sound: true, badge: true);

    // Ambil token
    String? token = await _messaging.getToken();

    if (token != null) {
      print('✅ FCM Token: $token');
      await _sendTokenToServer(token);
    }

    // Dengarkan kalau token berubah
    _messaging.onTokenRefresh.listen((newToken) {
      print('🔄 Token baru: $newToken');
      _sendTokenToServer(newToken);
    });
  }

  /// Kirim token ke server Laravel kamu
  static Future<void> _sendTokenToServer(String token) async {
    // Ambil device_id dari local storage (saat login disimpan di sana)
    String? deviceId = LocalStorageService.getDeviceId() as String?;

    if (deviceId == null) {
      print('⚠️ Gagal kirim token: device_id belum tersimpan');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          'https://parentalcontrol.satelliteorbit.cloud/api/device/update-token',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'device_id': deviceId, 'fcm_token': token}),
      );

      if (response.statusCode == 200) {
        print('✅ Token berhasil dikirim ke server');
      } else {
        print('❌ Gagal kirim token: ${response.body}');
      }
    } catch (e) {
      print('🚫 Error kirim token ke server: $e');
    }
  }
}
