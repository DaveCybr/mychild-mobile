package com.example.couple_guard_child.workers

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.google.android.gms.location.*
import kotlinx.coroutines.tasks.await
import com.example.couple_guard_child.utils.ApiClient

class LocationWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        private const val TAG = "LocationWorker"
    }

    override suspend fun doWork(): Result {
        Log.d(TAG, "========================================")
        Log.d(TAG, "⏰ PERIODIC LOCATION UPDATE TRIGGERED")
        Log.d(TAG, "========================================")

        return try {
            // Check if device is paired
            if (!ApiClient.isPaired(applicationContext)) {
                Log.d(TAG, "❌ Device not paired, skipping")
                return Result.success()
            }

            val deviceId = ApiClient.getDeviceId(applicationContext)
            Log.d(TAG, "Device ID: ${deviceId?.substring(0, 8)}...")

            // Get location
            val location = getLocation()

            if (location == null) {
                Log.e(TAG, "❌ Failed to get location")
                return Result.retry()
            }

            Log.d(TAG, "✅ Location: ${location.latitude}, ${location.longitude}")

            // Get battery level
            val batteryManager = applicationContext.getSystemService(
                Context.BATTERY_SERVICE
            ) as android.os.BatteryManager
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
                Log.d(TAG, "✅ Location sent successfully")
                Log.d(TAG, "========================================")
                Result.success()
            } else {
                Log.e(TAG, "❌ Failed to send location")
                Log.d(TAG, "========================================")
                Result.retry()
            }

        } catch (e: Exception) {
            Log.e(TAG, "❌ Worker failed", e)
            Log.d(TAG, "========================================")
            Result.retry()
        }
    }

    private suspend fun getLocation(): android.location.Location? {
        return try {
            // Check permission
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                if (applicationContext.checkSelfPermission(
                        android.Manifest.permission.ACCESS_FINE_LOCATION
                    ) != android.content.pm.PackageManager.PERMISSION_GRANTED
                ) {
                    Log.e(TAG, "❌ No location permission")
                    return null
                }
            }

            val fusedLocationClient = LocationServices.getFusedLocationProviderClient(
                applicationContext
            )

            // Try last known location first
            var location = fusedLocationClient.lastLocation.await()

            // If no last location or too old, get fresh one
            if (location == null || isLocationTooOld(location)) {
                Log.d(TAG, "Getting fresh location...")
                location = fusedLocationClient.getCurrentLocation(
                    LocationRequest.PRIORITY_HIGH_ACCURACY,
                    null
                ).await()
            }

            location

        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to get location", e)
            null
        }
    }

    private fun isLocationTooOld(location: android.location.Location): Boolean {
        val ageInMinutes = (System.currentTimeMillis() - location.time) / 1000 / 60
        return ageInMinutes > 10 // More than 10 minutes = too old
    }
}