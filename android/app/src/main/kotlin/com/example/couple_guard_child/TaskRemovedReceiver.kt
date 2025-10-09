package com.example.couple_guard_child

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Receiver untuk restart service ketika user swipe close app
 * CRITICAL untuk keep service running
 */
class TaskRemovedReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "TaskRemovedReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            Log.d(TAG, "========================================")
            Log.d(TAG, "DEVICE REBOOTED - Checking pairing status")

            try {
                val prefs = context.getSharedPreferences(
                    "FlutterSharedPreferences",
                    Context.MODE_PRIVATE
                )
                val isPaired = prefs.getBoolean("flutter.is_paired", false)
                val deviceId = prefs.getString("flutter.device_id", null)

                Log.d(TAG, "Paired: $isPaired, Device ID: $deviceId")

                if (isPaired && !deviceId.isNullOrEmpty()) {
                    Log.d(TAG, "✅ Device is paired - Restarting service")
                    restartService(context)
                } else {
                    Log.d(TAG, "❌ Device not paired - Skip restart")
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error in TaskRemovedReceiver", e)
            }

            Log.d(TAG, "========================================")
        }
    }

    private fun restartService(context: Context) {
        val serviceIntent = Intent(
            context,
            id.flutter.flutter_background_service.BackgroundService::class.java
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
            Log.d(TAG, "Started foreground service")
        } else {
            context.startService(serviceIntent)
            Log.d(TAG, "Started service")
        }
    }
}