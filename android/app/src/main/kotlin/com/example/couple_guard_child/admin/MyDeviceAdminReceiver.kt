package com.example.couple_guard_child.admin

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Device Admin Receiver
 * Memberikan proteksi dari uninstall dan force stop
 * (Optional - untuk parental control yang lebih strict)
 */
class MyDeviceAdminReceiver : DeviceAdminReceiver() {
    companion object {
        private const val TAG = "DeviceAdminReceiver"
    }

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d(TAG, "========================================")
        Log.d(TAG, "✅ DEVICE ADMIN ENABLED")
        Log.d(TAG, "App is now protected from uninstall")
        Log.d(TAG, "========================================")
        
        // Save admin status
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("flutter.device_admin_enabled", true)
            .apply()
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.d(TAG, "========================================")
        Log.d(TAG, "⚠️ DEVICE ADMIN DISABLED")
        Log.d(TAG, "App can now be uninstalled")
        Log.d(TAG, "========================================")
        
        // Save admin status
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("flutter.device_admin_enabled", false)
            .apply()
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        Log.d(TAG, "⚠️ User trying to disable Device Admin")
        
        // Return warning message
        return "Disabling device admin will stop family safety protection. Continue?"
    }
}