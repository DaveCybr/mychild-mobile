package com.example.my_child

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class PermissionMethodChannel(private val context: Context, private val activity: Activity?) {
    
    companion object {
        const val CHANNEL = "com.famisafe.child/permissions"
        const val REQUEST_BATTERY_OPTIMIZATION = 1001
        const val REQUEST_DEVICE_ADMIN = 1002
    }
    
    private var methodChannel: MethodChannel? = null
    private val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
    private val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    private val deviceAdminComponent = ComponentName(context, DeviceAdminReceiver::class.java)

    fun setupMethodChannel(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestBatteryOptimization" -> {
                    requestBatteryOptimization(result)
                }
                "isBatteryOptimizationDisabled" -> {
                    result.success(isBatteryOptimizationDisabled())
                }
                "requestDeviceAdmin" -> {
                    requestDeviceAdmin(result)
                }
                "isDeviceAdminActive" -> {
                    result.success(isDeviceAdminActive())
                }
                "openAppSettings" -> {
                    openAppSettings(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestBatteryOptimization(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!powerManager.isIgnoringBatteryOptimizations(context.packageName)) {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:${context.packageName}")
                    }
                    
                    if (activity != null && intent.resolveActivity(context.packageManager) != null) {
                        activity.startActivityForResult(intent, REQUEST_BATTERY_OPTIMIZATION)
                        result.success(true)
                    } else {
                        // Fallback to battery optimization settings
                        val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        if (fallbackIntent.resolveActivity(context.packageManager) != null) {
                            context.startActivity(fallbackIntent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                } else {
                    result.success(true) // Already whitelisted
                }
            } else {
                result.success(true) // Not needed for older versions
            }
        } catch (e: Exception) {
            result.error("BATTERY_OPTIMIZATION_ERROR", e.message, null)
        }
    }

    private fun isBatteryOptimizationDisabled(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            powerManager.isIgnoringBatteryOptimizations(context.packageName)
        } else {
            true
        }
    }

    private fun requestDeviceAdmin(result: MethodChannel.Result) {
        try {
            if (!devicePolicyManager.isAdminActive(deviceAdminComponent)) {
                val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                    putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, deviceAdminComponent)
                    putExtra(
                        DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                        "This app needs device admin permission to protect your child's safety and prevent unauthorized changes."
                    )
                }
                
                if (activity != null) {
                    activity.startActivityForResult(intent, REQUEST_DEVICE_ADMIN)
                    result.success(true)
                } else {
                    result.success(false)
                }
            } else {
                result.success(true) // Already active
            }
        } catch (e: Exception) {
            result.error("DEVICE_ADMIN_ERROR", e.message, null)
        }
    }

    private fun isDeviceAdminActive(): Boolean {
        return devicePolicyManager.isAdminActive(deviceAdminComponent)
    }

    private fun openAppSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
            }
            
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("SETTINGS_ERROR", e.message, null)
        }
    }
}

