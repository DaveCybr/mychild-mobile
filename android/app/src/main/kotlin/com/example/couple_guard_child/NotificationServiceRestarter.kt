package com.example.couple_guard_child

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class NotificationServiceRestarter : BroadcastReceiver() {
    companion object {
        private const val TAG = "NotifServiceRestarter"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "========================================")
        Log.d(TAG, "Notification service restart triggered")
        Log.d(TAG, "Action: ${intent.action}")
        
        // Request notification listener rebind
        try {
            val notifServiceIntent = Intent(
                "android.service.notification.NotificationListenerService"
            )
            notifServiceIntent.setPackage(context.packageName)
            context.startService(notifServiceIntent)
            
            Log.d(TAG, "✅ Service restart requested")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to restart service", e)
        }
        
        Log.d(TAG, "========================================")
    }
}