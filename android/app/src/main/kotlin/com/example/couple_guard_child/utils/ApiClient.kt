package com.example.couple_guard_child.utils

import android.content.Context
import android.util.Log
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

object ApiClient {
    private const val TAG = "ApiClient"
    private const val BASE_URL = "https://parentalcontrol.satelliteorbit.cloud/api"

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    /**
     * Get Device ID from SharedPreferences
     */
    fun getDeviceId(context: Context): String? {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )
        return prefs.getString("flutter.device_id", null)
    }

    /**
     * Check if device is paired
     */
    fun isPaired(context: Context): Boolean {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )
        return prefs.getBoolean("flutter.is_paired", false)
    }

    /**
     * Send Location to Server
     */
    fun sendLocation(
        context: Context,
        latitude: Double,
        longitude: Double,
        batteryLevel: Int
    ): Boolean {
        return try {
            val deviceId = getDeviceId(context)
            if (deviceId.isNullOrEmpty()) {
                Log.e(TAG, "❌ No device ID")
                return false
            }

            Log.d(TAG, "Sending location: $latitude, $longitude")

            val json = JSONObject().apply {
                put("device_id", deviceId)
                put("latitude", latitude)
                put("longitude", longitude)
                put("battery_level", batteryLevel)
                put("timestamp", System.currentTimeMillis())
            }

            val body = json.toString().toRequestBody("application/json".toMediaType())

            val request = Request.Builder()
                .url("$BASE_URL/device/locations")
                .post(body)
                .addHeader("Content-Type", "application/json")
                .addHeader("Accept", "application/json")
                .build()

            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()

            Log.d(TAG, "Location API Response: ${response.code}")
            Log.d(TAG, "Body: $responseBody")

            val success = response.isSuccessful
            response.close()

            if (success) {
                Log.d(TAG, "✅ Location sent successfully")
            } else {
                Log.e(TAG, "❌ Location failed: ${response.code}")
            }

            success

        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception sending location", e)
            false
        }
    }

    /**
     * Send Notification to Server
     */
    fun sendNotification(
        context: Context,
        appName: String,
        title: String,
        content: String
    ): Boolean {
        return try {
            val deviceId = getDeviceId(context)
            if (deviceId.isNullOrEmpty()) {
                Log.e(TAG, "❌ No device ID")
                return false
            }

            Log.d(TAG, "Sending notification from: $appName")

            val json = JSONObject().apply {
                put("device_id", deviceId)
                put("app_name", appName)
                put("title", title)
                put("content", content)
                put("timestamp", System.currentTimeMillis())
            }

            val body = json.toString().toRequestBody("application/json".toMediaType())

            val request = Request.Builder()
                .url("$BASE_URL/device/notifications")
                .post(body)
                .addHeader("Content-Type", "application/json")
                .addHeader("Accept", "application/json")
                .build()

            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()

            Log.d(TAG, "Notification API Response: ${response.code}")
            Log.d(TAG, "Body: $responseBody")

            val success = response.isSuccessful
            response.close()

            if (success) {
                Log.d(TAG, "✅ Notification sent successfully")
            } else {
                Log.e(TAG, "❌ Notification failed: ${response.code}")
            }

            success

        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception sending notification", e)
            false
        }
    }

    /**
     * Update FCM Token
     */
    fun updateFcmToken(context: Context, token: String): Boolean {
        return try {
            val deviceId = getDeviceId(context)
            if (deviceId.isNullOrEmpty()) {
                Log.e(TAG, "❌ No device ID")
                return false
            }

            Log.d(TAG, "Updating FCM token")

            val json = JSONObject().apply {
                put("device_id", deviceId)
                put("fcm_token", token)
            }

            val body = json.toString().toRequestBody("application/json".toMediaType())

            val request = Request.Builder()
                .url("$BASE_URL/devices/update-fcm-token")
                .post(body)
                .addHeader("Content-Type", "application/json")
                .addHeader("Accept", "application/json")
                .build()

            val response = client.newCall(request).execute()
            val success = response.isSuccessful
            response.close()

            if (success) {
                Log.d(TAG, "✅ FCM token updated")
            } else {
                Log.e(TAG, "❌ FCM token update failed")
            }

            success

        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception updating FCM token", e)
            false
        }
    }
}