// models/pairing_response_model.dart
import 'device_model.dart';
import 'dart:developer' as developer;

class PairingResponseModel {
  static const String _tag = 'PairingResponseModel';

  final bool success;
  final String message;
  final DeviceModel? device;

  PairingResponseModel({
    required this.success,
    required this.message,
    this.device,
  });

  factory PairingResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      developer.log('Parsing PairingResponseModel from JSON', name: _tag);
      developer.log('JSON keys: ${json.keys.toList()}', name: _tag);
      developer.log('JSON values: $json', name: _tag);

      final success = json['success'] as bool? ?? false;
      final message = json['message'] as String? ?? 'Unknown error';

      developer.log('Success: $success, Message: $message', name: _tag);

      DeviceModel? device;
      if (json['data'] != null) {
        developer.log('Parsing device data...', name: _tag);
        device = DeviceModel.fromJson(json['data'] as Map<String, dynamic>);
        developer.log('Device parsed successfully', name: _tag);
      } else {
        developer.log('No device data in response', name: _tag);
      }

      return PairingResponseModel(
        success: success,
        message: message,
        device: device,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to parse PairingResponseModel',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': device?.toJson()};
  }
}
