package com.example.my_child

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.content.Intent
import androidx.core.content.ContextCompat

class MainActivity: FlutterActivity() {
    private lateinit var permissionMethodChannel: PermissionMethodChannel
    private lateinit var locationMethodChannel: LocationMethodChannel
    private lateinit var serviceManagerChannel: MethodChannel
    
    companion object {
        const val SERVICE_MANAGER_CHANNEL = "com.famisafe.child/service_manager"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Setup method channels
        permissionMethodChannel = PermissionMethodChannel(this, this)
        permissionMethodChannel.setupMethodChannel(flutterEngine)
        
        locationMethodChannel = LocationMethodChannel(this)
        locationMethodChannel.setupMethodChannel(flutterEngine)
        
        // Setup service manager channel
        setupServiceManagerChannel(flutterEngine)
    }

    private fun setupServiceManagerChannel(flutterEngine: FlutterEngine) {
        serviceManagerChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SERVICE_MANAGER_CHANNEL
        )
        
        serviceManagerChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startLocationTracking" -> {
                    startLocationTrackingService(result)
                }
                "stopLocationTracking" -> {
                    stopLocationTrackingService(result)
                }
                "startFamilyTracking" -> {
                    startFamilyTrackingService(result)
                }
                "stopFamilyTracking" -> {
                    stopFamilyTrackingService(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun startLocationTrackingService(result: MethodChannel.Result) {
        try {
            val serviceIntent = Intent(this, LocationTrackingService::class.java)
            ContextCompat.startForegroundService(this, serviceIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("LOCATION_SERVICE_ERROR", e.message, null)
        }
    }
    
    private fun stopLocationTrackingService(result: MethodChannel.Result) {
        try {
            val serviceIntent = Intent(this, LocationTrackingService::class.java)
            stopService(serviceIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_SERVICE_ERROR", e.message, null)
        }
    }
    
    private fun startFamilyTrackingService(result: MethodChannel.Result) {
        try {
            val serviceIntent = Intent(this, FamilyTrackingService::class.java)
            ContextCompat.startForegroundService(this, serviceIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("FAMILY_SERVICE_ERROR", e.message, null)
        }
    }
    
    private fun stopFamilyTrackingService(result: MethodChannel.Result) {
        try {
            val serviceIntent = Intent(this, FamilyTrackingService::class.java)
            stopService(serviceIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_SERVICE_ERROR", e.message, null)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Tidak auto-start service lagi
    }
}