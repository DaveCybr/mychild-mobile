package com.example.couple_guard_child

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import java.io.File
import java.io.FileOutputStream

object ImageCompressor {
    private const val TAG = "ImageCompressor"

    /**
     * Compress image file with optimal settings
     * @param file Original image file
     * @param maxWidth Maximum width (default 1280 for monitoring)
     * @param maxHeight Maximum height (default 720 for monitoring)
     * @param quality JPEG quality 0-100 (default 75)
     * @return Compressed file or original if compression fails
     */
    fun compressImage(
        file: File,
        maxWidth: Int = 1280,
        maxHeight: Int = 720,
        quality: Int = 75
    ): File {
        try {
            if (!file.exists()) {
                Log.e(TAG, "File not found: ${file.absolutePath}")
                return file
            }

            val startTime = System.currentTimeMillis()
            val originalSize = file.length()

            // Step 1: Get image dimensions without loading into memory
            val options = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(file.absolutePath, options)

            val originalWidth = options.outWidth
            val originalHeight = options.outHeight

            if (originalWidth <= 0 || originalHeight <= 0) {
                Log.e(TAG, "Invalid image dimensions")
                return file
            }

            Log.d(TAG, "Original: ${originalWidth}x${originalHeight}, ${originalSize / 1024} KB")

            // Step 2: Calculate target dimensions (maintain aspect ratio)
            val (targetWidth, targetHeight) = calculateTargetSize(
                originalWidth, originalHeight, maxWidth, maxHeight
            )

            // Step 3: Calculate inSampleSize for memory efficiency
            options.inSampleSize = calculateInSampleSize(options, targetWidth, targetHeight)
            options.inJustDecodeBounds = false
            options.inPreferredConfig = Bitmap.Config.RGB_565 // Less memory usage

            // Step 4: Decode bitmap
            val bitmap = BitmapFactory.decodeFile(file.absolutePath, options)
            if (bitmap == null) {
                Log.e(TAG, "Failed to decode bitmap")
                return file
            }

            // Step 5: Scale bitmap if needed
            val scaledBitmap = if (bitmap.width != targetWidth || bitmap.height != targetHeight) {
                val scaled = Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
                if (scaled != bitmap) {
                    bitmap.recycle() // Free original bitmap memory
                }
                scaled
            } else {
                bitmap
            }

            // Step 6: Compress and save
            val compressedFile = File(file.parent, "compressed_${System.currentTimeMillis()}_${file.name}")
            var success = false

            try {
                FileOutputStream(compressedFile).use { out ->
                    success = scaledBitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)
                }
            } finally {
                scaledBitmap.recycle() // Always free memory
            }

            if (!success || !compressedFile.exists()) {
                Log.e(TAG, "Failed to save compressed image")
                compressedFile.delete()
                return file
            }

            val compressedSize = compressedFile.length()
            val compressionRatio = if (originalSize > 0) {
                ((originalSize - compressedSize) * 100 / originalSize)
            } else 0
            val timeTaken = System.currentTimeMillis() - startTime

            Log.i(TAG, "✅ Compressed: ${targetWidth}x${targetHeight}, ${compressedSize / 1024} KB")
            Log.i(TAG, "✅ Saved: $compressionRatio% in ${timeTaken}ms")

            // Delete original file
            if (file.delete()) {
                Log.d(TAG, "Original file deleted")
            } else {
                Log.w(TAG, "Failed to delete original file")
            }

            return compressedFile

        } catch (e: OutOfMemoryError) {
            Log.e(TAG, "Out of memory during compression", e)
            return file
        } catch (e: Exception) {
            Log.e(TAG, "Compression failed: ${e.message}", e)
            return file
        }
    }

    private fun calculateTargetSize(
        originalWidth: Int,
        originalHeight: Int,
        maxWidth: Int,
        maxHeight: Int
    ): Pair<Int, Int> {
        if (originalWidth <= maxWidth && originalHeight <= maxHeight) {
            return Pair(originalWidth, originalHeight)
        }

        val ratio = originalWidth.toFloat() / originalHeight.toFloat()

        return if (originalWidth > originalHeight) {
            val width = maxWidth
            val height = (maxWidth / ratio).toInt()
            Pair(width, height)
        } else {
            val height = maxHeight
            val width = (maxHeight * ratio).toInt()
            Pair(width, height)
        }
    }

    private fun calculateInSampleSize(
        options: BitmapFactory.Options,
        reqWidth: Int,
        reqHeight: Int
    ): Int {
        val (height: Int, width: Int) = options.run { outHeight to outWidth }
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            val halfHeight: Int = height / 2
            val halfWidth: Int = width / 2

            while (halfHeight / inSampleSize >= reqHeight &&
                halfWidth / inSampleSize >= reqWidth) {
                inSampleSize *= 2
            }
        }

        return inSampleSize
    }
}