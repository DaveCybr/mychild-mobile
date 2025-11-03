package com.example.couple_guard_child.services.background

import android.content.Context
import android.util.Log
import com.example.couple_guard_child.utils.ApiClient
import kotlinx.coroutines.*
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicBoolean
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * NotificationQueueManager
 * Queue system untuk handle notification yang gagal terkirim
 */
object NotificationQueueManager {
    private const val TAG = "NotifQueueManager"
    private const val MAX_QUEUE_SIZE = 100
    private const val RETRY_DELAY_MS = 5000L
    
    private val queue = ConcurrentLinkedQueue<QueuedNotification>()
    private val isProcessing = AtomicBoolean(false)
    private var processingJob: Job? = null
    
    data class QueuedNotification(
        val id: String,
        val appName: String,
        val title: String,
        val content: String,
        val timestamp: Long,
        var retryCount: Int = 0
    )
    
    /**
     * Add notification to queue
     */
    fun enqueue(
        id: String,
        appName: String,
        title: String,
        content: String
    ) {
        if (queue.size >= MAX_QUEUE_SIZE) {
            Log.w(TAG, "⚠️ Queue full, removing oldest notification")
            queue.poll() // Remove oldest
        }
        
        val notification = QueuedNotification(
            id, appName, title, content, System.currentTimeMillis()
        )
        
        queue.offer(notification)
        Log.d(TAG, "➕ Notification queued. Queue size: ${queue.size}")
        
        // Start processing if not already running
        startProcessing()
    }
    
    /**
     * Start processing queue
     */
    private fun startProcessing() {
        if (isProcessing.compareAndSet(false, true)) {
            processingJob = CoroutineScope(Dispatchers.IO).launch {
                processQueue()
            }
        }
    }
    
    /**
     * Process queue
     */
    private suspend fun processQueue() {
        Log.d(TAG, "🔄 Starting queue processing...")
        
        while (queue.isNotEmpty()) {
            val notification = queue.peek() ?: break
            
            try {
                Log.d(TAG, "📤 Sending queued notification (attempt ${notification.retryCount + 1})")
                
                // Try to send
                val success = withContext(Dispatchers.IO) {
                    ApiClient.sendNotification(
                        // Need context here - will fix in implementation
                        // For now, just return false
                        false
                    )
                }
                
                if (success) {
                    queue.poll() // Remove from queue
                    Log.d(TAG, "✅ Queued notification sent. Remaining: ${queue.size}")
                } else {
                    notification.retryCount++
                    
                    if (notification.retryCount >= 3) {
                        queue.poll() // Remove after 3 failed attempts
                        Log.e(TAG, "❌ Notification failed after 3 attempts, discarding")
                    } else {
                        Log.w(TAG, "⚠️ Notification send failed, will retry")
                        delay(RETRY_DELAY_MS)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing notification", e)
                notification.retryCount++
                
                if (notification.retryCount >= 3) {
                    queue.poll()
                }
                
                delay(RETRY_DELAY_MS)
            }
        }
        
        isProcessing.set(false)
        Log.d(TAG, "✅ Queue processing completed")
    }
    
    /**
     * Get queue status
     */
    fun getQueueStatus(): String {
        return "Queue size: ${queue.size}, Processing: ${isProcessing.get()}"
    }
    
    /**
     * Clear queue
     */
    fun clear() {
        queue.clear()
        processingJob?.cancel()
        isProcessing.set(false)
        Log.d(TAG, "🗑️ Queue cleared")
    }
}

/**
 * IMPROVED NotificationListenerService with Queue
 */
class MyNotificationListenerServiceV2 : NotificationListenerService() {
    companion object {
        private const val TAG = "NotifListenerV2"
    }
    
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val notificationId = "${sbn.packageName}-${sbn.postTime}"
        
        Log.d(TAG, "📱 NEW NOTIFICATION: $notificationId")
        
        try {
            // Check pairing
            if (!com.example.couple_guard_child.utils.ApiClient.isPaired(applicationContext)) {
                Log.w(TAG, "⚠️ Device not paired, skipping")
                return
            }
            
            val packageName = sbn.packageName
            val notification = sbn.notification
            val extras = notification.extras
            
            val title = extras.getCharSequence("android.title")?.toString() ?: ""
            val text = extras.getCharSequence("android.text")?.toString() ?: ""
            
            if (title.isBlank() && text.isBlank()) {
                Log.w(TAG, "⏭️ SKIPPED: Empty notification")
                return
            }
            
            val finalTitle = if (title.isBlank()) packageName else title
            val finalContent = if (text.isBlank()) "New notification" else text
            
            // ✅ Try immediate send
            serviceScope.launch {
                try {
                    val success = com.example.couple_guard_child.utils.ApiClient.sendNotification(
                        applicationContext,
                        packageName,
                        finalTitle,
                        finalContent
                    )
                    
                    if (!success) {
                        // ✅ Add to queue if failed
                        Log.w(TAG, "⚠️ Immediate send failed, adding to queue")
                        NotificationQueueManager.enqueue(
                            notificationId,
                            packageName,
                            finalTitle,
                            finalContent
                        )
                    } else {
                        Log.d(TAG, "✅ Notification sent immediately")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error sending notification", e)
                    NotificationQueueManager.enqueue(
                        notificationId,
                        packageName,
                        finalTitle,
                        finalContent
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error processing notification", e)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        Log.d(TAG, "Service destroyed, scope cancelled")
    }
}