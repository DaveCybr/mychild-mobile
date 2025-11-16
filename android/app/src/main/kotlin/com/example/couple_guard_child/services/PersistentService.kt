package com.example.couple_guard_child.services

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.*
import com.example.couple_guard_child.MainActivity
import com.example.couple_guard_child.R
import com.example.couple_guard_child.utils.ApiClient
import com.example.couple_guard_child.services.NotificationListenerServiceImpl
import com.example.couple_guard_child.workers.LocationWorker
import java.util.concurrent.TimeUnit

class PersistentService : Service() {
    private val TAG = "PersistentService"
    private val NOTIFICATION_ID = 12345
    private val CHANNEL_ID = "persistent_service_channel"
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        private var isRunning = false

        fun isServiceRunning(): Boolean = isRunning

        fun startService(context: Context) {
            val intent = Intent(context, PersistentService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stopService(context: Context) {
            val intent = Intent(context, PersistentService::class.java)
            context.stopService(intent)
        }
    }

    override fun onCreate() {
        super.onCreate()

        Log.d(TAG, "✅ Service onCreate")
        
        // Acquire wake lock to prevent CPU sleep
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "CoupleGuardChild::PersistentWakeLock"
        )
        wakeLock?.acquire(10*60*1000L /*10 minutes*/)
        
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Schedule periodic location worker
        scheduleLocationWorker()
        
        // Update device status to online
        Thread {
            ApiClient.updateDeviceStatus(applicationContext, true)
        }.start()
        
        isRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "✅ Service onStartCommand - flags: $flags, startId: $startId")
        
        // Ensure notification is showing
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Reschedule worker if needed
        scheduleLocationWorker()
        
        // Return START_STICKY to restart service if killed
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.w(TAG, "⚠️ Service onDestroy - attempting restart")
        
        isRunning = false
        
        // Release wake lock
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        
        // Update device status to offline
        Thread {
            ApiClient.updateDeviceStatus(applicationContext, false)
        }.start()
        
        // Cancel location worker
        WorkManager.getInstance(applicationContext)
            .cancelUniqueWork("location_worker")
        
        // Restart service
        val restartIntent = Intent(applicationContext, PersistentService::class.java)
        val pendingIntent = PendingIntent.getService(
            applicationContext,
            1,
            restartIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.set(
            AlarmManager.RTC_WAKEUP,
            System.currentTimeMillis() + 1000,
            pendingIntent
        )
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.w(TAG, "⚠️ Task removed - restarting service")
        
        // Restart service when app is swiped away
        val restartIntent = Intent(applicationContext, PersistentService::class.java)
        val pendingIntent = PendingIntent.getService(
            applicationContext,
            1,
            restartIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.set(
            AlarmManager.RTC_WAKEUP,
            System.currentTimeMillis() + 1000,
            pendingIntent
        )
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Location & Notification Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the app running to monitor location and notifications"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
            
            Log.d(TAG, "✅ Notification channel created")
        }
    }

    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Couple Guard")
            .setContentText("Monitoring location and notifications")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    private fun scheduleLocationWorker() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val locationWorkRequest = PeriodicWorkRequestBuilder<LocationWorker>(
            5, TimeUnit.MINUTES,
            5, TimeUnit.MINUTES // flex interval
        )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.LINEAR,
                WorkRequest.MIN_BACKOFF_MILLIS,
                TimeUnit.MILLISECONDS
            )
            .addTag("location_tracking")
            .build()

        WorkManager.getInstance(applicationContext)
            .enqueueUniquePeriodicWork(
                "location_worker",
                ExistingPeriodicWorkPolicy.KEEP,
                locationWorkRequest
            )

        Log.d(TAG, "✅ Location worker scheduled (15-minute intervals)")
    }
}