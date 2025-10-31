package com.example.couple_guard_child.fcm

import android.content.Context
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import android.os.Looper
import com.google.android.gms.location.*
import com.example.couple_guard_child.utils.ApiClient
import kotlinx.coroutines.tasks.await

class MyFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "MyFCMService"
    }

    private val scope = CoroutineScope(Dispatchers.IO)
    private lateinit var fusedLocationClient: FusedLocationProviderClient

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        Log.d(TAG, "✅ FCM Service created")
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d(TAG, "========================================")
        Log.d(TAG, "📨 FCM MESSAGE RECEIVED")
        Log.d(TAG, "From: ${remoteMessage.from}")
        Log.d(TAG, "Data: ${remoteMessage.data}")
        Log.d(TAG, "========================================")

        if (remoteMessage.data.isNotEmpty()) {
            handleCommand(remoteMessage.data)
        }
    }

    private fun handleCommand(data: Map<String, String>) {
        val commandType = data["type"] ?: return

        Log.d(TAG, "🎯 Processing command: $commandType")

        // Check if paired
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
                Log.d(TAG, "📸 Command: Capture Photo")
                Log.d(TAG, "⚠️ Photo capture requires UI - notify Flutter if app is open")
                // TODO: Implement camera capture or notify Flutter
            }
            "REQUEST_NOTIFICATION" -> {
                Log.d(TAG, "� Command: Request Notification")
                Log.d(TAG, "⚠️ Notification requires UI - notify Flutter if app is open")
                // TODO: Implement notification or notify Flutter
            }
            "START_MONITORING" -> {
                Log.d(TAG, "▶️ Monitoring already active")
            }
            "STOP_MONITORING" -> {
                Log.d(TAG, "⏹️ Stop monitoring command received")
            }
            else -> {
                Log.d(TAG, "⚠️ Unknown command: $commandType")
            }
        }
    }

    private fun requestLocationUpdate() {
        scope.launch {
            try {
                Log.d(TAG, "Getting current location...")

                // Check permission
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                    if (checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) 
                        != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                        Log.e(TAG, "❌ No location permission")
                        return@launch
                    }
                }

                // Get location
                val location = fusedLocationClient.getCurrentLocation(
                    LocationRequest.PRIORITY_HIGH_ACCURACY,
                    null
                ).await()

                if (location != null) {
                    Log.d(TAG, "✅ Location: ${location.latitude}, ${location.longitude}")
                    
                    // Get battery level
                    val batteryManager = getSystemService(Context.BATTERY_SERVICE) as android.os.BatteryManager
                    val batteryLevel = batteryManager.getIntProperty(
                        android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY
                    )
                    
                    // Send to server
                    val success = ApiClient.sendLocation(
                        applicationContext,
                        location.latitude,
                        location.longitude,
                        batteryLevel
                    )
                    
                    if (success) {
                        Log.d(TAG, "✅ Location sent successfully via FCM command")
                    } else {
                        Log.e(TAG, "❌ Failed to send location")
                    }
                } else {
                    Log.e(TAG, "❌ Location is null")
                }

            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to get location", e)
            }
        }
    }

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