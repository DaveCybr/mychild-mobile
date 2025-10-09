package com.example.couple_guard_child.services.background

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit
import android.content.SharedPreferences
import android.content.Context
import android.os.Handler
import android.os.Looper

class MyNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "NotifListenerService"
        private const val API_URL = "https://parentalcontrol.satelliteorbit.cloud/api/device/notifications"
        
        // Static reference untuk MethodChannel dari MainActivity
        var methodChannel: MethodChannel? = null
    }

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()
        
    private val scope = CoroutineScope(Dispatchers.IO)
    private val mainHandler = Handler(Looper.getMainLooper())
    
    // Cache device ID untuk performa
    private var cachedDeviceId: String? = null
    
    /**
     * Get Device ID dari SharedPreferences
     * RENAMED: getStoredDeviceId() to avoid conflict with superclass
     */
    private fun getStoredDeviceId(): String? {
        // Return cached jika sudah ada
        if (cachedDeviceId != null && cachedDeviceId!!.isNotEmpty()) {
            return cachedDeviceId
        }
        
        return try {
            val prefs: SharedPreferences = applicationContext.getSharedPreferences(
                "FlutterSharedPreferences", 
                Context.MODE_PRIVATE
            )
            
            // ✅ FIX: Gunakan device_id yang di-pair (bukan Android ID)
            cachedDeviceId = prefs.getString("flutter.device_id", null)
            
            if (cachedDeviceId.isNullOrEmpty()) {
                Log.e(TAG, "❌ Device ID NOT FOUND in SharedPreferences!")
                Log.e(TAG, "Available keys: ${prefs.all.keys}")
                
                // ❌ JANGAN GUNAKAN Android ID sebagai fallback!
                // Notification akan gagal 422 jika device tidak paired
                Log.e(TAG, "❌ Device not paired - cannot send notifications")
                cachedDeviceId = null
            } else {
                Log.d(TAG, "✅ Device ID from SharedPreferences: $cachedDeviceId")
            }
            
            cachedDeviceId
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error getting device ID", e)
            null
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "========================================")
        Log.d(TAG, "SERVICE CREATED")
        
        // Pre-load device ID
        val deviceId = getStoredDeviceId()
        Log.d(TAG, "Device ID: $deviceId")
        Log.d(TAG, "Device ID status: ${if (deviceId.isNullOrEmpty()) "EMPTY/NULL" else "OK"}")
        Log.d(TAG, "MethodChannel status: ${if (methodChannel != null) "CONNECTED" else "NULL"}")
        Log.d(TAG, "========================================")
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "========================================")
        Log.d(TAG, "LISTENER CONNECTED")
        
        val deviceId = getStoredDeviceId()
        Log.d(TAG, "Device ID on connect: $deviceId")
        
        if (deviceId.isNullOrEmpty()) {
            Log.e(TAG, "⚠️ WARNING: Device ID is NULL/EMPTY")
            Log.e(TAG, "⚠️ Notifications will NOT be sent to server!")
        } else {
            Log.d(TAG, "✅ Ready to monitor notifications")
        }
        
        Log.d(TAG, "========================================")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.w(TAG, "⚠️ LISTENER DISCONNECTED")
        // Clear cache
        cachedDeviceId = null
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        Log.d(TAG, "----------------------------------------")
        Log.d(TAG, "📱 NEW NOTIFICATION RECEIVED")
        
        try {
            val packageName = sbn.packageName
            Log.d(TAG, "Package: $packageName")
            
            // Skip own notifications
            if (packageName == applicationContext.packageName) {
                Log.d(TAG, "⏭️ Skipping own notification")
                return
            }
            
            val notification = sbn.notification
            val extras = notification.extras

            val title = extras.getCharSequence("android.title")?.toString() ?: ""
            val text = extras.getCharSequence("android.text")?.toString() ?: ""
            val timestamp = sbn.postTime

            Log.d(TAG, "Title: $title")
            Log.d(TAG, "Text: ${text.take(50)}${if (text.length > 50) "..." else ""}")
            Log.d(TAG, "Timestamp: $timestamp")

            // PRIORITY 1: Send to server (most reliable)
            sendToServer(packageName, title, text)
            
            // PRIORITY 2: Send to Flutter UI (optional, may fail if app closed)
            sendToFlutter(packageName, title, text, timestamp)

        } catch (e: Exception) {
            Log.e(TAG, "❌ ERROR processing notification", e)
        }
        
        Log.d(TAG, "----------------------------------------")
    }

    /**
     * Send notification data to Flutter via MethodChannel
     */
    private fun sendToFlutter(
        packageName: String,
        title: String,
        text: String,
        timestamp: Long
    ) {
        try {
            if (methodChannel == null) {
                Log.w(TAG, "⚠️ MethodChannel is NULL - Flutter UI not available")
                return
            }
            
            // Post to main thread (required for MethodChannel)
            mainHandler.post {
                try {
                    methodChannel?.invokeMethod(
                        "onNotificationReceived",
                        mapOf(
                            "package" to packageName,
                            "title" to title,
                            "text" to text,
                            "timestamp" to timestamp.toString()
                        )
                    )
                    
                    Log.d(TAG, "✅ Sent to Flutter UI")
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Failed to invoke Flutter method", e)
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to send to Flutter", e)
        }
    }

    /**
     * Send notification to server API
     */
    private fun sendToServer(appName: String, title: String, content: String) {
        scope.launch {
            try {
                Log.d(TAG, "=== SENDING TO SERVER ===")
                
                val deviceId = getStoredDeviceId()
                if (deviceId.isNullOrEmpty()) {
                    Log.e(TAG, "❌ CRITICAL: Device ID is NULL/EMPTY")
                    Log.e(TAG, "❌ Cannot send without Device ID")
                    return@launch
                }
                
                Log.d(TAG, "Device ID: $deviceId")
                Log.d(TAG, "App: $appName")
                Log.d(TAG, "Title: $title")
                Log.d(TAG, "Content: ${content.take(50)}${if (content.length > 50) "..." else ""}")
                
                val json = JSONObject().apply {
                    put("device_id", deviceId)
                    put("app_name", appName)
                    put("title", title)
                    put("content", content)
                    put("timestamp", System.currentTimeMillis())
                }

                val jsonString = json.toString()
                Log.d(TAG, "JSON Payload: $jsonString")
                
                val body = jsonString.toRequestBody("application/json".toMediaType())

                val request = Request.Builder()
                    .url(API_URL)
                    .post(body)
                    .addHeader("Content-Type", "application/json")
                    .addHeader("Accept", "application/json")
                    .build()

                Log.d(TAG, "Executing HTTP POST to: $API_URL")
                
                val response = client.newCall(request).execute()
                val responseBody = response.body?.string()
                
                Log.d(TAG, "=== SERVER RESPONSE ===")
                Log.d(TAG, "Status: ${response.code}")
                Log.d(TAG, "Body: $responseBody")
                
                if (response.isSuccessful) {
                    Log.d(TAG, "✅ SUCCESS: Notification sent to server")
                } else {
                    Log.e(TAG, "❌ FAILED: ${response.code} - $responseBody")
                }
                
                response.close()
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ EXCEPTION sending to server", e)
                Log.e(TAG, "Exception: ${e.javaClass.name}: ${e.message}")
                e.printStackTrace()
            }
        }
    }
}