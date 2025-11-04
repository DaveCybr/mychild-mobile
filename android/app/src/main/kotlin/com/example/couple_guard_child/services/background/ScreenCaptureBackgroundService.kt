package com.example.couple_guard_child.services

import android.app.*
import android.content.Context
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
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import com.example.couple_guard_child.R
import com.example.couple_guard_child.utils.ApiClient
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer


class ScreenCaptureBackgroundService : Service() {
    companion object {
        private const val TAG = "ScreenCaptureService"
        private const val NOTIFICATION_ID = 2002
        private const val CHANNEL_ID = "screen_capture_channel"
        
        var mediaProjectionResultCode: Int? = null
        var mediaProjectionData: Intent? = null
        var hasPermission = false

        fun loadPermissionFromPrefs(context: Context): Boolean {
            try {
                val prefs = context.getSharedPreferences("ScreenCapturePrefs", Context.MODE_PRIVATE)
                val rc = prefs.getInt("screen_capture_result_code", -1)
                val dataUri = prefs.getString("screen_capture_result_data", null)
                val granted = prefs.getBoolean("screen_capture_permission_granted", false)

                if (granted && rc != -1 && dataUri != null) {
                    try {
                        val intent = Intent.parseUri(dataUri, 0)
                        mediaProjectionResultCode = rc
                        mediaProjectionData = intent
                        hasPermission = true
                        Log.d(TAG, "✅ Loaded MediaProjection permission from prefs")
                        return true
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Failed to parse saved MediaProjection intent", e)
                        hasPermission = false
                        return false
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error loading MediaProjection prefs", e)
            }
            hasPermission = false
            return false
        }

        fun startCapture(context: Context) {
            // attempt to load permission from prefs if not already in-memory
            if (!hasPermission) {
                loadPermissionFromPrefs(context)
            }

            if (!hasPermission) {
                Log.e(TAG, "❌ startCapture called but no saved MediaProjection permission")
                // optionally notify user to open app and grant permission
                return
            }

            val intent = Intent(context, ScreenCaptureBackgroundService::class.java)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun savePermission(resultCode: Int, data: Intent) {
            mediaProjectionResultCode = resultCode
            mediaProjectionData = data
            hasPermission = true
            Log.d(TAG, "✅ MediaProjection permission saved")
        }
    }

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "========================================")
        Log.d(TAG, "🖥️ BACKGROUND SCREENSHOT START")

        // Ensure permission loaded (handle cases where static vars lost)
        if (!hasPermission) {
            val loaded = loadPermissionFromPrefs(applicationContext)
            if (!loaded) {
                Log.e(TAG, "❌ No MediaProjection permission! User must approve screen capture in app first")
                stopSelfSafely()
                return START_NOT_STICKY
            }
        }

        // Only after confirming permission, call startForeground
        startForeground(NOTIFICATION_ID, createNotification("Capturing screen..."))

        // Proceed with capture
        captureScreen()
        return START_NOT_STICKY
    }


    private fun captureScreen() {
        try {
            Log.d(TAG, "Initializing MediaProjection...")
            
            val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) 
                as MediaProjectionManager
            
            mediaProjection = projectionManager.getMediaProjection(
                mediaProjectionResultCode!!,
                mediaProjectionData!!
            )
            
            if (mediaProjection == null) {
                Log.e(TAG, "❌ Failed to create MediaProjection")
                stopSelfSafely()
                return
            }
            
            Log.d(TAG, "✅ MediaProjection created")
            
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
            
            Log.d(TAG, "Screen: ${width}x${height} @ ${density}dpi")
            
            imageReader = ImageReader.newInstance(
                width, 
                height, 
                PixelFormat.RGBA_8888, 
                2
            )
            
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
            
            Log.d(TAG, "✅ VirtualDisplay created")
            
            handler.postDelayed({
                captureImage()
            }, 500)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to capture screen", e)
            stopSelfSafely()
        }
    }

    private fun captureImage() {
        try {
            Log.d(TAG, "Acquiring image from ImageReader...")
            
            val image = imageReader?.acquireLatestImage()
            
            if (image == null) {
                Log.e(TAG, "❌ No image available")
                stopSelfSafely()
                return
            }
            
            Log.d(TAG, "✅ Image acquired: ${image.width}x${image.height}")
            
            val planes = image.planes
            val buffer = planes[0].buffer
            val pixelStride = planes[0].pixelStride
            val rowStride = planes[0].rowStride
            val rowPadding = rowStride - pixelStride * image.width
            
            val bitmap = Bitmap.createBitmap(
                image.width + rowPadding / pixelStride,
                image.height,
                Bitmap.Config.ARGB_8888
            )
            
            bitmap.copyPixelsFromBuffer(buffer)
            image.close()
            
            Log.d(TAG, "✅ Bitmap created")
            
            saveAndSend(bitmap)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to capture image", e)
            stopSelfSafely()
        }
    }

    private fun saveAndSend(bitmap: Bitmap) {
        try {
            Log.d(TAG, "Saving screenshot...")
            
            val file = File(cacheDir, "screenshot_${System.currentTimeMillis()}.jpg")
            
            FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
            }
            
            bitmap.recycle()
            
            Log.d(TAG, "✅ Screenshot saved: ${file.path}")
            Log.d(TAG, "Size: ${file.length() / 1024} KB")
            
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
                    
                    file.delete()
                    
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to upload screenshot", e)
                }
            }.start()
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to save screenshot", e)
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

    private fun stopSelfSafely() {
        handler.postDelayed({
            try {
                cleanup()
                stopForeground(true)
                stopSelf()
                Log.d(TAG, "========================================")
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping service", e)
            }
        }, 1000)
    }

    private fun createNotification(message: String): Notification {
        // ✅ FIX: Use android built-in icon
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Screen Capture")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_menu_gallery) // ✅ Use system icon
            .setPriority(NotificationCompat.PRIORITY_LOW) // ✅ Use NotificationCompat constant
            .setAutoCancel(true)

        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Screen Capture",
                NotificationManager.IMPORTANCE_LOW
            )
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        cleanup()
        Log.d(TAG, "Service destroyed")
    }
}