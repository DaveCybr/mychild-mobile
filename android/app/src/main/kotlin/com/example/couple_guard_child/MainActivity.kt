package com.example.couple_guard_child

import android.Manifest
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import com.example.couple_guard_child.services.PersistentService
import com.example.couple_guard_child.utils.ApiClient
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.PowerManager

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"
    private val CHANNEL = "com.example.couple_guard_child/service"
    private lateinit var fusedLocationClient: FusedLocationProviderClient

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        Log.d(TAG, "✅ MainActivity onCreate")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Method channel untuk service control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        PersistentService.startService(this)
                        result.success(null)
                    }
                    "stopService" -> {
                        PersistentService.stopService(this)
                        result.success(null)
                    }
                    "isServiceRunning" -> {
                        result.success(PersistentService.isServiceRunning())
                    }
                    "getDeviceId" -> {
                        val deviceId = ApiClient.getDeviceId(this)
                        result.success(deviceId)
                    }
                    "openNotificationAccess" -> {
                        openNotificationAccessSettings()
                        result.success(null)
                    }
                    "openBatteryOptimization" -> {
                        openBatteryOptimizationSettings()
                        result.success(null)
                    }
                    "openAutoStartSettings" -> {
                        val manufacturer = call.argument<String>("manufacturer") ?: "generic"
                        openAutoStartSettings(manufacturer)
                        result.success(null)
                    }
                    "testSendLocation" -> {
                        testSendLocation(result)
                    }
                    "testSendNotification" -> {
                        testSendNotification(result)
                    }
                    "isNotificationAccessGranted" -> {
                        result.success(isNotificationAccessGranted())
                    }
                    "isBatteryOptimizationDisabled" -> {
                        result.success(isBatteryOptimizationDisabled())
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        
        // Method channel untuk location worker (dipanggil dari PairingScreen)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "location_worker_channel")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startPeriodicLocation" -> {
                        Log.d(TAG, "📍 startPeriodicLocation called from Flutter")
                        // WorkManager sudah di-schedule oleh PersistentService
                        // Tapi kita pastikan service running
                        PersistentService.startService(this)
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun isNotificationAccessGranted(): Boolean {
        return try {
            val enabledListeners = Settings.Secure.getString(
                contentResolver,
                "enabled_notification_listeners"
            )
            
            val packageName = packageName
            val result = enabledListeners?.contains(packageName) ?: false
            
            Log.d(TAG, "Notification access granted: $result")
            result
        } catch (e: Exception) {
            Log.e(TAG, "Error checking notification access", e)
            false
        }
    }

    private fun isBatteryOptimizationDisabled(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                val result = powerManager.isIgnoringBatteryOptimizations(packageName)
                
                Log.d(TAG, "Battery optimization disabled: $result")
                result
            } else {
                true // Not applicable for Android < 6.0
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking battery optimization", e)
            false
        }
    }

    private fun openNotificationAccessSettings() {
        try {
            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening notification settings", e)
        }
    }

    private fun openBatteryOptimizationSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error opening battery optimization settings", e)
            
            // Fallback to general battery settings
            try {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                startActivity(intent)
            } catch (e2: Exception) {
                Log.e(TAG, "Error opening general battery settings", e2)
            }
        }
    }

    private fun openAutoStartSettings(manufacturer: String) {
        val intent = Intent()
        
        try {
            when (manufacturer.lowercase()) {
                "xiaomi" -> {
                    // MIUI
                    intent.component = ComponentName(
                        "com.miui.securitycenter",
                        "com.miui.permcenter.autostart.AutoStartManagementActivity"
                    )
                }
                "oppo" -> {
                    // ColorOS
                    intent.component = ComponentName(
                        "com.coloros.safecenter",
                        "com.coloros.safecenter.permission.startup.StartupAppListActivity"
                    )
                    // Fallback
                    if (!isActivityAvailable(intent)) {
                        intent.component = ComponentName(
                            "com.oppo.safe",
                            "com.oppo.safe.permission.startup.StartupAppListActivity"
                        )
                    }
                }
                "vivo" -> {
                    // Funtouch OS
                    intent.component = ComponentName(
                        "com.vivo.permissionmanager",
                        "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                    )
                    // Fallback
                    if (!isActivityAvailable(intent)) {
                        intent.component = ComponentName(
                            "com.iqoo.secure",
                            "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"
                        )
                    }
                }
                "samsung" -> {
                    // OneUI
                    intent.component = ComponentName(
                        "com.samsung.android.lool",
                        "com.samsung.android.sm.ui.battery.BatteryActivity"
                    )
                }
                "huawei" -> {
                    // EMUI
                    intent.component = ComponentName(
                        "com.huawei.systemmanager",
                        "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                    )
                }
                "oneplus" -> {
                    // OxygenOS
                    intent.component = ComponentName(
                        "com.oneplus.security",
                        "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"
                    )
                }
                else -> {
                    // Generic settings
                    intent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                    intent.data = Uri.parse("package:$packageName")
                }
            }
            
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening auto-start settings for $manufacturer", e)
            
            // Final fallback to app settings
            try {
                val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                fallbackIntent.data = Uri.parse("package:$packageName")
                startActivity(fallbackIntent)
            } catch (e2: Exception) {
                Log.e(TAG, "Error opening app settings", e2)
            }
        }
    }

    private fun isActivityAvailable(intent: Intent): Boolean {
        return packageManager.queryIntentActivities(intent, 0).isNotEmpty()
    }

    private fun testSendLocation(result: MethodChannel.Result) {
        Thread {
            try {
                // Check permission
                if (ActivityCompat.checkSelfPermission(
                        this,
                        Manifest.permission.ACCESS_FINE_LOCATION
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    runOnUiThread {
                        result.success(false)
                    }
                    return@Thread
                }

                // Get location
                fusedLocationClient.lastLocation.addOnSuccessListener { location: Location? ->
                    if (location != null) {
                        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                        val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                        
                        val success = ApiClient.sendLocation(
                            applicationContext,
                            location.latitude,
                            location.longitude,
                            batteryLevel
                        )
                        
                        runOnUiThread {
                            result.success(success)
                        }
                    } else {
                        runOnUiThread {
                            result.success(false)
                        }
                    }
                }.addOnFailureListener {
                    runOnUiThread {
                        result.success(false)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error testing location", e)
                runOnUiThread {
                    result.success(false)
                }
            }
        }
    }

    private fun testSendNotification(result: MethodChannel.Result) {
        Thread {
            val success = ApiClient.sendNotification(
                applicationContext,
                "Test App",
                "Test Notification",
                "This is a test notification from Couple Guard Child"
            )
            
            runOnUiThread {
                result.success(success)
            }
        }.start()
    }
}