package com.example.my_child

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class LocationMethodChannel(private val context: Context) {
    
    companion object {
        const val CHANNEL = "com.famisafe.child/location"
    }
    
    private var methodChannel: MethodChannel? = null
    private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    fun setupMethodChannel(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startLocationTracking" -> {
                    startLocationTracking(result)
                }
                "stopLocationTracking" -> {
                    stopLocationTracking(result)
                }
                "isLocationServiceEnabled" -> {
                    result.success(isLocationServiceEnabled())
                }
                "hasLocationPermission" -> {
                    result.success(hasLocationPermission())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startLocationTracking(result: MethodChannel.Result) {
        try {
            if (!isLocationServiceEnabled()) {
                result.error("LOCATION_SERVICE_DISABLED", "Location services are disabled", null)
                return
            }
            
            if (!hasLocationPermission()) {
                result.error("LOCATION_PERMISSION_DENIED", "Location permission not granted", null)
                return
            }
            
            // Start foreground service for location tracking
            val serviceIntent = Intent(context, LocationTrackingService::class.java)
            ContextCompat.startForegroundService(context, serviceIntent)
            
            result.success(true)
        } catch (e: Exception) {
            result.error("LOCATION_TRACKING_ERROR", e.message, null)
        }
    }

    private fun stopLocationTracking(result: MethodChannel.Result) {
        try {
            val serviceIntent = Intent(context, LocationTrackingService::class.java)
            context.stopService(serviceIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_LOCATION_ERROR", e.message, null)
        }
    }

    private fun isLocationServiceEnabled(): Boolean {
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED &&
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_BACKGROUND_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
}
