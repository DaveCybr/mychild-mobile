package com.example.couple_guard_child.services

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.example.couple_guard_child.receivers.RestartServiceReceiver

/**
 * ServiceKeepAliveManager - ENHANCED VERSION
 * Triple redundancy system untuk keep service alive
 */
object ServiceKeepAliveManager {
    private const val TAG = "ServiceKeepAlive"
    
    // Multiple alarms untuk redundancy
    private const val ALARM_1_CODE = 1001
    private const val ALARM_2_CODE = 1002
    private const val ALARM_3_CODE = 1003
    
    private const val INTERVAL_1 = 15 * 60 * 1000L // 15 minutes
    private const val INTERVAL_2 = 20 * 60 * 1000L // 20 minutes
    private const val INTERVAL_3 = 25 * 60 * 1000L // 25 minutes

    /**
     * Schedule TRIPLE redundant alarms
     */
    fun scheduleServiceCheck(context: Context) {
        Log.d(TAG, "========================================")
        Log.d(TAG, "⏰ SCHEDULING TRIPLE REDUNDANT ALARMS")
        
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            // ✅ Alarm 1 - Primary (15 min)
            scheduleAlarm(context, alarmManager, ALARM_1_CODE, INTERVAL_1, "Primary")
            
            // ✅ Alarm 2 - Secondary (20 min) 
            scheduleAlarm(context, alarmManager, ALARM_2_CODE, INTERVAL_2, "Secondary")
            
            // ✅ Alarm 3 - Tertiary (25 min)
            scheduleAlarm(context, alarmManager, ALARM_3_CODE, INTERVAL_3, "Tertiary")
            
            Log.d(TAG, "✅ All 3 alarms scheduled successfully")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to schedule alarms", e)
        }
        
        Log.d(TAG, "========================================")
    }

    private fun scheduleAlarm(
        context: Context,
        alarmManager: AlarmManager,
        requestCode: Int,
        interval: Long,
        name: String
    ) {
        val intent = Intent(context, RestartServiceReceiver::class.java).apply {
            action = "com.example.couple_guard_child.ACTION_CHECK_SERVICE"
            putExtra("alarm_name", name)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )
        
        // Cancel existing
        alarmManager.cancel(pendingIntent)
        
        val triggerAt = System.currentTimeMillis() + interval
        
        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                // Android 6.0+ - Doze compatible
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    pendingIntent
                )
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT -> {
                // Android 4.4+
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    pendingIntent
                )
            }
            else -> {
                // Android < 4.4
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    pendingIntent
                )
            }
        }
        
        Log.d(TAG, "✅ $name alarm scheduled (${interval / 60000} min)")
    }

    /**
     * Cancel all alarms
     */
    fun cancelServiceCheck(context: Context) {
        Log.d(TAG, "Cancelling all keep-alive alarms...")
        
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            // Cancel all 3 alarms
            for (code in listOf(ALARM_1_CODE, ALARM_2_CODE, ALARM_3_CODE)) {
                val intent = Intent(context, RestartServiceReceiver::class.java)
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    code,
                    intent,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    } else {
                        PendingIntent.FLAG_UPDATE_CURRENT
                    }
                )
                
                alarmManager.cancel(pendingIntent)
            }
            
            Log.d(TAG, "✅ All alarms cancelled")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to cancel alarms", e)
        }
    }

    /**
     * Check if at least one alarm is scheduled
     */
    fun isAlarmScheduled(context: Context): Boolean {
        return try {
            for (code in listOf(ALARM_1_CODE, ALARM_2_CODE, ALARM_3_CODE)) {
                val intent = Intent(context, RestartServiceReceiver::class.java)
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    code,
                    intent,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
                    } else {
                        PendingIntent.FLAG_NO_CREATE
                    }
                )
                
                if (pendingIntent != null) {
                    return true
                }
            }
            false
        } catch (e: Exception) {
            Log.e(TAG, "Error checking alarm status", e)
            false
        }
    }
}