package com.example.couple_guard_child.services

import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import com.example.couple_guard_child.utils.ApiClient
import com.google.android.gms.location.*
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class PushService : FirebaseMessagingService() {
    private val TAG = "PushService"
    private lateinit var fusedLocationClient: FusedLocationProviderClient

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        Log.d(TAG, "✅ PushService created")
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "🔑 New FCM token: ${token.substring(0, 20)}...")
        
        // Send token to server
        Thread {
            val success = ApiClient.updateFcmToken(applicationContext, token)
            if (success) {
                Log.d(TAG, "✅ FCM token sent to server")
            } else {
                Log.e(TAG, "❌ Failed to send FCM token")
            }
        }.start()
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        Log.d(TAG, "📨 FCM message received")
        Log.d(TAG, "From: ${remoteMessage.from}")
        Log.d(TAG, "Data: ${remoteMessage.data}")
        
        // Check if message contains data payload
        if (remoteMessage.data.isNotEmpty()) {
            handleDataMessage(remoteMessage.data)
        }
        
        // Check if message contains notification payload
        remoteMessage.notification?.let {
            Log.d(TAG, "Notification Title: ${it.title}")
            Log.d(TAG, "Notification Body: ${it.body}")
        }
    }

    private fun handleDataMessage(data: Map<String, String>) {
        val action = data["type"]
        
        Log.d(TAG, "📋 Action: $action")
        
        when (action) {
            "request_location" -> {
                Log.d(TAG, "📍 Location request received via FCM")
                requestAndSendLocation()
            }
            "ping" -> {
                Log.d(TAG, "🏓 Ping received")
                // Optional: Send pong response
            }
            else -> {
                Log.w(TAG, "⚠️ Unknown action: $action")
            }
        }
    }

    private fun requestAndSendLocation() {
        // Check permission
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            Log.e(TAG, "❌ Location permission not granted")
            return
        }

        try {
            // Try to get last known location first (faster)
            fusedLocationClient.lastLocation.addOnSuccessListener { location: Location? ->
                if (location != null) {
                    Log.d(TAG, "✅ Got last known location")
                    sendLocationToServer(location)
                } else {
                    Log.d(TAG, "⚠️ No last known location, requesting fresh location")
                    requestFreshLocation()
                }
            }.addOnFailureListener { e ->
                Log.e(TAG, "❌ Failed to get last location", e)
                requestFreshLocation()
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception getting location", e)
        }
    }

    private fun requestFreshLocation() {
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            10000L // 10 seconds
        )
            .setWaitForAccurateLocation(false)
            .setMaxUpdateDelayMillis(5000L)
            .setMinUpdateIntervalMillis(5000L)
            .build()

        val locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                super.onLocationResult(locationResult)
                
                val location = locationResult.lastLocation
                if (location != null) {
                    Log.d(TAG, "✅ Got fresh location")
                    sendLocationToServer(location)
                }
                
                // Remove updates after getting one location
                fusedLocationClient.removeLocationUpdates(this)
            }
        }

        try {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
            
            Log.d(TAG, "🔄 Requesting fresh location updates")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception requesting location updates", e)
        }
    }

    private fun sendLocationToServer(location: Location) {
        val latitude = location.latitude
        val longitude = location.longitude
        
        Log.d(TAG, "📍 Sending location: $latitude, $longitude")
        
        // Get battery level
        val batteryLevel = getBatteryLevel()
        
        Thread {
            val success = ApiClient.sendLocation(
                applicationContext,
                latitude,
                longitude,
                batteryLevel
            )
            
            if (success) {
                Log.d(TAG, "✅ Location sent to server successfully")
            } else {
                Log.e(TAG, "❌ Failed to send location to server")
            }
        }.start()
    }

    private fun getBatteryLevel(): Int {
        return try {
            val batteryManager = getSystemService(BATTERY_SERVICE) as android.os.BatteryManager
            batteryManager.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error getting battery level", e)
            -1
        }
    }

    override fun onDeletedMessages() {
        super.onDeletedMessages()
        Log.w(TAG, "⚠️ Messages deleted on server")
    }

    override fun onMessageSent(msgId: String) {
        super.onMessageSent(msgId)
        Log.d(TAG, "✅ Message sent: $msgId")
    }

    override fun onSendError(msgId: String, exception: Exception) {
        super.onSendError(msgId, exception)
        Log.e(TAG, "❌ Send error for $msgId", exception)
    }
}