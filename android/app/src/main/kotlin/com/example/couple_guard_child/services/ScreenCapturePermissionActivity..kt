package com.example.couple_guard_child.services

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.util.Log

class ScreenCapturePermissionActivity : Activity() {

    companion object {
        private const val TAG = "ScreenCapturePermission"
        private const val REQUEST_MEDIA_PROJECTION = 1001
        
        // ✅ FIX: Sama dengan Service
        private const val PREFS_NAME = "ScreenCapturePrefs"
        private const val KEY_RESULT_CODE = "screen_capture_result_code"
        private const val KEY_RESULT_DATA = "screen_capture_result_data"
        private const val KEY_PERMISSION_GRANTED = "screen_capture_permission_granted"

        fun hasSavedPermission(context: Context): Boolean {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val granted = prefs.getBoolean(KEY_PERMISSION_GRANTED, false)
            
            // ✅ ADD: Debug log
            Log.d(TAG, "========================================")
            Log.d(TAG, "🔍 CHECKING SAVED PERMISSION")
            Log.d(TAG, "Prefs name: $PREFS_NAME")
            Log.d(TAG, "Permission granted: $granted")
            Log.d(TAG, "Result code: ${prefs.getInt(KEY_RESULT_CODE, -1)}")
            Log.d(TAG, "Result data exists: ${prefs.getString(KEY_RESULT_DATA, null) != null}")
            Log.d(TAG, "========================================")
            
            return granted
        }

        fun savePermission(context: Context, resultCode: Int, data: Intent) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val dataUri = data.toUri(0)
                
                // ✅ Use commit() not apply()
                prefs.edit().apply {
                    putInt(KEY_RESULT_CODE, resultCode)
                    putString(KEY_RESULT_DATA, dataUri)
                    putBoolean(KEY_PERMISSION_GRANTED, true)
                    commit() // ← PENTING: sync write
                }
                
                // Save to memory
                // ScreenCaptureForegroundService.savePermission(resultCode, data)
                
                Log.d(TAG, "✅ Permission saved")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Save failed", e)
                throw e
            }
        }

        fun getSavedPermission(context: Context): Pair<Int, Intent>? {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val code = prefs.getInt(KEY_RESULT_CODE, -1)
                val dataUri = prefs.getString(KEY_RESULT_DATA, null)
                
                if (code == -1 || dataUri == null) {
                    Log.w(TAG, "No saved permission found")
                    return null
                }
                
                val intent = Intent.parseUri(dataUri, 0)
                Log.d(TAG, "✅ Retrieved saved permission")
                return Pair(code, intent)
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error getting saved permission", e)
                return null
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "========================================")
        Log.d(TAG, "📋 SCREEN CAPTURE PERMISSION ACTIVITY")
        Log.d(TAG, "========================================")

        val mgr = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(mgr.createScreenCaptureIntent(), REQUEST_MEDIA_PROJECTION)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        Log.d(TAG, "========================================")
        Log.d(TAG, "📋 PERMISSION RESULT RECEIVED")
        Log.d(TAG, "Request Code: $requestCode")
        Log.d(TAG, "Result Code: $resultCode")
        Log.d(TAG, "RESULT_OK: $RESULT_OK")
        Log.d(TAG, "Data is null: ${data == null}")
        
        if (requestCode == REQUEST_MEDIA_PROJECTION) {
            if (resultCode == RESULT_OK && data != null) {
                Log.d(TAG, "✅ User GRANTED MediaProjection permission")
                savePermission(this, resultCode, data)
            } else {
                Log.e(TAG, "❌ User DENIED MediaProjection permission")
                Log.e(TAG, "Result code was: $resultCode (expected $RESULT_OK)")
                
                // Clear any existing permission
                val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().clear().apply()
            }
        } else {
            Log.e(TAG, "❌ Unknown request code: $requestCode")
        }
        
        Log.d(TAG, "========================================")
        finish()
    }
}