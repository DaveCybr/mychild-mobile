package com.example.couple_guard_child.services

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import com.example.couple_guard_child.utils.ApiClient
import java.io.File
import java.io.FileOutputStream

class ScreenCaptureBackgroundService : Service() {
    companion object {
        private const val TAG = "ScreenCaptureService"
        private const val NOTIFICATION_ID = 2002
        private const val CHANNEL_ID = "screen_capture_channel"
        
        // ✅ Static variables to hold permission
        private var mediaProjectionResultCode: Int? = null
        private var mediaProjectionData: Intent? = null
        private var hasPermission = false

        // ✅ PREFS constants (must match ScreenCapturePermissionActivity)
        private const val PREFS_NAME = "ScreenCapturePrefs"
        private const val KEY_RESULT_CODE = "screen_capture_result_code"
        private const val KEY_RESULT_DATA = "screen_capture_result_data"
        private const val KEY_PERMISSION_GRANTED = "screen_capture_permission_granted"

        /**
         * Load MediaProjection permission from SharedPreferences
         * MUST be called before starting capture
         */
        fun loadPermissionFromPrefs(context: Context): Boolean {
            try {
                Log.d(TAG, "========================================")
                Log.d(TAG, "🔍 LOADING MEDIAPROJECTION PERMISSION")
                
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val rc = prefs.getInt(KEY_RESULT_CODE, -1)
                val dataUri = prefs.getString(KEY_RESULT_DATA, null)
                val granted = prefs.getBoolean(KEY_PERMISSION_GRANTED, false)

                Log.d(TAG, "Result code: $rc")
                Log.d(TAG, "Data URI exists: ${dataUri != null}")
                Log.d(TAG, "Permission granted flag: $granted")

                if (!granted || rc == -1 || dataUri == null) {
                    Log.e(TAG, "❌ Permission not saved or incomplete")
                    Log.d(TAG, "========================================")
                    hasPermission = false
                    return false
                }

                try {
                    // ✅ Parse Intent from URI
                    val intent = Intent.parseUri(dataUri, 0)
                    
                    // ✅ Save to static variables
                    mediaProjectionResultCode = rc
                    mediaProjectionData = intent
                    hasPermission = true
                    
                    Log.d(TAG, "✅ MediaProjection permission loaded successfully")
                    Log.d(TAG, "Result code: $rc")
                    Log.d(TAG, "========================================")
                    return true
                    
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Failed to parse MediaProjection intent", e)
                    e.printStackTrace()
                    hasPermission = false
                    return false
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error loading MediaProjection permission", e)
                e.printStackTrace()
                Log.d(TAG, "========================================")
                hasPermission = false
                return false
            }
        }

        /**
         * Start screen capture service
         * Permission MUST be loaded first!
         */
        fun startCapture(context: Context) {
            Log.d(TAG, "========================================")
            Log.d(TAG, "🖥️ START SCREEN CAPTURE REQUEST")
            
            // ✅ Double-check permission is loaded
            if (!hasPermission) {
                Log.w(TAG, "⚠️ Permission not in memory, loading from prefs...")
                val loaded = loadPermissionFromPrefs(context)
                if (!loaded) {
                    Log.e(TAG, "❌ Cannot start: No MediaProjection permission")
                    Log.e(TAG, "User must open app and grant permission first")
                    Log.d(TAG, "========================================")
                    return
                }
            }
            
            // ✅ Verify we have both code and data
            if (mediaProjectionResultCode == null || mediaProjectionData == null) {
                Log.e(TAG, "❌ Permission data incomplete")
                Log.e(TAG, "Result code: $mediaProjectionResultCode")
                Log.e(TAG, "Data: ${mediaProjectionData != null}")
                Log.d(TAG, "========================================")
                return
            }

            Log.d(TAG, "✅ Permission verified, starting service...")
            
            val intent = Intent(context, ScreenCaptureBackgroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            
            Log.d(TAG, "========================================")
        }
        
        /**
         * Save permission (called by ScreenCapturePermissionActivity)
         */
        fun savePermission(resultCode: Int, data: Intent) {
            mediaProjectionResultCode = resultCode
            mediaProjectionData = data
            hasPermission = true
            Log.d(TAG, "✅ MediaProjection permission saved to memory")
        }
        
        /**
         * Check if permission is available
         */
        fun hasPermission(context: Context): Boolean {
            if (hasPermission) return true
            return loadPermissionFromPrefs(context)
        }
    }

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private val handler = Handler(Looper.getMainLooper())
    private var captureAttempted = false

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "========================================")
        Log.d(TAG, "🖥️ ScreenCaptureBackgroundService created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "========================================")
        Log.d(TAG, "🖥️ SCREEN CAPTURE SERVICE START")

        // ✅ CRITICAL: Start foreground IMMEDIATELY
        try {
            startForeground(NOTIFICATION_ID, createNotification("Preparing screen capture..."))
            Log.d(TAG, "✅ Started as foreground service")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start foreground", e)
            stopSelfSafely()
            return START_NOT_STICKY
        }

        // ✅ Verify permission one more time
        if (!hasPermission) {
            Log.w(TAG, "⚠️ Permission lost, reloading...")
            val loaded = loadPermissionFromPrefs(applicationContext)
            if (!loaded) {
                Log.e(TAG, "❌ Cannot proceed without permission")
                stopSelfSafely()
                return START_NOT_STICKY
            }
        }

        if (mediaProjectionResultCode == null || mediaProjectionData == null) {
            Log.e(TAG, "❌ Permission data is null")
            stopSelfSafely()
            return START_NOT_STICKY
        }

        Log.d(TAG, "✅ Permission verified")
        Log.d(TAG, "Result code: $mediaProjectionResultCode")

        // ✅ Small delay to ensure service is stable
        handler.postDelayed({
            if (!captureAttempted) {
                captureScreen()
            }
        }, 500)

        return START_NOT_STICKY
    }

    private fun captureScreen() {
        captureAttempted = true
        
        try {
            Log.d(TAG, "Initializing MediaProjection...")
            updateNotification("Initializing...")
            
            val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) 
                as MediaProjectionManager
            
            // ✅ Create MediaProjection with saved permission
            mediaProjection = projectionManager.getMediaProjection(
                mediaProjectionResultCode!!,
                mediaProjectionData!!
            )
            
            if (mediaProjection == null) {
                Log.e(TAG, "❌ Failed to create MediaProjection")
                Log.e(TAG, "Permission might have expired or been revoked")
                
                // ✅ Clear saved permission
                clearPermission()
                stopSelfSafely()
                return
            }
            
            Log.d(TAG, "✅ MediaProjection created")
            
            // ✅ Register callback to detect when permission is revoked
            mediaProjection?.registerCallback(object : MediaProjection.Callback() {
                override fun onStop() {
                    Log.w(TAG, "⚠️ MediaProjection stopped by system")
                    clearPermission()
                }
            }, handler)
            
            updateNotification("Getting screen dimensions...")
            
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val metrics = DisplayMetrics()
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val display = windowManager.defaultDisplay
                display?.getRealMetrics(metrics)
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay.getRealMetrics(metrics)
            }
            
            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val density = metrics.densityDpi
            
            Log.d(TAG, "Screen dimensions: ${width}x${height} @ ${density}dpi")
            
            updateNotification("Creating virtual display...")
            
            // ✅ Create ImageReader
            imageReader = ImageReader.newInstance(
                width, 
                height, 
                PixelFormat.RGBA_8888, 
                2
            )
            
            // ✅ Create VirtualDisplay
            virtualDisplay = mediaProjection!!.createVirtualDisplay(
                "ScreenCapture",
                width,
                height,
                density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader!!.surface,
                null,
                handler
            )
            
            if (virtualDisplay == null) {
                Log.e(TAG, "❌ Failed to create VirtualDisplay")
                stopSelfSafely()
                return
            }
            
            Log.d(TAG, "✅ VirtualDisplay created")
            updateNotification("Capturing screen...")
            
            // ✅ Wait for frame to be available
            handler.postDelayed({
                captureImage()
            }, 500)
            
        } catch (e: SecurityException) {
            Log.e(TAG, "❌ SecurityException - Permission revoked?", e)
            clearPermission()
            stopSelfSafely()
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to capture screen", e)
            e.printStackTrace()
            stopSelfSafely()
        }
    }

    private fun captureImage() {
        try {
            Log.d(TAG, "Acquiring image from ImageReader...")
            updateNotification("Processing image...")
            
            val image = imageReader?.acquireLatestImage()
            
            if (image == null) {
                Log.e(TAG, "❌ No image available")
                
                // ✅ Retry once
                handler.postDelayed({
                    val retryImage = imageReader?.acquireLatestImage()
                    if (retryImage != null) {
                        processImage(retryImage)
                        retryImage.close()
                    } else {
                        Log.e(TAG, "❌ Retry failed, no image")
                        stopSelfSafely()
                    }
                }, 1000)
                return
            }
            
            Log.d(TAG, "✅ Image acquired: ${image.width}x${image.height}")
            processImage(image)
            image.close()
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to capture image", e)
            e.printStackTrace()
            stopSelfSafely()
        }
    }

    private fun processImage(image: android.media.Image) {
        try {
            val planes = image.planes
            val buffer = planes[0].buffer
            val pixelStride = planes[0].pixelStride
            val rowStride = planes[0].rowStride
            val rowPadding = rowStride - pixelStride * image.width
            
            // ✅ Create bitmap with padding
            val bitmap = Bitmap.createBitmap(
                image.width + rowPadding / pixelStride,
                image.height,
                Bitmap.Config.ARGB_8888
            )
            
            bitmap.copyPixelsFromBuffer(buffer)
            
            Log.d(TAG, "✅ Bitmap created: ${bitmap.width}x${bitmap.height}")
            
            saveAndSend(bitmap)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to process image", e)
            e.printStackTrace()
            stopSelfSafely()
        }
    }

    private fun saveAndSend(bitmap: Bitmap) {
        try {
            Log.d(TAG, "Saving screenshot...")
            updateNotification("Saving screenshot...")
            
            val file = File(cacheDir, "screenshot_${System.currentTimeMillis()}.jpg")
            
            FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
            }
            
            bitmap.recycle()
            
            Log.d(TAG, "✅ Screenshot saved: ${file.path}")
            Log.d(TAG, "Size: ${file.length() / 1024} KB")
            
            updateNotification("Uploading...")
            
            // ✅ Upload in background thread
            Thread {
                try {
                    val success = ApiClient.uploadScreenshot(
                        applicationContext,
                        file
                    )
                    
                    if (success) {
                        Log.d(TAG, "✅ Screenshot uploaded successfully")
                    } else {
                        Log.e(TAG, "❌ Failed to upload screenshot")
                    }
                    
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Exception uploading screenshot", e)
                } finally {
                    try {
                        file.delete()
                        Log.d(TAG, "✅ Temp file deleted")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to delete temp file", e)
                    }
                }
            }.start()
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to save screenshot", e)
            e.printStackTrace()
        } finally {
            stopSelfSafely()
        }
    }

    private fun cleanup() {
        try {
            virtualDisplay?.release()
            virtualDisplay = null
            
            imageReader?.close()
            imageReader = null
            
            mediaProjection?.stop()
            mediaProjection = null
            
            Log.d(TAG, "✅ Resources cleaned up")
        } catch (e: Exception) {
            Log.e(TAG, "Error cleaning up", e)
        }
    }
    
    private fun clearPermission() {
        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().clear().apply()
            
            hasPermission = false
            mediaProjectionResultCode = null
            mediaProjectionData = null
            
            Log.d(TAG, "🗑️ Permission cleared")
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing permission", e)
        }
    }

    private fun stopSelfSafely() {
        handler.postDelayed({
            try {
                cleanup()
                stopForeground(true)
                stopSelf()
                Log.d(TAG, "✅ Service stopped")
                Log.d(TAG, "========================================")
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping service", e)
            }
        }, 1000)
    }

    private fun updateNotification(message: String) {
        try {
            val notification = createNotification(message)
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update notification", e)
        }
    }

    private fun createNotification(message: String): Notification {
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Screen Capture")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_menu_gallery)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setAutoCancel(false)
            .setOngoing(true)

        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Screen Capture",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for screen capture operations"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
            
            Log.d(TAG, "✅ Notification channel created")
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        cleanup()
        Log.d(TAG, "Service destroyed")
    }
}