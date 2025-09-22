package com.example.my_child

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class DeviceAdminReceiver : DeviceAdminReceiver() {
    
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d("DeviceAdmin", "Device admin enabled")
        
        // Notify Flutter that device admin is enabled
        val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        sharedPrefs.edit()
            .putBoolean("flutter.device_admin_permission_status", true)
            .apply()
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.d("DeviceAdmin", "Device admin disabled")
        
        // Notify Flutter that device admin is disabled
        val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        sharedPrefs.edit()
            .putBoolean("flutter.device_admin_permission_status", false)
            .apply()
    }

    override fun onPasswordFailed(context: Context, intent: Intent, user: android.os.UserHandle) {
        super.onPasswordFailed(context, intent, user)
        Log.d("DeviceAdmin", "Password failed")
    }

    override fun onPasswordSucceeded(context: Context, intent: Intent, user: android.os.UserHandle) {
        super.onPasswordSucceeded(context, intent, user)
        Log.d("DeviceAdmin", "Password succeeded")
    }
}
