// lib/services/background/screen_monitor_service.dart - STUB VERSION
// Screen monitoring is NOT SUPPORTED by backend (no screen_sessions table)
// This is a stub to prevent errors in code that references this service

import 'dart:developer' as developer;

class ScreenMonitorService {
  static const String _tag = 'ScreenMonitorService';

  /// Start monitoring (STUB - does nothing)
  static void startMonitoring() {
    developer.log(
      '⚠️ Screen monitoring not implemented (no backend support)',
      name: _tag,
      level: 900,
    );
  }

  /// Stop monitoring (STUB - does nothing)
  static void stopMonitoring() {
    developer.log(
      '⚠️ Screen monitoring not implemented (no backend support)',
      name: _tag,
      level: 900,
    );
  }

  /// Check if monitoring is active (always false)
  static bool get isMonitoring => false;

  /// Check if streaming is active (always false)
  static bool get isStreaming => false;
}
