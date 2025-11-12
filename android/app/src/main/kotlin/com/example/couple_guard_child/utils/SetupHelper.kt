package com.example.couple_guard_child.utils

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.util.Log
import com.example.couple_guard_child.admin.MyDeviceAdminReceiver
import com.example.couple_guard_child.services.MonitoringAccessibilityService

/**
 * SetupHelper - Guide user melalui semua permission yang dibutuhkan
 */
object SetupHelper {
    private const val TAG = "SetupHelper"

    /**
     * Check apakah Accessibility Service sudah enabled
     */
    fun isAccessibilityServiceEnabled(context: Context): Boolean {
        val service = "${context.packageName}/${MonitoringAccessibilityService::class.java.name}"
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        
        val isEnabled = enabledServices?.contains(service) == true
        Log.d(TAG, "Accessibility Service enabled: $isEnabled")
        return isEnabled
    }

    /**
     * Open Accessibility Settings
     */
    fun openAccessibilitySettings(context: Context) {
        try {
            Log.d(TAG, "Opening Accessibility Settings...")
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            Log.d(TAG, "✅ Accessibility Settings opened")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to open Accessibility Settings", e)
        }
    }

    /**
     * Check apakah Device Admin sudah enabled
     */
    fun isDeviceAdminEnabled(context: Context): Boolean {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(context, MyDeviceAdminReceiver::class.java)
        val isEnabled = dpm.isAdminActive(adminComponent)
        
        Log.d(TAG, "Device Admin enabled: $isEnabled")
        return isEnabled
    }

    /**
     * Request Device Admin activation
     */
    fun requestDeviceAdmin(context: Context) {
        try {
            Log.d(TAG, "Requesting Device Admin activation...")
            
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(context, MyDeviceAdminReceiver::class.java)
            
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
            intent.putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "Family Safety needs Device Administrator permission to:\n\n" +
                "• Prevent unauthorized uninstallation\n" +
                "• Protect monitoring settings\n" +
                "• Ensure continuous protection\n\n" +
                "This is essential for parental control functionality."
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            context.startActivity(intent)
            Log.d(TAG, "✅ Device Admin request dialog opened")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to request Device Admin", e)
        }
    }

    /**
     * Get setup completion percentage
     */
    fun getSetupProgress(context: Context): Int {
        var progress = 0
        val steps = 7 // Total setup steps
        
        // 1. Basic permissions (Location, Camera, Storage)
        if (hasBasicPermissions(context)) progress++
        
        // 2. Battery optimization
        if (BatteryOptimizationHelper.isIgnoringBatteryOptimizations(context)) progress++
        
        // 3. Notification Listener
        if (isNotificationListenerEnabled(context)) progress++
        
        // 4. Accessibility Service ✨ MOST IMPORTANT
        if (isAccessibilityServiceEnabled(context)) progress++
        
        // 5. Device Admin
        if (isDeviceAdminEnabled(context)) progress++
        
        // 6. Paired with parent
        if (ApiClient.isPaired(context)) progress++
        
        // 7. Services running
        if (areServicesRunning(context)) progress++
        
        return (progress * 100) / steps
    }

    private fun hasBasicPermissions(context: Context): Boolean {
        val locationPermission = context.checkSelfPermission(
            android.Manifest.permission.ACCESS_FINE_LOCATION
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
        
        val cameraPermission = context.checkSelfPermission(
            android.Manifest.permission.CAMERA
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
        
        return locationPermission && cameraPermission
    }

    private fun isNotificationListenerEnabled(context: Context): Boolean {
        val pkgName = context.packageName
        val flat = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners"
        )
        return flat?.contains(pkgName) == true
    }

    private fun areServicesRunning(context: Context): Boolean {
        // Check if accessibility service is running
        return MonitoringAccessibilityService.isRunning()
    }

    /**
     * Get user-friendly setup instructions
     */
    fun getSetupInstructions(context: Context): List<SetupStep> {
        val steps = mutableListOf<SetupStep>()
        
        // Step 1: Accessibility Service ⭐ MOST CRITICAL
        steps.add(SetupStep(
            title = "Enable Accessibility Service",
            description = "This is the MOST IMPORTANT step. It allows comprehensive monitoring without constant notifications.",
            isCompleted = isAccessibilityServiceEnabled(context),
            priority = SetupPriority.CRITICAL,
            action = { openAccessibilitySettings(context) }
        ))
        
        // Step 2: Device Admin
        steps.add(SetupStep(
            title = "Activate Device Administrator",
            description = "Prevents the app from being uninstalled and protects monitoring settings.",
            isCompleted = isDeviceAdminEnabled(context),
            priority = SetupPriority.HIGH,
            action = { requestDeviceAdmin(context) }
        ))
        
        // Step 3: Battery Optimization
        steps.add(SetupStep(
            title = "Disable Battery Optimization",
            description = "Ensures the app runs continuously in the background.",
            isCompleted = BatteryOptimizationHelper.isIgnoringBatteryOptimizations(context),
            priority = SetupPriority.HIGH,
            action = { BatteryOptimizationHelper.requestDisableBatteryOptimization(context) }
        ))
        
        // Step 4: Notification Listener
        steps.add(SetupStep(
            title = "Enable Notification Access",
            description = "Allows monitoring of notifications from all apps.",
            isCompleted = isNotificationListenerEnabled(context),
            priority = SetupPriority.MEDIUM,
            action = { 
                val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
            }
        ))
        
        return steps
    }
}

data class SetupStep(
    val title: String,
    val description: String,
    val isCompleted: Boolean,
    val priority: SetupPriority,
    val action: () -> Unit
)

enum class SetupPriority {
    CRITICAL,  // Must have for full functionality
    HIGH,      // Very important
    MEDIUM,    // Important but app can work without it
    LOW        // Optional enhancement
}