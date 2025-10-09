package com.example.couple_guard_child.services

import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import id.flutter.flutter_background_service.BackgroundService

/**
 * Custom Wrapper untuk flutter_background_service
 * Memastikan service TIDAK MATI ketika app di-close
 */
class CustomBackgroundService : Service() {
    companion object {
        private const val TAG = "CustomBackgroundService"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "========================================")
        Log.d(TAG, "SERVICE CREATED")
        Log.d(TAG, "========================================")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "========================================")
        Log.d(TAG, "onStartCommand() called")
        Log.d(TAG, "Intent: $intent")
        Log.d(TAG, "Flags: $flags")
        Log.d(TAG, "StartId: $startId")
        Log.d(TAG, "========================================")

        // ✅ CRITICAL: Return START_STICKY
        // Ini membuat Android restart service jika di-kill
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        Log.d(TAG, "onBind() called")
        return null
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        
        Log.d(TAG, "========================================")
        Log.d(TAG, "⚠️ TASK REMOVED - App closed from Recent Apps")
        Log.d(TAG, "========================================")

        try {
            // ✅ STEP 1: Check if device is paired
            val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            val isPaired = prefs.getBoolean("flutter.is_paired", false)
            
            Log.d(TAG, "Paired status: $isPaired")

            if (isPaired) {
                Log.d(TAG, "✅ Device is paired - RESTARTING SERVICE")
                
                // ✅ STEP 2: Restart service immediately
                val restartIntent = Intent(
                    applicationContext,
                    id.flutter.flutter_background_service.BackgroundService::class.java
                )
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    applicationContext.startForegroundService(restartIntent)
                    Log.d(TAG, "✅ Service restarted as FOREGROUND")
                } else {
                    applicationContext.startService(restartIntent)
                    Log.d(TAG, "✅ Service restarted")
                }
            } else {
                Log.d(TAG, "❌ Device not paired - Service will stop")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error in onTaskRemoved", e)
        }

        Log.d(TAG, "========================================")
    }

    override fun onDestroy() {
        super.onDestroy()
        
        Log.d(TAG, "========================================")
        Log.d(TAG, "⚠️ SERVICE DESTROYED")
        Log.d(TAG, "========================================")

        try {
            // ✅ Check if this is unexpected destroy
            val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            val isPaired = prefs.getBoolean("flutter.is_paired", false)

            if (isPaired) {
                Log.d(TAG, "⚠️ UNEXPECTED DESTROY - Attempting restart")
                
                // Schedule restart after delay
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    try {
                        val restartIntent = Intent(
                            applicationContext,
                            id.flutter.flutter_background_service.BackgroundService::class.java
                        )
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            applicationContext.startForegroundService(restartIntent)
                        } else {
                            applicationContext.startService(restartIntent)
                        }
                        
                        Log.d(TAG, "✅ Service restarted after destroy")
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Failed to restart service", e)
                    }
                }, 1000) // Restart after 1 second
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error in onDestroy", e)
        }
    }
}