package com.example.couple_guard_child.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.example.couple_guard_child.workers.LocationWorkManager
import com.example.couple_guard_child.utils.ApiClient

/**
 * BOOT RECEIVER
 * Handles device reboot and quick boot
 * Restarts services if device is paired
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
        private const val STARTUP_DELAY_MS = 5000L // 5 seconds
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        
        Log.d(TAG, "========================================")
        Log.d(TAG, "🔄 BROADCAST RECEIVED: $action")
        Log.d(TAG, "Time: ${java.text.SimpleDateFormat("HH:mm:ss", java.util.Locale.getDefault()).format(java.util.Date())}")
        
        when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                handleStartup(context)
            }
            else -> {
                Log.w(TAG, "⚠️ Unhandled action: $action")
            }
        }
        
        Log.d(TAG, "========================================")
    }

    private fun handleStartup(context: Context) {
        try {
            val isPaired = ApiClient.isPaired(context)
            val deviceId = ApiClient.getDeviceId(context)
            
            Log.d(TAG, "Pairing status: $isPaired")
            Log.d(TAG, "Device ID: ${deviceId?.substring(0, 8) ?: "NULL"}...")
            
            if (!isPaired || deviceId.isNullOrEmpty()) {
                Log.d(TAG, "❌ Device NOT paired - Services will not start")
                return
            }
            
            Log.d(TAG, "✅ Device is PAIRED - Scheduling startup...")
            
            // Delay startup to ensure system is ready
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                startServices(context)
            }, STARTUP_DELAY_MS)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error in BootReceiver", e)
            e.printStackTrace()
        }
    }

    private fun startServices(context: Context) {
        try {
            Log.d(TAG, "🚀 Starting services...")
            
            // 1. Start foreground service
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
            
            // 2. Schedule location work (includes watchdog)
            LocationWorkManager.schedulePeriodicLocationUpdates(context)
            Log.d(TAG, "✅ Location work scheduled")
            
            // 3. ✨ NEW: Schedule AlarmManager keep-alive
            ServiceKeepAliveManager.scheduleServiceCheck(context)
            Log.d(TAG, "✅ Keep-alive alarm scheduled")
            
            // 4. Verify after delay
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                verifyStartup(context)
            }, 3000)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error starting services", e)
            e.printStackTrace()
        }
    }

    private fun verifyStartup(context: Context) {
        try {
            val isScheduled = LocationWorkManager.isWorkScheduled(context)
            val watchdogScheduled = LocationWorkManager.isWatchdogScheduled(context) // ✨ NEW
            val alarmScheduled = ServiceKeepAliveManager.isAlarmScheduled(context) // ✨ NEW
            val status = LocationWorkManager.getWorkStatus(context)
            
            Log.d(TAG, "========================================")
            Log.d(TAG, "📊 STARTUP VERIFICATION")
            Log.d(TAG, "Location work scheduled: $isScheduled")
            Log.d(TAG, "Watchdog scheduled: $watchdogScheduled") // ✨ NEW
            Log.d(TAG, "AlarmManager scheduled: $alarmScheduled") // ✨ NEW
            Log.d(TAG, "Work status: $status")
            Log.d(TAG, "========================================")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error verifying startup", e)
        }
    }
}

/**
 * NETWORK STATE RECEIVER
 * Monitors network connectivity changes
 * Useful for retrying failed API calls
 */
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

/**
 * PACKAGE REPLACED RECEIVER
 * Handles app updates
 */
class PackageReplacedReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "PackageReplacedReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) {
            return
        }

        Log.d(TAG, "========================================")
        Log.d(TAG, "📦 APP UPDATED - Restarting services")
        
        val isPaired = ApiClient.isPaired(context)
        
        if (isPaired) {
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                try {
                    val serviceIntent = Intent(
                        context,
                        id.flutter.flutter_background_service.BackgroundService::class.java
                    )
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                    
                    LocationWorkManager.schedulePeriodicLocationUpdates(context)
                    Log.d(TAG, "✅ Services restarted after update")
                    
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error restarting services", e)
                }
            }, 2000)
        }
        
        Log.d(TAG, "========================================")
    }
}