package com.example.couple_guard_child

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.couple_guard_child.services.background.MyNotificationListenerService

class MainActivity: FlutterActivity() {
    private val CHANNEL = "notification_listener_channel"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "Configuring Flutter Engine")
        
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, 
            CHANNEL
        )
        
        // Set static reference untuk NotificationListenerService
        MyNotificationListenerService.methodChannel = channel
        Log.d(TAG, "MethodChannel registered and set to NotificationListenerService")
        
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkNotificationPermission" -> {
                    val enabled = isNotificationServiceEnabled()
                    Log.d(TAG, "Permission check result: $enabled")
                    result.success(enabled)
                }
                "openNotificationSettings" -> {
                    openNotificationListenerSettings()
                    result.success(null)
                }
                "minimizeApp" -> {
                    moveTaskToBack(true)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )
        
        if (!flat.isNullOrEmpty()) {
            val enabled = flat.contains(pkgName)
            Log.d(TAG, "Notification listener enabled: $enabled")
            return enabled
        }
        
        Log.d(TAG, "Notification listener settings is null or empty")
        return false
    }

    private fun openNotificationListenerSettings() {
        Log.d(TAG, "Opening notification listener settings")
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "MainActivity resumed")
    }

    override fun onPause() {
        super.onPause()
        Log.d(TAG, "MainActivity paused")
    }
}