// android/app/src/main/kotlin/com/example/famisafe_child/LocationMethodChannel.kt
package com.example.famisafe_child

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class LocationMethodChannel(private val context: Context) {
    
    companion object {
        const val CHANNEL = "com.famisafe.child/location"
    }
    
    private var methodChannel: MethodChannel? = null
    private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    fun setupMethodChannel(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startLocationTracking" -> {
                    startLocationTracking(result)
                }
                "stopLocationTracking" -> {
                    stopLocationTracking(result)
                }
                "isLocationServiceEnabled" -> {
                    result.success(isLocationServiceEnabled())
                }
                "hasLocationPermission" -> {
                    result.success(hasLocationPermission())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startLocationTracking(result: MethodChannel.Result) {
        try {
            if (!isLocationServiceEnabled()) {
                result.error("LOCATION_SERVICE_DISABLED", "Location services are disabled", null)
                return
            }
            
            if (!hasLocationPermission()) {
                result.error("LOCATION_PERMISSION_DENIED", "Location permission not granted", null)
                return
            }
            
            // Start foreground service for location tracking
            val serviceIntent = Intent(context, LocationTrackingService::class.java)
            ContextCompat.startForegroundService(context, serviceIntent)
            
            result.success(true)
        } catch (e: Exception) {
            result.error("LOCATION_TRACKING_ERROR", e.message, null)
        }
    }

    private fun stopLocationTracking(result: MethodChannel.Result) {
        try {
            val serviceIntent = Intent(context, LocationTrackingService::class.java)
            context.stopService(serviceIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_LOCATION_ERROR", e.message, null)
        }
    }

    private fun isLocationServiceEnabled(): Boolean {
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED &&
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_BACKGROUND_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
}

// android/app/src/main/kotlin/com/example/famisafe_child/LocationTrackingService.kt
package com.example.famisafe_child

import android.app.*
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import androidx.core.app.NotificationCompat

class LocationTrackingService : Service(), LocationListener {
    
    companion object {
        const val CHANNEL_ID = "LOCATION_TRACKING_CHANNEL"
        const val NOTIFICATION_ID = 1002
        const val MIN_TIME_BETWEEN_UPDATES = 30000L // 30 seconds
        const val MIN_DISTANCE_CHANGE_FOR_UPDATES = 10f // 10 meters
    }
    
    private lateinit var locationManager: LocationManager
    private var lastKnownLocation: Location? = null

    override fun onCreate() {
        super.onCreate()
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, createNotification())
        startLocationUpdates()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        stopLocationUpdates()
    }

    private fun startLocationUpdates() {
        try {
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    MIN_TIME_BETWEEN_UPDATES,
                    MIN_DISTANCE_CHANGE_FOR_UPDATES,
                    this
                )
            }
            
            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    MIN_TIME_BETWEEN_UPDATES,
                    MIN_DISTANCE_CHANGE_FOR_UPDATES,
                    this
                )
            }
        } catch (SecurityException e) {
            // Location permission not granted
            stopSelf()
        }
    }

    private fun stopLocationUpdates() {
        try {
            locationManager.removeUpdates(this)
        } catch (e: Exception) {
            // Ignore errors when stopping
        }
    }

    override fun onLocationChanged(location: Location) {
        lastKnownLocation = location
        
        // Send location update to Flutter
        sendLocationToFlutter(location)
        
        // Update notification with current location
        updateNotification("Location: ${location.latitude}, ${location.longitude}")
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}

    private fun sendLocationToFlutter(location: Location) {
        // This would typically send location data back to Flutter
        // For now, we'll save it to SharedPreferences for Flutter to read
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("flutter.last_location_latitude", location.latitude.toString())
            .putString("flutter.last_location_longitude", location.longitude.toString())
            .putString("flutter.last_location_accuracy", location.accuracy.toString())
            .putLong("flutter.last_location_timestamp", location.time)
            .apply()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Location Tracking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Tracks location for family safety"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Famisafe Location Tracking")
            .setContentText("Tracking location for family safety")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun updateNotification(text: String) {
        val notification = createNotification()
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
}

// Update MainActivity.kt to register method channels
// android/app/src/main/kotlin/com/example/famisafe_child/MainActivity.kt
package com.example.famisafe_child

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.os.Bundle

class MainActivity: FlutterActivity() {
    private lateinit var permissionMethodChannel: PermissionMethodChannel
    private lateinit var locationMethodChannel: LocationMethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Setup method channels
        permissionMethodChannel = PermissionMethodChannel(this, this)
        permissionMethodChannel.setupMethodChannel(flutterEngine)
        
        locationMethodChannel = LocationMethodChannel(this)
        locationMethodChannel.setupMethodChannel(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Start foreground service if permissions are granted
        startForegroundServiceIfNeeded()
    }

    private fun startForegroundServiceIfNeeded() {
        val sharedPrefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val permissionSetupCompleted = sharedPrefs.getBoolean("flutter.permission_setup_completed", false)
        
        if (permissionSetupCompleted) {
            val serviceIntent = android.content.Intent(this, FamilyTrackingService::class.java)
            startForegroundService(serviceIntent)
        }
    }
}