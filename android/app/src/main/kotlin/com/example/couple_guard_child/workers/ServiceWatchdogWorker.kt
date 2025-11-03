package com.example.couple_guard_child.workers

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.couple_guard_child.utils.ApiClient
import java.text.SimpleDateFormat
import java.util.*

/**
 * Watchdog Worker - Memastikan semua service tetap hidup
 * Berjalan setiap 15 menit untuk check & restart service yang mati
 */
class ServiceWatchdogWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        private const val TAG = "ServiceWatchdog"
    }

    override suspend fun doWork(): Result {
        val currentTime = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
        
        Log.d(TAG, "========================================")
        Log.d(TAG, "🐕 WATCHDOG CHECK - $currentTime")
        Log.d(TAG, "========================================")

        val isPaired = ApiClient.isPaired(applicationContext)
        val deviceId = ApiClient.getDeviceId(applicationContext)
        
        Log.d(TAG, "Device paired: $isPaired")
        Log.d(TAG, "Device ID: ${deviceId?.take(8) ?: "NULL"}...")

        if (!isPaired || deviceId.isNullOrEmpty()) {
            Log.d(TAG, "⏭️ Device not paired, skipping watchdog")
            return Result.success()
        }

        checkAndFixLocationWork()
        checkAndFixForegroundService()
        checkAndFixNotificationListener()
        sendHeartbeat()

        Log.d(TAG, "========================================")
        Log.d(TAG, "✅ WATCHDOG CHECK COMPLETE")
        Log.d(TAG, "========================================")

        return Result.success()
    }

    /**
     * Check if location WorkManager is scheduled
     */
    private fun checkAndFixLocationWork() {
        Log.d(TAG, "Checking Location WorkManager...")

        val isScheduled = LocationWorkManager.isWorkScheduled(applicationContext)
        
        Log.d(TAG, "Location work scheduled: $isScheduled")

        if (!isScheduled) {
            Log.w(TAG, "⚠️ Location work NOT scheduled! Fixing...")
            
            try {
                LocationWorkManager.schedulePeriodicLocationUpdates(applicationContext)
                
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    val verified = LocationWorkManager.isWorkScheduled(applicationContext)
                    Log.d(TAG, "Location work re-scheduled: $verified")
                }, 2000)
                
                Log.d(TAG, "✅ Location work restarted")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to restart location work", e)
            }
        } else {
            Log.d(TAG, "✅ Location work is running")
        }
    }

    /**
     * Check if foreground service is running
     */
    private fun checkAndFixForegroundService() {
        Log.d(TAG, "Checking Foreground Service...")

        // ✅ FIX: Use correct package name for flutter service
        val isRunning = isServiceRunning(
            applicationContext,
            "id.flutter.flutter_background_service.BackgroundService"
        )
        
        Log.d(TAG, "Foreground service running: $isRunning")

        if (!isRunning) {
            Log.w(TAG, "⚠️ Foreground service NOT running! Restarting...")
            
            try {
                // ✅ FIX: Create intent using Class.forName to avoid compile error
                val serviceClass = Class.forName("id.flutter.flutter_background_service.BackgroundService")
                val intent = Intent(applicationContext, serviceClass)
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    applicationContext.startForegroundService(intent)
                } else {
                    applicationContext.startService(intent)
                }
                
                Log.d(TAG, "✅ Foreground service restarted")
            } catch (e: ClassNotFoundException) {
                Log.e(TAG, "❌ BackgroundService class not found", e)
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to restart foreground service", e)
            }
        } else {
            Log.d(TAG, "✅ Foreground service is running")
        }
    }

    /**
     * Check if notification listener is connected
     */
    private fun checkAndFixNotificationListener() {
        Log.d(TAG, "Checking Notification Listener...")

        val isEnabled = isNotificationListenerEnabled(applicationContext)
        
        Log.d(TAG, "Notification listener enabled: $isEnabled")

        if (!isEnabled) {
            Log.w(TAG, "⚠️ Notification listener NOT enabled (user needs to enable)")
        } else {
            val isRunning = isServiceRunning(
                applicationContext,
                "com.example.couple_guard_child.services.background.MyNotificationListenerService"
            )
            
            Log.d(TAG, "Notification listener running: $isRunning")
            
            if (!isRunning) {
                Log.w(TAG, "⚠️ Notification listener enabled but not running! Requesting rebind...")
                
                try {
                    val intent = Intent(
                        "com.example.couple_guard_child.ACTION_REBIND_NOTIFICATION_LISTENER"
                    )
                    intent.setPackage(applicationContext.packageName)
                    applicationContext.sendBroadcast(intent)
                    
                    Log.d(TAG, "✅ Rebind request sent")
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Failed to request rebind", e)
                }
            } else {
                Log.d(TAG, "✅ Notification listener is running")
            }
        }
    }

    /**
     * Send heartbeat to server untuk status monitoring
     */
    private fun sendHeartbeat() {
        try {
            Log.d(TAG, "Sending heartbeat to server...")
            
            val deviceId = ApiClient.getDeviceId(applicationContext) ?: return
            
            val success = ApiClient.updateDeviceStatus(applicationContext, true)
            
            if (success) {
                Log.d(TAG, "✅ Heartbeat sent successfully")
            } else {
                Log.w(TAG, "⚠️ Heartbeat failed (server unreachable?)")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to send heartbeat", e)
        }
    }

    /**
     * Check if a service is currently running
     */
    private fun isServiceRunning(context: Context, serviceClassName: String): Boolean {
        return try {
            val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            
            @Suppress("DEPRECATION")
            for (service in manager.getRunningServices(Int.MAX_VALUE)) {
                if (serviceClassName == service.service.className) {
                    return true
                }
            }
            false
        } catch (e: Exception) {
            Log.e(TAG, "Error checking service: $serviceClassName", e)
            false
        }
    }

    /**
     * Check if notification listener is enabled
     */
    private fun isNotificationListenerEnabled(context: Context): Boolean {
        return try {
            val pkgName = context.packageName
            val flat = android.provider.Settings.Secure.getString(
                context.contentResolver,
                "enabled_notification_listeners"
            )
            
            if (!flat.isNullOrEmpty()) {
                flat.contains(pkgName)
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking notification listener", e)
            false
        }
    }
}