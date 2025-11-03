package com.example.couple_guard_child.workers

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.google.android.gms.location.*
import kotlinx.coroutines.tasks.await
import com.example.couple_guard_child.utils.ApiClient
import android.os.PowerManager
import java.text.SimpleDateFormat
import java.util.Date 
import java.util.Locale
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.withTimeout

class LocationWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        private const val TAG = "LocationWorker"
        private const val LOCATION_TIMEOUT_MS = 30000L // 30 seconds
        private const val MAX_LOCATION_AGE_MINUTES = 10L
    }

    override suspend fun doWork(): Result {
        val wakeLock = (applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "LocationWorker::WakeLock")
        
        try {
            wakeLock.acquire(10 * 60 * 1000L)
            
            Log.d(TAG, "========================================")
            Log.d(TAG, "⏰ PERIODIC LOCATION UPDATE TRIGGERED")
            Log.d(TAG, "Time: ${SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())}")
            Log.d(TAG, "Run attempt: $runAttemptCount")
            Log.d(TAG, "========================================")

            // Check pairing status
            val isPaired = ApiClient.isPaired(applicationContext)
            val deviceId = ApiClient.getDeviceId(applicationContext)
            
            Log.d(TAG, "Device paired: $isPaired")
            Log.d(TAG, "Device ID: ${deviceId?.take(8) ?: "NULL"}...")
            
            if (!isPaired || deviceId.isNullOrEmpty()) {
                Log.w(TAG, "❌ Device not paired, skipping")
                return Result.success()
            }

            // Get location with timeout
            val location = try {
                withTimeout(LOCATION_TIMEOUT_MS) {
                    getLocation()
                }
            } catch (e: TimeoutCancellationException) {
                Log.e(TAG, "❌ Location request timeout")
                return if (runAttemptCount < 3) Result.retry() else Result.failure()
            }

            if (location == null) {
                Log.e(TAG, "❌ Failed to get location")
                return if (runAttemptCount < 3) Result.retry() else Result.failure()
            }

            Log.d(TAG, "✅ Location obtained:")
            Log.d(TAG, "   Lat: ${location.latitude}")
            Log.d(TAG, "   Lng: ${location.longitude}")
            Log.d(TAG, "   Accuracy: ${location.accuracy}m")
            Log.d(TAG, "   Age: ${(System.currentTimeMillis() - location.time) / 1000}s")

            // Get battery level
            val batteryLevel = try {
                val batteryManager = applicationContext.getSystemService(
                    Context.BATTERY_SERVICE
                ) as? android.os.BatteryManager
                
                batteryManager?.getIntProperty(
                    android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY
                ) ?: 0
            } catch (e: Exception) {
                Log.e(TAG, "Failed to get battery level", e)
                0
            }

            Log.d(TAG, "🔋 Battery level: $batteryLevel%")

            // Send to server with retry
            Log.d(TAG, "📤 Sending to API...")
            val startTime = System.currentTimeMillis()
            
            val success = sendLocationWithRetry(
                location.latitude,
                location.longitude,
                batteryLevel
            )
            
            val duration = System.currentTimeMillis() - startTime

            if (success) {
                Log.d(TAG, "✅ Location sent successfully in ${duration}ms")
                return Result.success()
            } else {
                Log.e(TAG, "❌ Failed to send location after retries")
                return if (runAttemptCount < 3) Result.retry() else Result.failure()
            }

        } catch (e: Exception) {
            Log.e(TAG, "❌ Worker exception", e)
            return Result.retry()
        } finally {
            if (wakeLock.isHeld) {
                wakeLock.release()
                Log.d(TAG, "🔓 Wake lock released")
            }
        }
    }

    private suspend fun getLocation(): android.location.Location? {
        return try {
            Log.d(TAG, "Checking location permission...")
            
            // Check permission
            if (applicationContext.checkSelfPermission(
                    android.Manifest.permission.ACCESS_FINE_LOCATION
                ) != android.content.pm.PackageManager.PERMISSION_GRANTED
            ) {
                Log.e(TAG, "❌ No location permission!")
                return null
            }
            
            Log.d(TAG, "✅ Permission granted")

            val fusedLocationClient = LocationServices.getFusedLocationProviderClient(
                applicationContext
            )

            // Try last known location first
            Log.d(TAG, "Trying last known location...")
            var location = fusedLocationClient.lastLocation.await()

            // If no last location or too old, get fresh one
            if (location == null || isLocationTooOld(location)) {
                Log.d(TAG, "Last location ${if (location == null) "not available" else "too old"}")
                Log.d(TAG, "Requesting fresh location...")
                
                // Use high accuracy request
                val locationRequest = LocationRequest.create().apply {
                    priority = LocationRequest.PRIORITY_HIGH_ACCURACY
                    interval = 10000
                    fastestInterval = 5000
                    maxWaitTime = 20000
                }
                
                location = fusedLocationClient.getCurrentLocation(
                    LocationRequest.PRIORITY_HIGH_ACCURACY,
                    null
                ).await()
                
                Log.d(TAG, "Fresh location ${if (location != null) "obtained" else "failed"}")
            } else {
                Log.d(TAG, "Using cached location")
            }

            location

        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception getting location", e)
            null
        }
    }

    private fun isLocationTooOld(location: android.location.Location): Boolean {
        val ageInMinutes = (System.currentTimeMillis() - location.time) / 1000 / 60
        return ageInMinutes > MAX_LOCATION_AGE_MINUTES
    }

    private suspend fun sendLocationWithRetry(
        latitude: Double,
        longitude: Double,
        batteryLevel: Int,
        maxRetries: Int = 3
    ): Boolean {
        repeat(maxRetries) { attempt ->
            try {
                val success = ApiClient.sendLocation(
                    applicationContext,
                    latitude,
                    longitude,
                    batteryLevel
                )
                
                if (success) {
                    return true
                }
                
                if (attempt < maxRetries - 1) {
                    Log.d(TAG, "Retry ${attempt + 1}/$maxRetries in 2 seconds...")
                    kotlinx.coroutines.delay(2000)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Send attempt ${attempt + 1} failed", e)
                if (attempt < maxRetries - 1) {
                    kotlinx.coroutines.delay(2000)
                }
            }
        }
        return false
    }
}