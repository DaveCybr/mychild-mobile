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
    
    private fun getDeviceId(): String? {
        val prefs: SharedPreferences = applicationContext.getSharedPreferences(
            "FlutterSharedPreferences", 
            Context.MODE_PRIVATE
        )
        return prefs.getString("flutter.device_id", null)
    }

    override fun onCreate() {
        super.onCreate()
        Log.e(TAG, "========================================")
        Log.e(TAG, "SERVICE CREATED")
        Log.e(TAG, "MethodChannel: ${methodChannel != null}")
        Log.e(TAG, "========================================")
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.e(TAG, "========================================")
        Log.e(TAG, "LISTENER CONNECTED")
        Log.e(TAG, "========================================")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.e(TAG, "LISTENER DISCONNECTED")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        Log.e(TAG, "----------------------------------------")
        Log.e(TAG, "NEW NOTIFICATION")
        
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

            // Send to Flutter
            sendToFlutter(packageName, title, text, timestamp)
            
            // Send to server
            sendToServer(packageName, title, text)

        } catch (e: Exception) {
            Log.e(TAG, "ERROR: ${e.message}", e)
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
                Log.e(TAG, "MethodChannel is NULL")
                return
            }Log.e(TAG, "Invoking Flutter method...")
            
            methodChannel?.invokeMethod(
                "onNotificationReceived",
                mapOf(
                    "package" to packageName,
                    "title" to title,
                    "text" to text,
                    "timestamp" to timestamp.toString()
                )
            )
            
            Log.e(TAG, "Flutter method invoked")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send to Flutter", e)
        }
    }

    private fun sendToServer(appName: String, title: String, content: String) {
        scope.launch {
            try {
                val deviceId = getDeviceId()
                if (deviceId == null) {
                    Log.e(TAG, "Device ID not found")
                    return@launch
                }
                
                Log.e(TAG, "Sending to server...")
                
                val json = JSONObject().apply {
                    put("device_id", deviceId)
                    put("app_name", appName)
                    put("title", title)
                    put("content", content)
                }

                Log.e(TAG, "JSON: ${json.toString()}")
                
                val body = json.toString()
                    .toRequestBody("application/json".toMediaType())

                val request = Request.Builder()
                    .url(API_URL)
                    .post(body)
                    .addHeader("Content-Type", "application/json")
                    .addHeader("Accept", "application/json")
                    .build()

                val response = client.newCall(request).execute()
                
                Log.e(TAG, "Response: ${response.code}")
                
                if (response.isSuccessful) {
                    Log.e(TAG, "SUCCESS: Sent to server")
                } else {
                    Log.e(TAG, "FAILED: ${response.code}")
                }
                
                response.close()
                
            } catch (e: Exception) {
                Log.e(TAG, "Server error", e)
            }
        }
    }
}