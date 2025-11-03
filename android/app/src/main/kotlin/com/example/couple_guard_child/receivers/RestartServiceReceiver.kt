package com.example.couple_guard_child.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.example.couple_guard_child.workers.LocationWorkManager
import com.example.couple_guard_child.utils.ApiClient
import com.example.couple_guard_child.services.ServiceKeepAliveManager

/**
 * RestartServiceReceiver
 * Triggered by AlarmManager to ensure services stay alive
 */
class RestartServiceReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "RestartServiceReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "========================================")
        Log.d(TAG, "⏰ RESTART SERVICE RECEIVER TRIGGERED")
        Log.d(TAG, "Action: ${intent.action}")
        
        try {
            // Check if device is paired
            val isPaired = ApiClient.isPaired(context)
            val deviceId = ApiClient.getDeviceId(context)
            
            Log.d(TAG, "Device paired: $isPaired")
            Log.d(TAG, "Device ID: ${deviceId?.take(8) ?: "NULL"}...")
            
            if (!isPaired || deviceId.isNullOrEmpty()) {
                Log.d(TAG, "❌ Device not paired, skipping restart")
                return
            }
            
            Log.d(TAG, "✅ Device is paired, restarting services...")
            
            // STEP 1: Restart foreground service
            restartForegroundService(context)
            
            // STEP 2: Ensure WorkManager is scheduled
            restartWorkManager(context)
            
            // STEP 3: Reschedule next alarm
            ServiceKeepAliveManager.scheduleServiceCheck(context)
            
            Log.d(TAG, "✅ Services restart complete")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error in RestartServiceReceiver", e)
            e.printStackTrace()
        }
        
        Log.d(TAG, "========================================")
    }

    private fun restartForegroundService(context: Context) {
        try {
            Log.d(TAG, "Restarting foreground service...")
            
            val serviceIntent = Intent(
                context,
                id.flutter.flutter_background_service.BackgroundService::class.java
            )
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
                Log.d(TAG, "✅ Foreground service started")
            } else {
                context.startService(serviceIntent)
                Log.d(TAG, "✅ Service started")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to restart foreground service", e)
        }
    }

    private fun restartWorkManager(context: Context) {
        try {
            Log.d(TAG, "Ensuring WorkManager is scheduled...")
            
            val isScheduled = LocationWorkManager.isWorkScheduled(context)
            Log.d(TAG, "Location work currently scheduled: $isScheduled")
            
            if (!isScheduled) {
                LocationWorkManager.schedulePeriodicLocationUpdates(context)
                Log.d(TAG, "✅ WorkManager re-scheduled")
            } else {
                Log.d(TAG, "✅ WorkManager already scheduled")
            }
            
            // Also ensure watchdog is running
            val watchdogScheduled = LocationWorkManager.isWatchdogScheduled(context)
            Log.d(TAG, "Watchdog scheduled: $watchdogScheduled")
            
            if (!watchdogScheduled) {
                LocationWorkManager.scheduleWatchdog(context)
                Log.d(TAG, "✅ Watchdog re-scheduled")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to restart WorkManager", e)
        }
    }
}

// ===============================================
// ALSO ADD: NetworkStateReceiver (for offline retry)
// ===============================================

class NetworkStateReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "NetworkStateReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != "android.net.conn.CONNECTIVITY_CHANGE") {
            return
        }

        val connectivityManager = context.getSystemService(
            Context.CONNECTIVITY_SERVICE
        ) as android.net.ConnectivityManager
        
        val activeNetwork = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            connectivityManager.activeNetwork
        } else {
            @Suppress("DEPRECATION")
            connectivityManager.activeNetworkInfo
        }
        
        val isConnected = activeNetwork != null
        
        Log.d(TAG, "Network state changed: ${if (isConnected) "CONNECTED" else "DISCONNECTED"}")
        
        // Trigger immediate location update if network is back
        if (isConnected) {
            val isPaired = ApiClient.isPaired(context)
            if (isPaired) {
                Log.d(TAG, "📡 Network restored - Triggering location update")
                LocationWorkManager.scheduleImmediateLocationUpdate(context)
            }
        }
    }
}