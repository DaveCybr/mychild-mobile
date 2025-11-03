package com.example.couple_guard_child.utils

import android.content.Context
import android.util.Log
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit
import java.io.File
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody

object ApiClient {
    private const val TAG = "ApiClient"
    private const val BASE_URL = "https://parentalcontrol.satelliteorbit.cloud/api"

    // ✅ FIX 1: Add interceptor for detailed logging
    private val loggingInterceptor = okhttp3.logging.HttpLoggingInterceptor { message ->
        Log.d("OkHttp", message)
    }.apply {
        level = okhttp3.logging.HttpLoggingInterceptor.Level.BODY
    }

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .retryOnConnectionFailure(true) // ✅ FIX 2: Enable auto-retry
        .addInterceptor(loggingInterceptor) // ✅ FIX 3: Add logging
        .addInterceptor { chain ->
            // ✅ FIX 4: Add request timing interceptor
            val request = chain.request()
            val startTime = System.currentTimeMillis()
            
            Log.d(TAG, "→→→ REQUEST START →→→")
            Log.d(TAG, "URL: ${request.url}")
            Log.d(TAG, "Method: ${request.method}")
            Log.d(TAG, "Thread: ${Thread.currentThread().name}")
            
            try {
                val response = chain.proceed(request)
                val duration = System.currentTimeMillis() - startTime
                
                Log.d(TAG, "←←← RESPONSE (${duration}ms) ←←←")
                Log.d(TAG, "Code: ${response.code}")
                Log.d(TAG, "Message: ${response.message}")
                
                response
            } catch (e: Exception) {
                val duration = System.currentTimeMillis() - startTime
                Log.e(TAG, "←←← REQUEST FAILED (${duration}ms) ←←←")
                Log.e(TAG, "Error: ${e.javaClass.simpleName}: ${e.message}")
                throw e
            }
        }
        .build()

