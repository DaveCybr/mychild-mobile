package com.example.couple_guard_child.workers

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.os.BatteryManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.couple_guard_child.utils.ApiClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull

class LocationWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    private val TAG = "LocationWorker"
    private val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)

    override suspend fun doWork(): Result {
        Log.d(TAG, "========================================")
        Log.d(TAG, "🔄 LocationWorker started")
        Log.d(TAG, "Run attempt: $runAttemptCount")
        
        return try {
            // Check if device is paired
            if (!ApiClient.isPaired(applicationContext)) {
                Log.w(TAG, "⚠️ Device not paired, skipping location update")
                return Result.success()
            }
            
            // Check location permission
            if (!hasLocationPermission()) {
                Log.e(TAG, "❌ Location permission not granted")
                return Result.failure()
            }
            
            // Get location
            val location = getLocation()
            
            if (location != null) {
                Log.d(TAG, "📍 Location obtained: ${location.latitude}, ${location.longitude}")
                Log.d(TAG, "Accuracy: ${location.accuracy}m")
                Log.d(TAG, "Time: ${System.currentTimeMillis() - location.time}ms ago")
                
                // Get battery level
                val batteryLevel = getBatteryLevel()
                Log.d(TAG, "🔋 Battery: $batteryLevel%")
                
                // Send to server
                val success = ApiClient.sendLocation(
                    applicationContext,
                    location.latitude,
                    location.longitude,
                    batteryLevel
                )
                
                if (success) {
                    Log.d(TAG, "✅ LocationWorker completed successfully")
                    Log.d(TAG, "========================================")
                    Result.success()
                } else {
                    Log.e(TAG, "❌ Failed to send location to server")
                    Log.d(TAG, "========================================")
                    
                    // Retry on failure
                    if (runAttemptCount < 3) {
                        Log.d(TAG, "🔄 Will retry (attempt ${runAttemptCount + 1}/3)")
                        Result.retry()
                    } else {
                        Log.e(TAG, "❌ Max retries reached")
                        Result.failure()
                    }
                }
            } else {
                Log.e(TAG, "❌ Could not get location")
                Log.d(TAG, "========================================")
                
                // Retry on null location
                if (runAttemptCount < 3) {
                    Result.retry()
                } else {
                    Result.failure()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception in LocationWorker", e)
            e.printStackTrace()
            Log.d(TAG, "========================================")
            
            // Retry on exception
            if (runAttemptCount < 3) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }

    private fun hasLocationPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private suspend fun getLocation(): Location? {
        return try {
            // First try to get last known location (fast)
            val lastLocation = withTimeoutOrNull(5000L) {
                if (ActivityCompat.checkSelfPermission(
                        applicationContext,
                        Manifest.permission.ACCESS_FINE_LOCATION
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    return@withTimeoutOrNull null
                }
                fusedLocationClient.lastLocation.await()
            }
            
            if (lastLocation != null && isLocationFresh(lastLocation)) {
                Log.d(TAG, "✅ Using last known location")
                return lastLocation
            }
            
            // If last location is too old or null, request current location
            Log.d(TAG, "🔄 Requesting current location")
            val currentLocation = withTimeoutOrNull(30000L) {
                if (ActivityCompat.checkSelfPermission(
                        applicationContext,
                        Manifest.permission.ACCESS_FINE_LOCATION
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    return@withTimeoutOrNull null
                }
                
                fusedLocationClient.getCurrentLocation(
                    Priority.PRIORITY_HIGH_ACCURACY,
                    null
                ).await()
            }
            
            if (currentLocation != null) {
                Log.d(TAG, "✅ Got current location")
            } else {
                Log.w(TAG, "⚠️ Current location is null, falling back to last location")
            }
            
            currentLocation ?: lastLocation
            
        } catch (e: SecurityException) {
            Log.e(TAG, "❌ Security exception getting location", e)
            null
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception getting location", e)
            null
        }
    }

    private fun isLocationFresh(location: Location): Boolean {
        val ageMillis = System.currentTimeMillis() - location.time
        val maxAgeMillis = 5 * 60 * 1000 // 5 minutes
        return ageMillis < maxAgeMillis
    }

    private fun getBatteryLevel(): Int {
        return try {
            val batteryManager = applicationContext.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            level
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error getting battery level", e)
            -1
        }
    }
}