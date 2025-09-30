// models/pairing_response_model.dart
import 'device_model.dart';

class PairingResponseModel {
  final bool success;
  final String message;
  final DeviceModel? device;

  PairingResponseModel({
    required this.success,
    required this.message,
    this.device,
  });

  factory PairingResponseModel.fromJson(Map<String, dynamic> json) {
    return PairingResponseModel(
      success: json['success'],
      message: json['message'],
      device: json['data'] != null ? DeviceModel.fromJson(json['data']) : null,
    );
  }
}
