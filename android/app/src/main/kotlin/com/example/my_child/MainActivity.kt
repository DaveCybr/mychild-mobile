package com.example.my_child

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.os.Bundle
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Start background service if permissions are granted
        startForegroundServiceIfNeeded()
    }

    private fun startForegroundServiceIfNeeded() {
        val sharedPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val permissionSetupCompleted = sharedPrefs.getBoolean("flutter.permission_setup_completed", false)
        
        if (permissionSetupCompleted) {
            val serviceIntent = Intent(this, FamilyTrackingService::class.java)
            ContextCompat.startForegroundService(this, serviceIntent)
        }
    }
}