package com.example.couple_guard_child.workers

import android.content.Context
import android.util.Log
import androidx.work.*
import java.util.concurrent.TimeUnit

object LocationWorkManager {
    private const val TAG = "LocationWorkManager"
    private const val WORK_NAME = "periodic_location_update"
    private const val ONE_TIME_WORK_NAME = "immediate_location_update"
    private const val WATCHDOG_WORK_NAME = "service_watchdog" // ✨ NEW
    private const val INTERVAL_MINUTES = 30L
    private const val FLEX_INTERVAL_MINUTES = 5L
    private const val WATCHDOG_INTERVAL_MINUTES = 15L // ✨ NEW

    fun schedulePeriodicLocationUpdates(context: Context) {
        Log.d(TAG, "========================================")
        Log.d(TAG, "📍 SCHEDULING PERIODIC LOCATION UPDATES")
        Log.d(TAG, "Interval: $INTERVAL_MINUTES minutes")

        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .setRequiresBatteryNotLow(false)
            .build()

        val workRequest = PeriodicWorkRequestBuilder<LocationWorker>(
            INTERVAL_MINUTES, TimeUnit.MINUTES,
            FLEX_INTERVAL_MINUTES, TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.EXPONENTIAL,
                WorkRequest.MIN_BACKOFF_MILLIS,
                TimeUnit.MILLISECONDS
            )
            .addTag("location_tracking")
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            workRequest
        )

        Log.d(TAG, "✅ Periodic work scheduled")
        
        scheduleImmediateLocationUpdate(context)
        
        // ✨ NEW: Schedule watchdog
        scheduleWatchdog(context)
        
        Log.d(TAG, "========================================")
    }
    
    fun scheduleImmediateLocationUpdate(context: Context) {
        Log.d(TAG, "📍 Scheduling IMMEDIATE location update...")
        
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()
        
        val immediateWork = OneTimeWorkRequestBuilder<LocationWorker>()
            .setConstraints(constraints)
            .addTag("immediate_location")
            .build()
        
        WorkManager.getInstance(context).enqueueUniqueWork(
            ONE_TIME_WORK_NAME,
            ExistingWorkPolicy.REPLACE,
            immediateWork
        )
        
        Log.d(TAG, "✅ Immediate work enqueued")
    }

    // ✨ NEW: Schedule watchdog untuk monitor & restart services
    fun scheduleWatchdog(context: Context) {
        Log.d(TAG, "🐕 Scheduling Service Watchdog...")
        Log.d(TAG, "Watchdog interval: $WATCHDOG_INTERVAL_MINUTES minutes")

        val constraints = Constraints.Builder()
            .setRequiresBatteryNotLow(false) // Run even on low battery
            .setRequiresStorageNotLow(false) // Run even on low storage
            .build()

        val watchdogRequest = PeriodicWorkRequestBuilder<ServiceWatchdogWorker>(
            WATCHDOG_INTERVAL_MINUTES, TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.LINEAR,
                WorkRequest.MIN_BACKOFF_MILLIS,
                TimeUnit.MILLISECONDS
            )
            .addTag("service_watchdog")
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WATCHDOG_WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP, // Keep existing schedule
            watchdogRequest
        )

        Log.d(TAG, "✅ Watchdog scheduled")
    }

    fun cancelPeriodicLocationUpdates(context: Context) {
        Log.d(TAG, "🛑 Cancelling all location updates")
        WorkManager.getInstance(context).apply {
            cancelUniqueWork(WORK_NAME)
            cancelUniqueWork(ONE_TIME_WORK_NAME)
            cancelUniqueWork(WATCHDOG_WORK_NAME) // ✨ NEW
            cancelAllWorkByTag("location_tracking")
            cancelAllWorkByTag("service_watchdog") // ✨ NEW
        }
        Log.d(TAG, "✅ All location work cancelled")
    }

    fun isWorkScheduled(context: Context): Boolean {
        return try {
            val workInfos = WorkManager.getInstance(context)
                .getWorkInfosForUniqueWork(WORK_NAME)
                .get()

            val isScheduled = workInfos.any { workInfo ->
                workInfo.state == WorkInfo.State.ENQUEUED || 
                workInfo.state == WorkInfo.State.RUNNING
            }
            
            Log.d(TAG, "Periodic work scheduled: $isScheduled")
            
            if (isScheduled) {
                workInfos.forEach { info ->
                    Log.d(TAG, "Work state: ${info.state}")
                    Log.d(TAG, "Run attempt: ${info.runAttemptCount}")
                }
            }
            
            isScheduled
        } catch (e: Exception) {
            Log.e(TAG, "Error checking work status", e)
            false
        }
    }
    
    // ✨ NEW: Check watchdog status
    fun isWatchdogScheduled(context: Context): Boolean {
        return try {
            val workInfos = WorkManager.getInstance(context)
                .getWorkInfosForUniqueWork(WATCHDOG_WORK_NAME)
                .get()

            workInfos.any { workInfo ->
                workInfo.state == WorkInfo.State.ENQUEUED || 
                workInfo.state == WorkInfo.State.RUNNING
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking watchdog status", e)
            false
        }
    }
    
    fun getWorkStatus(context: Context): String {
        return try {
            val workInfos = WorkManager.getInstance(context)
                .getWorkInfosForUniqueWork(WORK_NAME)
                .get()
            
            if (workInfos.isEmpty()) {
                "No work scheduled"
            } else {
                workInfos.joinToString("\n") { info ->
                    "State: ${info.state}, Attempts: ${info.runAttemptCount}"
                }
            }
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }
}