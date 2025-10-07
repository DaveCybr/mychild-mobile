package com.example.couple_guard_child

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "========================================")
            Log.d(TAG, "BOOT COMPLETED - Device rebooted")
            
            try {
                // Check SharedPreferences if device is paired
                val prefs = context.getSharedPreferences(
                    "FlutterSharedPreferences", 
                    Context.MODE_PRIVATE
                )
                val isPaired = prefs.getBoolean("flutter.is_paired", false)
                val deviceId = prefs.getString("flutter.device_id", null)
                
                Log.d(TAG, "Pairing status: $isPaired")
                Log.d(TAG, "Device ID: $deviceId")
                
                // CRITICAL: Only start service if PAIRED
                if (isPaired && !deviceId.isNullOrEmpty()) {
                    Log.d(TAG, "✅ Device is PAIRED - Starting service")
                    
                    val serviceIntent = Intent(
                        context, 
                        id.flutter.flutter_background_service.BackgroundService::class.java
                    )
                    
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                        Log.d(TAG, "Started foreground service")
                    } else {
                        context.startService(serviceIntent)
                        Log.d(TAG, "Started service")
                    }
                } else {
                    Log.d(TAG, "❌ Device NOT paired - Skipping service start")
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error in BootReceiver", e)
            }
            
            Log.d(TAG, "========================================")
        }
    }
}