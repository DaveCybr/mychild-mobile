package com.example.couple_guard_child.services

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.example.couple_guard_child.receivers.RestartServiceReceiver

/**
 * ServiceKeepAliveManager
 * Menggunakan AlarmManager untuk memastikan service restart secara periodik
 */
object ServiceKeepAliveManager {
    private const val TAG = "ServiceKeepAlive"
    private const val REQUEST_CODE = 1001
    private const val INTERVAL_MILLIS = 15 * 60 * 1000L // 15 minutes

    /**
     * Schedule alarm untuk check & restart service
     */
    fun scheduleServiceCheck(context: Context) {
        Log.d(TAG, "========================================")
        Log.d(TAG, "⏰ SCHEDULING SERVICE KEEP-ALIVE")
        Log.d(TAG, "Interval: 15 minutes")
        
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, RestartServiceReceiver::class.java)
            intent.action = "com.example.couple_guard_child.ACTION_CHECK_SERVICE"
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
            )
            
            // Cancel existing alarm
            alarmManager.cancel(pendingIntent)
            
            val triggerAtMillis = System.currentTimeMillis() + INTERVAL_MILLIS
            
            // Use setRepeating untuk regular check
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // Android M+ - use setExactAndAllowWhileIdle for Doze mode
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
                
                Log.d(TAG, "✅ Alarm scheduled (exact, doze-compatible)")
            } else {
                // Android L and below
                alarmManager.setRepeating(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    INTERVAL_MILLIS,
                    pendingIntent
                )
                
                Log.d(TAG, "✅ Alarm scheduled (repeating)")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to schedule alarm", e)
        }
        
        Log.d(TAG, "========================================")
    }

    /**
     * Cancel scheduled alarm
     */
    fun cancelServiceCheck(context: Context) {
        Log.d(TAG, "Cancelling service keep-alive alarm...")
        
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, RestartServiceReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
            )
            
            alarmManager.cancel(pendingIntent)
            
            Log.d(TAG, "✅ Alarm cancelled")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to cancel alarm", e)
        }
    }

    /**
     * Check if alarm is scheduled
     */
    fun isAlarmScheduled(context: Context): Boolean {
        return try {
            val intent = Intent(context, RestartServiceReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_NO_CREATE
                }
            )
            
            pendingIntent != null
        } catch (e: Exception) {
            Log.e(TAG, "Error checking alarm status", e)
            false
        }
    }
}