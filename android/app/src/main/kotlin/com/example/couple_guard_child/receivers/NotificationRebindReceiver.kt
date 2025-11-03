package com.example.couple_guard_child.receivers

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.example.couple_guard_child.services.background.MyNotificationListenerService

/**
 * NotificationRebindReceiver
 * Handle rebind request untuk notification listener
 */
class NotificationRebindReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "NotifRebindReceiver"
        const val ACTION_REBIND = "com.example.couple_guard_child.ACTION_REBIND_NOTIFICATION_LISTENER"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_REBIND) return
        
        Log.d(TAG, "========================================")
        Log.d(TAG, "🔔 REBIND REQUEST RECEIVED")
        
        try {
            // Request rebind menggunakan Android API
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                Log.d(TAG, "Requesting rebind via ComponentName...")
                
                val componentName = ComponentName(
                    context,
                    MyNotificationListenerService::class.java
                )
                
                // Ini akan trigger onListenerConnected() di service
                MyNotificationListenerService.requestRebind(componentName)
                
                Log.d(TAG, "✅ Rebind requested")
            } else {
                Log.d(TAG, "Android version < N, rebind not supported")
            }
            
            // Fallback: restart service manually
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                try {
                    val serviceIntent = Intent(context, MyNotificationListenerService::class.java)
                    context.startService(serviceIntent)
                    Log.d(TAG, "✅ Service restart fallback executed")
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Failed to restart service", e)
                }
            }, 2000)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error handling rebind request", e)
        }
        
        Log.d(TAG, "========================================")
    }
}