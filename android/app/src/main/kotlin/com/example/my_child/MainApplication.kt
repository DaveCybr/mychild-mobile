package com.example.my_child

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.work.Configuration
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication(), Configuration.Provider {

    override fun onCreate() {
        super.onCreate()

        // Create notification channels for background services & general notifications
        createNotificationChannels()
    }

    // WorkManager configuration (no manual initialize needed)
    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setMinimumLoggingLevel(android.util.Log.INFO)
            .build()

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            // ✅ Sinkron dengan Dart (FlutterBackgroundService pakai "family_tracking_channel")
            val familyTrackingChannel = NotificationChannel(
                "family_tracking_channel",
                "Family Tracking Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background service for family tracking"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
            }

            // Opsional: channel tambahan untuk notifikasi umum
            val generalChannel = NotificationChannel(
                "general_notifications",
                "General Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "General app notifications"
            }

            // Daftarkan ke sistem
            notificationManager.createNotificationChannel(familyTrackingChannel)
            notificationManager.createNotificationChannel(generalChannel)
        }
    }
}
