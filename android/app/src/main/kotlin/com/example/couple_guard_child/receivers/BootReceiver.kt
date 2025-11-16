package com.example.couple_guard_child.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.example.couple_guard_child.services.PersistentService

class BootReceiver : BroadcastReceiver() {
    private val TAG = "BootReceiver"

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        
        val action = intent.action
        Log.d(TAG, "📱 Broadcast received: $action")
        
        when (action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.d(TAG, "🔄 Device booted - starting service")
                startPersistentService(context)
            }
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d(TAG, "📦 App updated - starting service")
                startPersistentService(context)
            }
            Intent.ACTION_LOCKED_BOOT_COMPLETED -> {
                Log.d(TAG, "🔒 Locked boot completed - starting service")
                startPersistentService(context)
            }
            "android.intent.action.QUICKBOOT_POWERON" -> {
                Log.d(TAG, "⚡ Quick boot - starting service")
                startPersistentService(context)
            }
            "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                Log.d(TAG, "⚡ HTC Quick boot - starting service")
                startPersistentService(context)
            }
        }
    }

    private fun startPersistentService(context: Context) {
        try {
            val serviceIntent = Intent(context, PersistentService::class.java)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
                Log.d(TAG, "✅ Foreground service started")
            } else {
                context.startService(serviceIntent)
                Log.d(TAG, "✅ Service started")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start service", e)
        }
    }
}