    /**
     * Get Device ID from SharedPreferences
     */
    fun getDeviceId(context: Context): String? {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )
        val deviceId = prefs.getString("flutter.device_id", null)
        Log.d(TAG, "Device ID: ${deviceId?.substring(0, 8) ?: "NULL"}...")
        return deviceId
    }

    /**
     * Check if device is paired
     */
    fun isPaired(context: Context): Boolean {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )
        val isPaired = prefs.getBoolean("flutter.is_paired", false)
        Log.d(TAG, "Is Paired: $isPaired")
        return isPaired
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
            Log.d(TAG, "========================================")
            Log.d(TAG, "📍 SENDING LOCATION")
            
            val deviceId = getDeviceId(context)
            if (deviceId.isNullOrEmpty()) {
                Log.e(TAG, "❌ No device ID")
                return false
            }

            Log.d(TAG, "Device ID: ${deviceId.substring(0, 8)}...")
            Log.d(TAG, "Location: $latitude, $longitude")
            Log.d(TAG, "Battery: $batteryLevel%")

            val json = JSONObject().apply {
                put("device_id", deviceId)
                put("latitude", latitude)
                put("longitude", longitude)
                put("battery_level", batteryLevel)
                put("timestamp", System.currentTimeMillis())
            }

            Log.d(TAG, "JSON payload: ${json.toString(2)}")

            val body = json.toString().toRequestBody("application/json".toMediaType())

            val request = Request.Builder()
                .url("$BASE_URL/device/locations")
                .post(body)
                .addHeader("Content-Type", "application/json")
                .addHeader("Accept", "application/json")
                .addHeader("User-Agent", "CoupleGuardChild/1.0")
                .build()

            val startTime = System.currentTimeMillis()
            val response = client.newCall(request).execute()
            val duration = System.currentTimeMillis() - startTime
            
            val responseBody = response.body?.string()

            Log.d(TAG, "Response Code: ${response.code}")
            Log.d(TAG, "Response Time: ${duration}ms")
            Log.d(TAG, "Response Body: $responseBody")

            val success = response.isSuccessful
            response.close()

            if (success) {
                Log.d(TAG, "✅ Location sent successfully")
            } else {
                Log.e(TAG, "❌ Location failed: ${response.code} - ${response.message}")
            }

            Log.d(TAG, "========================================")
            success

        } catch (e: java.net.SocketTimeoutException) {
            Log.e(TAG, "❌ TIMEOUT: Request took too long", e)
            false
        } catch (e: java.net.UnknownHostException) {
            Log.e(TAG, "❌ DNS ERROR: Cannot resolve $BASE_URL", e)
            false
        } catch (e: java.net.ConnectException) {
            Log.e(TAG, "❌ CONNECTION REFUSED: Server not reachable", e)
            false
        } catch (e: javax.net.ssl.SSLException) {
            Log.e(TAG, "❌ SSL ERROR: Certificate issue", e)
            false
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception sending location", e)
            e.printStackTrace()
            false
        }
    }

    fun updateDeviceStatus(context: Context, isOnline: Boolean): Boolean {
        return try {
            val deviceId = getDeviceId(context)
            if (deviceId.isNullOrEmpty()) {
                Log.e(TAG, "❌ No device ID")
                return false
            }

            val json = JSONObject().apply {
                put("is_online", isOnline)
            }

            val body = json.toString().toRequestBody("application/json".toMediaType())

            val request = Request.Builder()
                .url("$BASE_URL/device/$deviceId/status")
                .put(body)
                .addHeader("Content-Type", "application/json")
                .addHeader("Accept", "application/json")
                .build()

            val response = client.newCall(request).execute()
            val success = response.isSuccessful
            response.close()

            if (success) {
                Log.d(TAG, "✅ Device status updated: $isOnline")
            } else {
                Log.e(TAG, "❌ Failed to update status: ${response.code}")
            }

            success
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception updating status", e)
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
        // ✅ FIX 5: Add detailed start logging
        val callId = System.currentTimeMillis()
        
        return try {
            Log.d(TAG, "========================================")
            Log.d(TAG, "📧 SENDING NOTIFICATION #$callId")
            Log.d(TAG, "Thread: ${Thread.currentThread().name}")
            Log.d(TAG, "Stack depth: ${Thread.currentThread().stackTrace.size}")
            
            val deviceId = getDeviceId(context)
            if (deviceId.isNullOrEmpty()) {
                Log.e(TAG, "❌ No device ID for call #$callId")
                Log.d(TAG, "========================================")
                return false
            }

            Log.d(TAG, "Device ID: ${deviceId.substring(0, 8)}...")
            Log.d(TAG, "App: $appName")
            Log.d(TAG, "Title: $title")
            Log.d(TAG, "Content: ${content.take(100)}${if(content.length > 100) "..." else ""}")

            val json = JSONObject().apply {
                put("device_id", deviceId)
                put("app_name", appName)
                put("title", title)
                put("content", content)
                put("timestamp", System.currentTimeMillis())
            }

            Log.d(TAG, "JSON size: ${json.toString().length} bytes")

            val body = json.toString().toRequestBody("application/json".toMediaType())

            val request = Request.Builder()
                .url("$BASE_URL/device/notifications")
                .post(body)
                .addHeader("Content-Type", "application/json")
                .addHeader("Accept", "application/json")
                .addHeader("User-Agent", "CoupleGuardChild/1.0")
                .addHeader("X-Request-ID", callId.toString()) // ✅ Track request
                .build()

            Log.d(TAG, "🚀 Making HTTP POST to: $BASE_URL/device/notifications")
            Log.d(TAG, "Request headers: ${request.headers}")
            
            val startTime = System.currentTimeMillis()
            
            // ✅ FIX 6: Execute in current thread (already in executor thread)
            val response = client.newCall(request).execute()
            
            val duration = System.currentTimeMillis() - startTime
            val responseBody = response.body?.string()

            Log.d(TAG, "Response received in ${duration}ms")
            Log.d(TAG, "Response Code: ${response.code}")
            Log.d(TAG, "Response Message: ${response.message}")
            Log.d(TAG, "Response Headers: ${response.headers}")
            Log.d(TAG, "Response Body: $responseBody")

            val success = response.isSuccessful
            
            // ✅ FIX 7: Parse and log response details
            if (success) {
                try {
                    val jsonResponse = JSONObject(responseBody ?: "{}")
                    Log.d(TAG, "✅ SUCCESS - Call #$callId")
                    Log.d(TAG, "Server response: ${jsonResponse.toString(2)}")
                } catch (e: Exception) {
                    Log.d(TAG, "✅ SUCCESS - Call #$callId (no JSON response)")
                }
            } else {
                Log.e(TAG, "❌ FAILED - Call #$callId")
                Log.e(TAG, "Status: ${response.code} ${response.message}")
                Log.e(TAG, "Body: $responseBody")
                
                // ✅ FIX 8: Parse error message
                try {
                    val errorJson = JSONObject(responseBody ?: "{}")
                    Log.e(TAG, "Server error: ${errorJson.optString("message", "Unknown")}")
                } catch (e: Exception) {
                    Log.e(TAG, "Could not parse error response")
                }
            }
            
            response.close()
            Log.d(TAG, "========================================")
            
            success

        } catch (e: java.net.SocketTimeoutException) {
            Log.e(TAG, "❌ TIMEOUT - Call #$callId", e)
            Log.e(TAG, "The server took longer than 30 seconds to respond")
            Log.e(TAG, "========================================")
            false
        } catch (e: java.net.UnknownHostException) {
            Log.e(TAG, "❌ DNS ERROR - Call #$callId", e)
            Log.e(TAG, "Cannot resolve hostname: ${e.message}")
            Log.e(TAG, "Check internet connection")
            Log.e(TAG, "========================================")
            false
        } catch (e: java.net.ConnectException) {
            Log.e(TAG, "❌ CONNECTION ERROR - Call #$callId", e)
            Log.e(TAG, "Cannot connect to server: ${e.message}")
            Log.e(TAG, "Server might be down or unreachable")
            Log.e(TAG, "========================================")
            false
        } catch (e: javax.net.ssl.SSLException) {
            Log.e(TAG, "❌ SSL ERROR - Call #$callId", e)
            Log.e(TAG, "Certificate validation failed: ${e.message}")
            Log.e(TAG, "========================================")
            false
        } catch (e: Exception) {
            Log.e(TAG, "❌ EXCEPTION - Call #$callId", e)
            Log.e(TAG, "Error type: ${e.javaClass.name}")
            Log.e(TAG, "Error message: ${e.message}")
            e.printStackTrace()
            Log.e(TAG, "========================================")
            false
        }
    }

    fun uploadCapturedPhoto(context: Context, file: File, cameraType: String = "front"): Boolean {
        return try {
            Log.d(TAG, "========================================")
            Log.d(TAG, "📸 UPLOADING CAPTURED PHOTO")
            
            val deviceId = getDeviceId(context)
            if (deviceId.isNullOrEmpty()) {
                Log.e(TAG, "❌ No device ID")
                return false
            }

            Log.d(TAG, "Device ID: ${deviceId.substring(0, 8)}...")
            Log.d(TAG, "Camera Type: $cameraType")
            Log.d(TAG, "File size: ${file.length() / 1024} KB")

            // Create multipart request body
            val requestBody = MultipartBody.Builder()
                .setType(MultipartBody.FORM)
                .addFormDataPart("device_id", deviceId)
                .addFormDataPart("camera_type", cameraType)
                .addFormDataPart(
                    "photo",
                    file.name,
                    file.asRequestBody("image/jpeg".toMediaType())
                )
                .build()

            val request = Request.Builder()
                .url("$BASE_URL/device/captured-photos")
                .post(requestBody)
                .addHeader("Accept", "application/json")
                .build()

            val startTime = System.currentTimeMillis()
            val response = client.newCall(request).execute()
            val duration = System.currentTimeMillis() - startTime
            
            val responseBody = response.body?.string()

            Log.d(TAG, "Response Code: ${response.code}")
            Log.d(TAG, "Response Time: ${duration}ms")
            Log.d(TAG, "Response Body: $responseBody")

            val success = response.isSuccessful
            response.close()

            if (success) {
                Log.d(TAG, "✅ Photo uploaded successfully")
            } else {
                Log.e(TAG, "❌ Photo upload failed: ${response.code} - ${response.message}")
            }

            Log.d(TAG, "========================================")
            success

        } catch (e: java.net.SocketTimeoutException) {
            Log.e(TAG, "❌ TIMEOUT: Photo upload took too long", e)
            false
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception uploading photo", e)
            e.printStackTrace()
            false
        }
    }

    fun uploadScreenshot(context: Context, file: File): Boolean {
        return try {
            Log.d(TAG, "========================================")
            Log.d(TAG, "🖥️ UPLOADING SCREENSHOT")
            
            val deviceId = getDeviceId(context)
            if (deviceId.isNullOrEmpty()) {
                Log.e(TAG, "❌ No device ID")
                return false
            }

            Log.d(TAG, "Device ID: ${deviceId.substring(0, 8)}...")
            Log.d(TAG, "File size: ${file.length() / 1024} KB")

            // Create multipart request body
            val requestBody = MultipartBody.Builder()
                .setType(MultipartBody.FORM)
                .addFormDataPart("device_id", deviceId)
                .addFormDataPart(
                    "screenshot",
                    file.name,
                    file.asRequestBody("image/jpeg".toMediaType())
                )
                .build()

            val request = Request.Builder()
                .url("$BASE_URL/device/screenshots")
                .post(requestBody)
                .addHeader("Accept", "application/json")
                .build()

            val startTime = System.currentTimeMillis()
            val response = client.newCall(request).execute()
            val duration = System.currentTimeMillis() - startTime
            
            val responseBody = response.body?.string()

            Log.d(TAG, "Response Code: ${response.code}")
            Log.d(TAG, "Response Time: ${duration}ms")

            val success = response.isSuccessful
            response.close()

            if (success) {
                Log.d(TAG, "✅ Screenshot uploaded successfully")
            } else {
                Log.e(TAG, "❌ Screenshot upload failed: ${response.code}")
            }

            Log.d(TAG, "========================================")
            success

        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception uploading screenshot", e)
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
                Log.e(TAG, "❌ FCM token update failed: ${response.code}")
            }

            success

        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception updating FCM token", e)
            false
        }
    }
}