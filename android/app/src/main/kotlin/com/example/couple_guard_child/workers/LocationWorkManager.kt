package com.example.couple_guard_child.workers

import android.content.Context
import android.util.Log
import androidx.work.*
import java.util.concurrent.TimeUnit

object LocationWorkManager {
    private const val TAG = "LocationWorkManager"
    private const val WORK_NAME = "periodic_location_update"
    private const val ONE_TIME_WORK_NAME = "immediate_location_update"
    private const val INTERVAL_MINUTES = 30L
    private const val FLEX_INTERVAL_MINUTES = 5L

    fun schedulePeriodicLocationUpdates(context: Context) {
        Log.d(TAG, "========================================")
        Log.d(TAG, "📍 SCHEDULING PERIODIC LOCATION UPDATES")
        Log.d(TAG, "Interval: $INTERVAL_MINUTES minutes")

        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .setRequiresBatteryNotLow(false) // ✅ Work even on low battery
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
            ExistingPeriodicWorkPolicy.UPDATE, // ✅ CHANGED: UPDATE instead of KEEP
            workRequest
        )

        Log.d(TAG, "✅ Periodic work scheduled")
        
        // ✅ ADD: Schedule immediate one-time work for first location
        scheduleImmediateLocationUpdate(context)
        
        Log.d(TAG, "========================================")
    }
    
    // ✅ NEW: Immediate location update
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

    fun cancelPeriodicLocationUpdates(context: Context) {
        Log.d(TAG, "🛑 Cancelling all location updates")
        WorkManager.getInstance(context).apply {
            cancelUniqueWork(WORK_NAME)
            cancelUniqueWork(ONE_TIME_WORK_NAME)
            cancelAllWorkByTag("location_tracking")
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
    
    // ✅ NEW: Get work status details
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