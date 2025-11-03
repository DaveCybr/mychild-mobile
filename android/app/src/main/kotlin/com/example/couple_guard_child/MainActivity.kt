package com.example.couple_guard_child

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.Bitmap  // ✅ ADD THIS
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.couple_guard_child.services.background.MyNotificationListenerService
import com.example.couple_guard_child.workers.LocationWorkManager
import com.example.couple_guard_child.utils.BatteryOptimizationHelper
import java.io.File  // ✅ ADD THIS
import java.io.FileOutputStream  // ✅ ADD THIS

class MainActivity: FlutterActivity() {
    private val CHANNEL = "notification_listener_channel"
    private val LOCATION_CHANNEL = "location_worker_channel"
    private val TAG = "MainActivity"
    
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
                
                // Background service channel
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
                
                // Geofence alert channel
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
        
        // Notification listener channel
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
                "requestBatteryOptimization" -> {
                    BatteryOptimizationHelper.requestDisableBatteryOptimization(applicationContext)
                    result.success(null)
                }
                "checkBatteryOptimization" -> {
                    val isIgnoring = BatteryOptimizationHelper.isIgnoringBatteryOptimizations(applicationContext)
                    result.success(isIgnoring)
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
                "captureScreen" -> {
                    try {
                        val bitmap = captureScreenshot()  // ✅ Call function
                        val file = saveBitmap(bitmap)
                        Thread {
                            val success = com.example.couple_guard_child.utils.ApiClient.uploadScreenshot(
                                applicationContext,
                                file
                            )
                            if (success) {
                                file.delete()
                            }
                        }.start()
                        
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CAPTURE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Location worker channel
        val locationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LOCATION_CHANNEL
        )
        
        locationChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startPeriodicLocation" -> {
                    Log.d(TAG, "========================================")
                    Log.d(TAG, "📍 START PERIODIC LOCATION REQUEST")
                    
                    // Check battery optimization
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
                        
                        Log.d(TAG, "Battery optimization ignored: $isIgnoring")
                        
                        if (!isIgnoring) {
                            Log.w(TAG, "⚠️ WARNING: Battery optimization NOT disabled!")
                        }
                    }
                    
                    LocationWorkManager.schedulePeriodicLocationUpdates(applicationContext)
                    
                    // Verify scheduling
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
    }
    
    // ✅ FIX: Move functions OUTSIDE setMethodCallHandler
    private fun captureScreenshot(): Bitmap {
        val view = window.decorView.rootView
        view.isDrawingCacheEnabled = true
        val bitmap = Bitmap.createBitmap(view.drawingCache)
        view.isDrawingCacheEnabled = false
        return bitmap
    }
    
    private fun saveBitmap(bitmap: Bitmap): File {
        val file = File(cacheDir, "screenshot_${System.currentTimeMillis()}.jpg")
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
        }
        return file
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = android.provider.Settings.Secure.getString(
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
        val intent = android.content.Intent(android.provider.Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }
}