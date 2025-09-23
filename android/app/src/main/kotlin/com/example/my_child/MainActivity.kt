package com.example.my_child

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.os.Bundle

class MainActivity: FlutterActivity() {
    private lateinit var permissionMethodChannel: PermissionMethodChannel
    private lateinit var locationMethodChannel: LocationMethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Setup method channels
        permissionMethodChannel = PermissionMethodChannel(this, this)
        permissionMethodChannel.setupMethodChannel(flutterEngine)
        
        locationMethodChannel = LocationMethodChannel(this)
        locationMethodChannel.setupMethodChannel(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Start foreground service if permissions are granted
        startForegroundServiceIfNeeded()
    }

    private fun startForegroundServiceIfNeeded() {
        val sharedPrefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val permissionSetupCompleted = sharedPrefs.getBoolean("flutter.permission_setup_completed", false)
        
        if (permissionSetupCompleted) {
            val serviceIntent = android.content.Intent(this, FamilyTrackingService::class.java)
            startForegroundService(serviceIntent)
        }
    }
}