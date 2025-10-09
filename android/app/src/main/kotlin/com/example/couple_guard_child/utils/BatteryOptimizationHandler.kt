package com.example.couple_guard_child.utils

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

/**
 * Helper untuk bypass battery optimization
 * Critical untuk parental control apps
 */
object BatteryOptimizationHelper {
    private const val TAG = "BatteryOptHelper"

    /**
     * Check if app is ignoring battery optimization
     */
    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val packageName = context.packageName
            val isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
            
            Log.d(TAG, "Battery optimization status: ${if (isIgnoring) "IGNORED" else "ACTIVE"}")
            return isIgnoring
        }
        return true // Android < 6.0 tidak ada battery optimization
    }

    /**
     * Request to disable battery optimization
     */
    fun requestDisableBatteryOptimization(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                Log.d(TAG, "Opening battery optimization settings...")
                
                val intent = Intent().apply {
                    action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                    data = Uri.parse("package:${context.packageName}")
                }
                
                context.startActivity(intent)
                Log.d(TAG, "✅ Battery optimization dialog opened")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to open battery optimization settings", e)
                
                // Fallback: Open battery settings page
                try {
                    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    context.startActivity(intent)
                } catch (e2: Exception) {
                    Log.e(TAG, "❌ Fallback also failed", e2)
                }
            }
        }
    }

    /**
     * Open OEM-specific battery settings
     * Critical untuk Xiaomi, Huawei, Samsung, dll
     */
    fun openOemBatterySettings(context: Context) {
        val manufacturer = Build.MANUFACTURER.lowercase()
        
        Log.d(TAG, "========================================")
        Log.d(TAG, "Device manufacturer: $manufacturer")
        
        when {
            manufacturer.contains("xiaomi") -> openXiaomiBatterySettings(context)
            manufacturer.contains("huawei") -> openHuaweiBatterySettings(context)
            manufacturer.contains("samsung") -> openSamsungBatterySettings(context)
            manufacturer.contains("oppo") -> openOppoBatterySettings(context)
            manufacturer.contains("vivo") -> openVivoBatterySettings(context)
            manufacturer.contains("oneplus") -> openOnePlusBatterySettings(context)
            else -> {
                Log.d(TAG, "No specific OEM settings, using standard")
                requestDisableBatteryOptimization(context)
            }
        }
        
        Log.d(TAG, "========================================")
    }

    private fun openXiaomiBatterySettings(context: Context) {
        Log.d(TAG, "Opening Xiaomi battery settings...")
        try {
            // MIUI 12+ Autostart
            val intent = Intent().apply {
                component = android.content.ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity"
                )
            }
            context.startActivity(intent)
            Log.d(TAG, "✅ Xiaomi autostart settings opened")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to open Xiaomi settings", e)
            requestDisableBatteryOptimization(context)
        }
    }

    private fun openHuaweiBatterySettings(context: Context) {
        Log.d(TAG, "Opening Huawei battery settings...")
        try {
            // Huawei Protected Apps
            val intent = Intent().apply {
                component = android.content.ComponentName(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                )
            }
            context.startActivity(intent)
            Log.d(TAG, "✅ Huawei protected apps opened")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to open Huawei settings", e)
            requestDisableBatteryOptimization(context)
        }
    }

    private fun openSamsungBatterySettings(context: Context) {
        Log.d(TAG, "Opening Samsung battery settings...")
        try {
            // Samsung Battery Settings
            val intent = Intent().apply {
                action = "android.settings.APPLICATION_DETAILS_SETTINGS"
                data = Uri.parse("package:${context.packageName}")
            }
            context.startActivity(intent)
            Log.d(TAG, "✅ Samsung app details opened")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to open Samsung settings", e)
            requestDisableBatteryOptimization(context)
        }
    }

    private fun openOppoBatterySettings(context: Context) {
        Log.d(TAG, "Opening Oppo battery settings...")
        try {
            val intent = Intent().apply {
                component = android.content.ComponentName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity"
                )
            }
            context.startActivity(intent)
            Log.d(TAG, "✅ Oppo startup settings opened")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to open Oppo settings", e)
            requestDisableBatteryOptimization(context)
        }
    }

    private fun openVivoBatterySettings(context: Context) {
        Log.d(TAG, "Opening Vivo battery settings...")
        try {
            val intent = Intent().apply {
                component = android.content.ComponentName(
                    "com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"
                )
            }
            context.startActivity(intent)
            Log.d(TAG, "✅ Vivo whitelist settings opened")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to open Vivo settings", e)
            requestDisableBatteryOptimization(context)
        }
    }

    private fun openOnePlusBatterySettings(context: Context) {
        Log.d(TAG, "Opening OnePlus battery settings...")
        try {
            val intent = Intent().apply {
                component = android.content.ComponentName(
                    "com.oneplus.security",
                    "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"
                )
            }
            context.startActivity(intent)
            Log.d(TAG, "✅ OnePlus battery settings opened")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to open OnePlus settings", e)
            requestDisableBatteryOptimization(context)
        }
    }

    /**
     * Get user-friendly instructions based on manufacturer
     */
    fun getBatteryOptimizationInstructions(context: Context): String {
        val manufacturer = Build.MANUFACTURER.lowercase()
        
        return when {
            manufacturer.contains("xiaomi") -> """
                🔋 Xiaomi/MIUI Instructions:
                1. Go to Settings → Apps → Manage apps
                2. Find "Family Safety"
                3. Enable "Autostart"
                4. Set Battery saver to "No restrictions"
                5. Lock app in Recent Apps
            """.trimIndent()
            
            manufacturer.contains("huawei") -> """
                🔋 Huawei Instructions:
                1. Go to Settings → Battery → App launch
                2. Find "Family Safety"
                3. Toggle OFF "Manage automatically"
                4. Enable Auto-launch, Secondary launch, Run in background
            """.trimIndent()
            
            manufacturer.contains("samsung") -> """
                🔋 Samsung Instructions:
                1. Go to Settings → Apps → Family Safety
                2. Battery → Optimize battery usage → All apps
                3. Toggle OFF for "Family Safety"
                4. Settings → Battery → Background usage limits
                5. Add "Family Safety" to "Never sleeping apps"
            """.trimIndent()
            
            manufacturer.contains("oppo") -> """
                🔋 Oppo/ColorOS Instructions:
                1. Settings → Battery → App Battery Management
                2. Find "Family Safety"
                3. Enable "Allow background activity"
                4. Settings → Privacy → Permission manager → Autostart
                5. Enable "Family Safety"
            """.trimIndent()
            
            manufacturer.contains("vivo") -> """
                🔋 Vivo Instructions:
                1. Settings → Battery → Background power consumption
                2. Add "Family Safety" to whitelist
                3. Settings → More settings → Applications → Autostart
                4. Enable "Family Safety"
            """.trimIndent()
            
            manufacturer.contains("oneplus") -> """
                🔋 OnePlus Instructions:
                1. Settings → Battery → Battery optimization
                2. Find "Family Safety" → Don't optimize
                3. Recent apps → Lock icon to lock app
            """.trimIndent()
            
            else -> """
                🔋 General Instructions:
                1. Go to Settings → Apps → Family Safety
                2. Battery → Unrestricted
                3. Disable any battery optimization
            """.trimIndent()
        }
    }
}