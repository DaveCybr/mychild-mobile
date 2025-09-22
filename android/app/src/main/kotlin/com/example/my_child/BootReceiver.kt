package com.example.my_child

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            
            // Check if app setup is completed
            val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val permissionSetupCompleted = sharedPrefs.getBoolean("flutter.permission_setup_completed", false)
            
            if (permissionSetupCompleted) {
                // Start background service
                val serviceIntent = Intent(context, FamilyTrackingService::class.java)
                ContextCompat.startForegroundService(context, serviceIntent)
            }
        }
    }
}