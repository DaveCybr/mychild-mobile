package com.example.couple_guard_child

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
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
    
    // ✅ CRITICAL: Notification Channel IDs (MUST match background_service_manager.dart)
    companion object {
        const val NOTIFICATION_CHANNEL_ID = "child_app_background"
        const val NOTIFICATION_CHANNEL_NAME = "Background Service"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "========================================")
        Log.d(TAG, "MainActivity onCreate()")
        
        // ✅ STEP 1: Create notification channel BEFORE service starts
        createNotificationChannel()
        
        Log.d(TAG, "Notification channel created")
        Log.d(TAG, "========================================")
    }

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
    
    /**
     * ✅ CRITICAL FIX: Create notification channel for foreground service
     * This MUST be called before starting the background service
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                
                // Check if channel already exists
                val existingChannel = notificationManager.getNotificationChannel(NOTIFICATION_CHANNEL_ID)
                
                if (existingChannel == null) {
                    Log.d(TAG, "Creating notification channel: $NOTIFICATION_CHANNEL_ID")
                    
                    val channel = NotificationChannel(
                        NOTIFICATION_CHANNEL_ID,
                        NOTIFICATION_CHANNEL_NAME,
                        NotificationManager.IMPORTANCE_LOW // LOW = tidak ada suara
                    ).apply {
                        description = "Keeps the app running in background for family safety"
                        setShowBadge(false)
                        enableLights(false)
                        enableVibration(false)
                        setSound(null, null) // No sound
                    }
                    
                    notificationManager.createNotificationChannel(channel)
                    
                    Log.d(TAG, "✅ Notification channel created successfully")
                } else {
                    Log.d(TAG, "✅ Notification channel already exists")
                }
                
                // Verify channel exists
                val verifyChannel = notificationManager.getNotificationChannel(NOTIFICATION_CHANNEL_ID)
                if (verifyChannel != null) {
                    Log.d(TAG, "✅ Channel verification PASSED")
                    Log.d(TAG, "   - ID: ${verifyChannel.id}")
                    Log.d(TAG, "   - Name: ${verifyChannel.name}")
                    Log.d(TAG, "   - Importance: ${verifyChannel.importance}")
                } else {
                    Log.e(TAG, "❌ Channel verification FAILED!")
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to create notification channel", e)
            }
        } else {
            Log.d(TAG, "Android version < O, notification channel not required")
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