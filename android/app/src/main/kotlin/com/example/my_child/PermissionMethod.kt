package com.example.my_child

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class PermissionMethodChannel(private val context: Context, private val activity: Activity?) {
    
    companion object {
        const val CHANNEL = "com.my_child.child/permissions"
        const val REQUEST_BATTERY_OPTIMIZATION = 1001
        const val REQUEST_DEVICE_ADMIN = 1002
    }
    
    private var methodChannel: MethodChannel? = null
    private val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
    private val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    private val deviceAdminComponent = ComponentName(context, DeviceAdminReceiver::class.java)

    fun setupMethodChannel(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestBatteryOptimization" -> {
                    requestBatteryOptimization(result)
                }
                "isBatteryOptimizationDisabled" -> {
                    result.success(isBatteryOptimizationDisabled())
                }
                "requestDeviceAdmin" -> {
                    requestDeviceAdmin(result)
                }
                "isDeviceAdminActive" -> {
                    result.success(isDeviceAdminActive())
                }
                "openAppSettings" -> {
                    openAppSettings(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestBatteryOptimization(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!powerManager.isIgnoringBatteryOptimizations(context.packageName)) {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:${context.packageName}")
                    }
                    
                    if (activity != null && intent.resolveActivity(context.packageManager) != null) {
                        activity.startActivityForResult(intent, REQUEST_BATTERY_OPTIMIZATION)
                        result.success(true)
                    } else {
                        // Fallback to battery optimization settings
                        val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        if (fallbackIntent.resolveActivity(context.packageManager) != null) {
                            context.startActivity(fallbackIntent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                } else {
                    result.success(true) // Already whitelisted
                }
            } else {
                result.success(true) // Not needed for older versions
            }
        } catch (e: Exception) {
            result.error("BATTERY_OPTIMIZATION_ERROR", e.message, null)
        }
    }

    private fun isBatteryOptimizationDisabled(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            powerManager.isIgnoringBatteryOptimizations(context.packageName)
        } else {
            true
        }
    }

    private fun requestDeviceAdmin(result: MethodChannel.Result) {
        try {
            if (!devicePolicyManager.isAdminActive(deviceAdminComponent)) {
                val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                    putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, deviceAdminComponent)
                    putExtra(
                        DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                        "This app needs device admin permission to protect your child's safety and prevent unauthorized changes."
                    )
                }
                
                if (activity != null) {
                    activity.startActivityForResult(intent, REQUEST_DEVICE_ADMIN)
                    result.success(true)
                } else {
                    result.success(false)
                }
            } else {
                result.success(true) // Already active
            }
        } catch (e: Exception) {
            result.error("DEVICE_ADMIN_ERROR", e.message, null)
        }
    }

    private fun isDeviceAdminActive(): Boolean {
        return devicePolicyManager.isAdminActive(deviceAdminComponent)
    }

    private fun openAppSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
            }
            
            if (intent.resolveActivity(context.packageManager) != null) {
                context.startActivity(intent)
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("SETTINGS_ERROR", e.message, null)
        }
    }
}
