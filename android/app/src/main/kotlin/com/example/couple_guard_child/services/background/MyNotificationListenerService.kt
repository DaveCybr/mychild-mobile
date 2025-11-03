package com.example.couple_guard_child.services.background

import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import com.example.couple_guard_child.utils.ApiClient
import java.util.concurrent.Executors
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.*

class MyNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "NotifListenerService"
        var methodChannel: MethodChannel? = null
    }

    // ✅ FIX 1: Gunakan CoroutineScope untuk better lifecycle management
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    // ✅ FIX 2: Keep executor tapi dengan proper configuration
    private val executor = Executors.newFixedThreadPool(
        3,
        { runnable ->
            Thread(runnable).apply {
                isDaemon = false // Don't let threads die prematurely
                priority = Thread.NORM_PRIORITY
                name = "NotifSender-${System.currentTimeMillis()}"
            }
        }
    ) as ThreadPoolExecutor

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "========================================")
        Log.d(TAG, "📱 NOTIFICATION LISTENER SERVICE CREATED")
        Log.d(TAG, "PID: ${android.os.Process.myPid()}")
        Log.d(TAG, "Thread: ${Thread.currentThread().name}")
        Log.d(TAG, "========================================")
        
        // ✅ FIX 3: Configure executor
        executor.apply {
            setKeepAliveTime(60, TimeUnit.SECONDS)
            allowCoreThreadTimeOut(false)
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "========================================")
        Log.d(TAG, "✅ LISTENER CONNECTED")
        
        val isPaired = ApiClient.isPaired(applicationContext)
        val deviceId = ApiClient.getDeviceId(applicationContext)
        
        Log.d(TAG, "Device paired: $isPaired")
        Log.d(TAG, "Device ID: ${deviceId?.substring(0, 8) ?: "NULL"}...")
        Log.d(TAG, "Executor active threads: ${executor.activeCount}")
        Log.d(TAG, "Executor queue size: ${executor.queue.size}")
        Log.d(TAG, "========================================")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.w(TAG, "========================================")
        Log.w(TAG, "⚠️ LISTENER DISCONNECTED")
        Log.w(TAG, "Attempting to reconnect...")
        Log.w(TAG, "========================================")
        
        requestRebind(android.content.ComponentName(this, javaClass))
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val notificationId = "${sbn.packageName}-${sbn.postTime}"
        
        Log.d(TAG, "----------------------------------------")
        Log.d(TAG, "📱 NEW NOTIFICATION RECEIVED")
        Log.d(TAG, "ID: $notificationId")
        Log.d(TAG, "Thread: ${Thread.currentThread().name}")
        
        try {
            val packageName = sbn.packageName
            Log.d(TAG, "Package: $packageName")
            
            // ✅ FIX 4: Check pairing FIRST
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

            // Skip empty notifications
            if (title.isBlank() && text.isBlank()) {
                Log.w(TAG, "⏭️ SKIPPED: Empty title AND content")
                Log.d(TAG, "----------------------------------------")
                return
            }
            
            val finalTitle = if (title.isBlank()) packageName else title
            val finalContent = if (text.isBlank()) "New notification" else text

            // ✅ FIX 5: Check network before sending
            if (!isNetworkAvailable()) {
                Log.w(TAG, "⚠️ NO NETWORK - Notification will be queued")
                // TODO: Queue notification for later
                Log.d(TAG, "----------------------------------------")
                return
            }

            // ✅ FIX 6: Send with better error handling
            Log.d(TAG, "📤 Queuing notification to executor...")
            Log.d(TAG, "Executor queue size BEFORE: ${executor.queue.size}")
            Log.d(TAG, "Executor active threads: ${executor.activeCount}")
            
            executor.execute {
                sendToServerImmediate(
                    notificationId,
                    packageName, 
                    finalTitle, 
                    finalContent
                )
            }
            
            Log.d(TAG, "Executor queue size AFTER: ${executor.queue.size}")
            
            // Send to Flutter UI (non-blocking)
            sendToFlutter(packageName, finalTitle, finalContent, sbn.postTime)

        } catch (e: Exception) {
            Log.e(TAG, "❌ ERROR processing notification", e)
            e.printStackTrace()
        }
        
        Log.d(TAG, "----------------------------------------")
    }

    private fun sendToServerImmediate(
        notificationId: String,
        appName: String, 
        title: String, 
        content: String
    ) {
        // ✅ FIX 7: Better logging and error tracking
        val startTime = System.currentTimeMillis()
        val threadName = Thread.currentThread().name
        
        try {
            Log.d(TAG, "=== SENDING TO SERVER (IMMEDIATE) ===")
            Log.d(TAG, "Notification ID: $notificationId")
            Log.d(TAG, "Thread: $threadName")
            Log.d(TAG, "Executor stats:")
            Log.d(TAG, "  - Active threads: ${executor.activeCount}")
            Log.d(TAG, "  - Queue size: ${executor.queue.size}")
            Log.d(TAG, "  - Completed tasks: ${executor.completedTaskCount}")
            
            // ✅ FIX 8: Check network again before sending
            if (!isNetworkAvailable()) {
                Log.e(TAG, "❌ NETWORK LOST during send")
                return
            }
            
            // ✅ FIX 9: Check if device is still paired
            if (!ApiClient.isPaired(applicationContext)) {
                Log.e(TAG, "❌ Device unpaired during send")
                return
            }
            
            Log.d(TAG, "🚀 Making API call...")
            val success = ApiClient.sendNotification(
                applicationContext,
                appName,
                title,
                content
            )
            
            val duration = System.currentTimeMillis() - startTime
            
            if (success) {
                Log.d(TAG, "✅ SUCCESS: Notification sent in ${duration}ms")
                Log.d(TAG, "   App: $appName")
                Log.d(TAG, "   Title: $title")
            } else {
                Log.e(TAG, "❌ FAILED: Could not send notification (${duration}ms)")
                Log.e(TAG, "   This might be:")
                Log.e(TAG, "   - Server rejected request")
                Log.e(TAG, "   - Network timeout")
                Log.e(TAG, "   - Invalid device_id")
            }
            
            Log.d(TAG, "=== END SENDING (${duration}ms) ===")
            
        } catch (e: java.net.SocketTimeoutException) {
            Log.e(TAG, "❌ TIMEOUT: Server took too long", e)
        } catch (e: java.net.UnknownHostException) {
            Log.e(TAG, "❌ DNS ERROR: Cannot resolve hostname", e)
        } catch (e: java.net.ConnectException) {
            Log.e(TAG, "❌ CONNECTION ERROR: Cannot connect to server", e)
        } catch (e: javax.net.ssl.SSLException) {
            Log.e(TAG, "❌ SSL ERROR: Certificate problem", e)
        } catch (e: Exception) {
            Log.e(TAG, "❌ EXCEPTION sending to server", e)
            e.printStackTrace()
        } finally {
            val totalDuration = System.currentTimeMillis() - startTime
            Log.d(TAG, "⏱️ Total time in thread: ${totalDuration}ms")
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
                Log.w(TAG, "⚠️ MethodChannel is null, cannot send to Flutter")
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
                    Log.w(TAG, "Failed to send to Flutter: ${e.message}")
                }
            }
            
        } catch (e: Exception) {
            Log.w(TAG, "Exception in sendToFlutter: ${e.message}")
        }
    }

    // ✅ FIX 10: Add network check
    private fun isNetworkAvailable(): Boolean {
        return try {
            val connectivityManager = getSystemService(
                android.content.Context.CONNECTIVITY_SERVICE
            ) as android.net.ConnectivityManager
            
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                val network = connectivityManager.activeNetwork
                val capabilities = connectivityManager.getNetworkCapabilities(network)
                val hasNetwork = capabilities != null
                
                Log.d(TAG, "Network available: $hasNetwork")
                if (hasNetwork) {
                    Log.d(TAG, "Network type: ${
                        when {
                            capabilities!!.hasTransport(android.net.NetworkCapabilities.TRANSPORT_WIFI) -> "WIFI"
                            capabilities.hasTransport(android.net.NetworkCapabilities.TRANSPORT_CELLULAR) -> "CELLULAR"
                            else -> "OTHER"
                        }
                    }")
                }
                
                hasNetwork
            } else {
                @Suppress("DEPRECATION")
                val networkInfo = connectivityManager.activeNetworkInfo
                val isConnected = networkInfo?.isConnected == true
                Log.d(TAG, "Network available (legacy): $isConnected")
                isConnected
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking network", e)
            false
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.w(TAG, "========================================")
        Log.w(TAG, "⚠️ LISTENER DISCONNECTED")
        Log.w(TAG, "Attempting auto-reconnect...")
        Log.w(TAG, "========================================")
        
        // ✨ Method 1: Request rebind (Android N+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                requestRebind(android.content.ComponentName(this, javaClass))
                Log.d(TAG, "✅ Rebind requested via API")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to request rebind", e)
            }
        }
        
        // ✨ Method 2: Schedule delayed restart
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            try {
                Log.d(TAG, "Attempting manual reconnect...")
                
                // Restart service
                val intent = Intent(this, MyNotificationListenerService::class.java)
                startService(intent)
                
                Log.d(TAG, "✅ Manual reconnect attempted")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed manual reconnect", e)
            }
        }, 5000) // Wait 5 seconds
        
        // ✨ Method 3: Broadcast ke RestartServiceReceiver
        try {
            val broadcastIntent = Intent(
                "com.example.couple_guard_child.ACTION_REBIND_NOTIFICATION_LISTENER"
            )
            broadcastIntent.setPackage(packageName)
            sendBroadcast(broadcastIntent)
            
            Log.d(TAG, "✅ Rebind broadcast sent")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to send rebind broadcast", e)
        }
    }


    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.w(TAG, "========================================")
        Log.w(TAG, "⚠️ TASK REMOVED - App swiped from recent")
        Log.w(TAG, "Service will auto-reconnect...")
        Log.w(TAG, "========================================")
        
        // ✨ Request rebind saat task removed
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                requestRebind(android.content.ComponentName(this, javaClass))
                Log.d(TAG, "✅ Rebind requested after task removed")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to rebind", e)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.w(TAG, "========================================")
        Log.w(TAG, "⚠️ SERVICE DESTROYED")
        Log.w(TAG, "Shutting down executor...")
        Log.w(TAG, "Remaining tasks: ${executor.queue.size}")
        Log.w(TAG, "========================================")
        
        try {
            // ✅ FIX 11: Graceful shutdown
            serviceScope.cancel()
            
            executor.shutdown()
            if (!executor.awaitTermination(10, TimeUnit.SECONDS)) {
                Log.w(TAG, "⚠️ Executor did not terminate in time, forcing shutdown")
                executor.shutdownNow()
            }
            Log.d(TAG, "✅ Executor shutdown complete")
        } catch (e: Exception) {
            Log.e(TAG, "Error shutting down executor", e)
            executor.shutdownNow()
        }
    }
}