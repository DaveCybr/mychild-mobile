package com.example.couple_guard_child

import android.util.Log
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.Call
import okhttp3.Callback
import okhttp3.Response
import okhttp3.Interceptor
import java.io.File
import java.io.IOException
import java.util.concurrent.TimeUnit
import android.graphics.BitmapFactory


object UploadHelper {

    private const val TAG = "UploadHelper"
    private const val BASE_URL = "https://parentalcontrol.satelliteorbit.cloud/application/public"
    private const val MAX_RETRIES = 3

    // ✅ Smart logging interceptor yang tidak log binary data
    private val client by lazy {
        val smartLoggingInterceptor = Interceptor { chain ->
            val request = chain.request()
            
            // Log request
            Log.d("$TAG-HTTP", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            Log.d("$TAG-HTTP", "→ ${request.method} ${request.url}")
            Log.d("$TAG-HTTP", "Request Headers:")
            request.headers.forEach { (name, value) ->
                Log.d("$TAG-HTTP", "  $name: $value")
            }
            
            // Jangan log body untuk multipart (berisi binary file)
            val contentType = request.body?.contentType()?.toString() ?: ""
            if (contentType.contains("multipart")) {
                Log.d("$TAG-HTTP", "Body: [MULTIPART DATA - ${request.body?.contentLength()} bytes]")
            } else {
                Log.d("$TAG-HTTP", "Body: ${request.body}")
            }
            
            // Execute request
            val startTime = System.currentTimeMillis()
            val response = chain.proceed(request)
            val duration = System.currentTimeMillis() - startTime
            
            // Log response
            Log.d("$TAG-HTTP", "← ${response.code} ${response.message} (${duration}ms)")
            Log.d("$TAG-HTTP", "Response Headers:")
            response.headers.forEach { (name, value) ->
                Log.d("$TAG-HTTP", "  $name: $value")
            }
            
            // Log response body hanya jika bukan binary
            val responseContentType = response.body?.contentType()?.toString() ?: ""
            if (responseContentType.contains("json") || responseContentType.contains("text")) {
                // Safe to log as text
                val bodyString = response.peekBody(Long.MAX_VALUE).string()
                Log.d("$TAG-HTTP", "Response Body: $bodyString")
            } else {
                Log.d("$TAG-HTTP", "Response Body: [BINARY DATA - ${response.body?.contentLength()} bytes]")
            }
            
            Log.d("$TAG-HTTP", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            response
        }

        OkHttpClient.Builder()
            .addInterceptor(smartLoggingInterceptor)
            .connectTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(60, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    fun uploadScreenshot(deviceId: String, filePath: String) {
        Log.i(TAG, "═══════════════════════════════════════════════")
        Log.i(TAG, "📸 Starting screenshot upload")
        Log.i(TAG, "Device ID: $deviceId")
        Log.i(TAG, "File path: $filePath")

        try {
            val file = File(filePath)
            
            // ✅ Detailed file validation
            if (!file.exists()) {
                Log.e(TAG, "❌ File not found: $filePath")
                Log.e(TAG, "Parent dir exists: ${file.parentFile?.exists()}")
                Log.e(TAG, "Parent dir path: ${file.parentFile?.absolutePath}")
                return
            }

            Log.i(TAG, "✅ File exists")
            Log.i(TAG, "File size: ${file.length()} bytes (${file.length() / 1024} KB)")
            Log.i(TAG, "File readable: ${file.canRead()}")
            Log.i(TAG, "File name: ${file.name}")
            Log.i(TAG, "File absolute path: ${file.absolutePath}")

            // ✅ Multipart form data
            val requestBody = MultipartBody.Builder()
                .setType(MultipartBody.FORM)
                .addFormDataPart("device_id", deviceId)
                .addFormDataPart(
                    "screenshot",
                    file.name,
                    file.asRequestBody("image/jpeg".toMediaTypeOrNull())
                )
                .build()

            Log.i(TAG, "Request body size: ${requestBody.contentLength()} bytes")
            Log.i(TAG, "Request body parts: ${requestBody.parts.size}")

            // ✅ Request
            val url = "$BASE_URL/api/device/screenshots"
            Log.i(TAG, "Target URL: $url")

            val request = Request.Builder()
                .url(url)
                .post(requestBody)
                .build()

            Log.i(TAG, "🚀 Sending request...")

            // ✅ Send async with detailed logging
            client.newCall(request).enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    Log.e(TAG, "═══════════════════════════════════════════════")
                    Log.e(TAG, "❌ Upload FAILED")
                    Log.e(TAG, "Error type: ${e.javaClass.simpleName}")
                    Log.e(TAG, "Error message: ${e.message}")
                    Log.e(TAG, "Stack trace:", e)
                    Log.e(TAG, "═══════════════════════════════════════════════")
                }

                override fun onResponse(call: Call, response: Response) {
                    response.use {
                        Log.i(TAG, "═══════════════════════════════════════════════")
                        Log.i(TAG, "📥 Response received")
                        Log.i(TAG, "Status code: ${it.code}")
                        Log.i(TAG, "Status message: ${it.message}")

                        val responseBody = it.body?.string() ?: ""
                        Log.i(TAG, "Response body length: ${responseBody.length}")
                        Log.i(TAG, "Response body: $responseBody")

                        if (!it.isSuccessful) {
                            Log.e(TAG, "❌ Upload failed with code ${it.code}")
                        } else {
                            Log.i(TAG, "✅ Upload SUCCESS!")
                            
                            // Parse response to verify data
                            try {
                                if (responseBody.contains("\"success\"")) {
                                    Log.i(TAG, "✅ Response contains success field")
                                    if (responseBody.contains("\"data\"")) {
                                        Log.i(TAG, "✅ Response contains data field")
                                    } else {
                                        Log.w(TAG, "⚠️ Response missing data field")
                                    }
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "Error parsing response: ${e.message}")
                            }
                        }
                        Log.i(TAG, "═══════════════════════════════════════════════")
                    }
                }
            })

        } catch (e: Exception) {
            Log.e(TAG, "═══════════════════════════════════════════════")
            Log.e(TAG, "❌ Exception in uploadScreenshot")
            Log.e(TAG, "Exception type: ${e.javaClass.simpleName}")
            Log.e(TAG, "Exception message: ${e.message}", e)
            Log.e(TAG, "═══════════════════════════════════════════════")
        }
    }

    fun uploadCapturedPhoto(deviceId: String, frontCamera: Boolean, filePath: String) {
        Log.i(TAG, "═══════════════════════════════════════════════")
        Log.i(TAG, "📷 Starting camera photo upload")
        Log.i(TAG, "Device ID: $deviceId")
        Log.i(TAG, "Camera type: ${if (frontCamera) "front" else "back"}")
        Log.i(TAG, "File path: $filePath")

        try {
            val file = File(filePath)

            // Validation 1: File exists
            if (!file.exists()) {
                Log.e(TAG, "❌ File not found: $filePath")
                return
            }

            Log.i(TAG, "✅ File exists")
            Log.i(TAG, "File size before compression: ${file.length()} bytes (${file.length() / 1024} KB)")

            // Validation 2: File is readable
            if (!file.canRead()) {
                Log.e(TAG, "❌ File not readable")
                return
            }

            // Validation 3: File is valid image
            val options = BitmapFactory.Options()
            options.inJustDecodeBounds = true
            BitmapFactory.decodeFile(filePath, options)

            Log.d("UploadHelper", "Image width: ${options.outWidth}, height: ${options.outHeight}, type: ${options.outMimeType}")

            if (options.outWidth <= 0 || options.outHeight <= 0) {
                Log.e(TAG, "❌ Invalid image file")
                return
            }

            Log.i(TAG, "✅ Valid image: ${options.outWidth}x${options.outHeight}")
            Log.i(TAG, "Image MIME type: ${options.outMimeType}")

            // Step 1: Compress image
            Log.i(TAG, "🔄 Compressing image...")
            val compressedFile = ImageCompressor.compressImage(
                file = file,
                maxWidth = 1280,
                maxHeight = 720,
                quality = 75
            )

            if (!compressedFile.exists()) {
                Log.e(TAG, "❌ Compression failed - file doesn't exist")
                return
            }

            Log.i(TAG, "✅ Compression complete")
            Log.i(TAG, "Compressed file size: ${compressedFile.length()} bytes (${compressedFile.length() / 1024} KB)")

            // Validation 4: Check compressed file size
            val maxSizeBytes = 10 * 1024 * 1024 // 10MB
            if (compressedFile.length() > maxSizeBytes) {
                Log.e(TAG, "❌ Compressed file still too large: ${compressedFile.length() / 1024 / 1024} MB")
                compressedFile.delete()
                return
            }

            // Step 2: Upload
            uploadWithRetry(deviceId, frontCamera, compressedFile, 0)

        } catch (e: OutOfMemoryError) {
            Log.e(TAG, "❌ Out of memory: ${e.message}", e)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception in uploadCapturedPhoto: ${e.message}", e)
        }
    }

    private fun uploadWithRetry(deviceId: String, frontCamera: Boolean, file: File, attempt: Int) {
        if (attempt >= MAX_RETRIES) {
            Log.e(TAG, "❌ Max retries reached. Upload failed.")
            file.delete()
            return
        }

        val attemptNum = attempt + 1
        Log.i(TAG, "📤 Upload attempt $attemptNum/$MAX_RETRIES")

        try {
            val cameraTypeStr = if (frontCamera) "front" else "back"

            // Build multipart request body
            val requestBody = MultipartBody.Builder()
                .setType(MultipartBody.FORM)
                .addFormDataPart("device_id", deviceId)
                .addFormDataPart("camera_type", cameraTypeStr)
                .addFormDataPart(
                    "photo",
                    file.name,
                    file.asRequestBody("image/jpeg".toMediaTypeOrNull())
                )
                .build()

            Log.i(TAG, "Request body size: ${requestBody.contentLength()} bytes")
            Log.i(TAG, "Request body parts: ${requestBody.parts.size}")

            // Build request (DO NOT manually set Content-Type header)
            val url = "$BASE_URL/api/upload/photo"
            Log.i(TAG, "Target URL: $url")

            val request = Request.Builder()
                .url(url)
                .addHeader("Accept", "application/json")
                .post(requestBody)
                .build()

            Log.i(TAG, "🚀 Sending request...")

            // Send request
            client.newCall(request).enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    Log.e(TAG, "═══════════════════════════════════════════════")
                    Log.e(TAG, "❌ Upload FAILED (Attempt $attemptNum)")
                    Log.e(TAG, "Error type: ${e.javaClass.simpleName}")
                    Log.e(TAG, "Error message: ${e.message}")
                    
                    if (e is java.net.SocketTimeoutException) {
                        Log.e(TAG, "⏱️ Request timed out")
                    } else if (e is java.net.UnknownHostException) {
                        Log.e(TAG, "🌐 Network error - check internet connection")
                    }
                    
                    Log.e(TAG, "═══════════════════════════════════════════════")

                    // Retry with exponential backoff
                    if (attempt < MAX_RETRIES - 1) {
                        val delayMs = (1000 * (attempt + 1)).toLong()
                        Log.i(TAG, "⏳ Retrying in ${delayMs}ms...")
                        Thread.sleep(delayMs)
                        uploadWithRetry(deviceId, frontCamera, file, attempt + 1)
                    } else {
                        file.delete()
                    }
                }

                override fun onResponse(call: Call, response: Response) {
                    response.use {
                        Log.i(TAG, "═══════════════════════════════════════════════")
                        Log.i(TAG, "📥 Response received (Attempt $attemptNum)")
                        Log.i(TAG, "Status code: ${it.code}")
                        Log.i(TAG, "Status message: ${it.message}")
                        Log.i(TAG, "Is successful: ${it.isSuccessful}")

                        val responseBody = it.body?.string() ?: ""
                        Log.i(TAG, "Response body length: ${responseBody.length}")
                        Log.i(TAG, "Response body: $responseBody")

                        when (it.code) {
                            200, 201 -> {
                                Log.i(TAG, "✅ Upload SUCCESS!")
                                
                                try {
                                    if (responseBody.contains("\"success\"") && 
                                        responseBody.contains("true")) {
                                        Log.i(TAG, "✅ Server confirmed success")
                                        
                                        // Extract record ID if present
                                        val idPattern = "\"id\":(\\d+)".toRegex()
                                        idPattern.find(responseBody)?.let { match ->
                                            Log.i(TAG, "✅ Record ID: ${match.groupValues[1]}")
                                        }
                                    }
                                } catch (e: Exception) {
                                    Log.w(TAG, "Could not parse response: ${e.message}")
                                }
                                
                                // Delete file after successful upload
                                if (file.delete()) {
                                    Log.i(TAG, "✅ Temporary file deleted")
                                }
                            }
                            
                            422 -> {
                                Log.e(TAG, "❌ Validation error (422)")
                                Log.e(TAG, "Response: $responseBody")
                                
                                if (responseBody.contains("device_id")) {
                                    Log.e(TAG, "⚠️ Device ID tidak valid atau tidak terdaftar")
                                    Log.e(TAG, "⚠️ Periksa database: SELECT * FROM devices WHERE device_id = '$deviceId'")
                                }
                                if (responseBody.contains("camera_type")) {
                                    Log.e(TAG, "⚠️ Camera type tidak valid")
                                }
                                if (responseBody.contains("photo")) {
                                    Log.e(TAG, "⚠️ Photo validation failed")
                                    
                                    // Retry with even more compression
                                    if (attempt < MAX_RETRIES - 1) {
                                        Log.i(TAG, "🔄 Trying with higher compression...")
                                        val recompressed = ImageCompressor.compressImage(
                                            file = file,
                                            maxWidth = 960,
                                            maxHeight = 540,
                                            quality = 60
                                        )
                                        uploadWithRetry(deviceId, frontCamera, recompressed, attempt + 1)
                                        return
                                    }
                                }
                                
                                file.delete()
                            }
                            
                            404 -> {
                                Log.e(TAG, "❌ Not found (404)")
                                Log.e(TAG, "⚠️ Endpoint mungkin salah atau device_id tidak ada")
                                file.delete()
                            }
                            
                            413 -> {
                                Log.e(TAG, "❌ Payload too large (413)")
                                Log.e(TAG, "⚠️ File terlalu besar untuk server")
                                
                                if (attempt < MAX_RETRIES - 1) {
                                    Log.i(TAG, "🔄 Compressing more aggressively...")
                                    val recompressed = ImageCompressor.compressImage(
                                        file = file,
                                        maxWidth = 800,
                                        maxHeight = 600,
                                        quality = 50
                                    )
                                    uploadWithRetry(deviceId, frontCamera, recompressed, attempt + 1)
                                } else {
                                    file.delete()
                                }
                            }
                            
                            500, 502, 503, 504 -> {
                                Log.e(TAG, "❌ Server error (${it.code})")
                                Log.e(TAG, "⚠️ Periksa Laravel logs di server")
                                
                                // Retry for server errors
                                if (attempt < MAX_RETRIES - 1) {
                                    val delayMs = (2000 * (attempt + 1)).toLong()
                                    Log.i(TAG, "⏳ Retrying in ${delayMs}ms...")
                                    Thread.sleep(delayMs)
                                    uploadWithRetry(deviceId, frontCamera, file, attempt + 1)
                                } else {
                                    file.delete()
                                }
                            }
                            
                            else -> {
                                Log.e(TAG, "❌ Upload failed with code ${it.code}")
                                Log.e(TAG, "Response: $responseBody")
                                file.delete()
                            }
                        }
                        
                        Log.i(TAG, "═══════════════════════════════════════════════")
                    }
                }
            })

        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception during upload: ${e.message}", e)
            
            if (attempt < MAX_RETRIES - 1) {
                uploadWithRetry(deviceId, frontCamera, file, attempt + 1)
            } else {
                file.delete()
            }
        }
    }
}