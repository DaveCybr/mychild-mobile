package com.example.couple_guard_child

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.couple_guard_child.workers.LocationWorkManager
import com.example.couple_guard_child.utils.ApiClient

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "========================================")
            Log.d(TAG, "🔄 BOOT COMPLETED - Device rebooted")
            
            try {
                val isPaired = ApiClient.isPaired(context)
                val deviceId = ApiClient.getDeviceId(context)
                
                Log.d(TAG, "Pairing status: $isPaired")
                Log.d(TAG, "Device ID: ${deviceId?.substring(0, 8)}...")
                
                if (isPaired && !deviceId.isNullOrEmpty()) {
                    Log.d(TAG, "✅ Device is PAIRED - Starting services")
                    
                    // ✅ Start background service
                    val serviceIntent = Intent(
                        context, 
                        id.flutter.flutter_background_service.BackgroundService::class.java
                    )
                    
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                    
                    // ✅ Schedule periodic location updates
                    LocationWorkManager.schedulePeriodicLocationUpdates(context)
                    
                    Log.d(TAG, "✅ All services started")
                } else {
                    Log.d(TAG, "❌ Device NOT paired - Skipping")
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error in BootReceiver", e)
            }
            
            Log.d(TAG, "========================================")
        }
    }
}