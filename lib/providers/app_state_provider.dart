import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class AppStateProvider extends ChangeNotifier {
  // Authentication state
  User? _currentUser;
  bool _isAuthenticated = false;

  // App state
  bool _isSetupComplete = false;
  bool _hasAllPermissions = false;
  Family? _family;

  // Service states
  LocationStatus _locationStatus = LocationStatus.stopped;
  bool _notificationListening = false;
  bool _screenMirroring = false;

  // Dashboard data
  ChildDashboard? _dashboard;
  List<Alert> _recentAlerts = [];

  // Loading states
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isSetupComplete => _isSetupComplete;
  bool get hasAllPermissions => _hasAllPermissions;
  Family? get family => _family;
  LocationStatus get locationStatus => _locationStatus;
  bool get notificationListening => _notificationListening;
  bool get screenMirroring => _screenMirroring;
  ChildDashboard? get dashboard => _dashboard;
  List<Alert> get recentAlerts => _recentAlerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool _isLocationTrackingEnabled = false;
  bool _isNotificationListenerEnabled = false;
  bool _isScreenMirroringActive = false;
  String? _lastLocationUpdate;

  // Getters
  bool get isLocationTrackingEnabled => _isLocationTrackingEnabled;
  bool get isNotificationListenerEnabled => _isNotificationListenerEnabled;
  bool get isScreenMirroringActive => _isScreenMirroringActive;
  String? get lastLocationUpdate => _lastLocationUpdate;

  // Authentication methods
  void setUser(User user) {
    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    _family = null;
    _dashboard = null;
    notifyListeners();
  }

  // Setup state methods
  void setSetupComplete(bool complete) {
    _isSetupComplete = complete;
    notifyListeners();
  }

  void setPermissionsGranted(bool granted) {
    _hasAllPermissions = granted;
    notifyListeners();
  }

  void setFamily(Family family) {
    _family = family;
    notifyListeners();
  }

  // Service status updates
  void updateLocationStatus(LocationStatus status) {
    _locationStatus = status;
    notifyListeners();
  }

  void updateNotificationListening(bool listening) {
    _notificationListening = listening;
    notifyListeners();
  }

  void updateScreenMirroring(bool mirroring) {
    _screenMirroring = mirroring;
    notifyListeners();
  }

  // Dashboard updates
  void updateDashboard(ChildDashboard dashboard) {
    _dashboard = dashboard;
    _recentAlerts = dashboard.recentAlerts;
    notifyListeners();
  }

  // Loading and error state
  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _errorMessage = null;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Overall app status for UI indicators
  String get appStatus {
    if (!_isAuthenticated) return 'Not authenticated';
    if (!_hasAllPermissions) return 'Missing permissions';
    if (_family == null) return 'Not connected to family';

    final services = <String>[];
    if (_locationStatus == LocationStatus.active) services.add('Location');
    if (_notificationListening) services.add('Notifications');
    if (_screenMirroring) services.add('Screen sharing');

    if (services.isEmpty) return 'Services stopped';
    return 'Active: ${services.join(', ')}';
  }

  // Connection health indicator
  bool get isHealthy {
    return _isAuthenticated &&
        _hasAllPermissions &&
        _family != null &&
        (_locationStatus == LocationStatus.active ||
            _locationStatus == LocationStatus.searching);
  }

  // Location tracking
  void setLocationTrackingEnabled(bool enabled) {
    _isLocationTrackingEnabled = enabled;
    notifyListeners();
  }

  void updateLastLocation(String locationInfo) {
    _lastLocationUpdate = locationInfo;
    notifyListeners();
  }

  // Notification listener
  void setNotificationListenerEnabled(bool enabled) {
    _isNotificationListenerEnabled = enabled;
    notifyListeners();
  }

  // Screen mirroring
  void setScreenMirroringActive(bool active) {
    _isScreenMirroringActive = active;
    notifyListeners();
  }
}
