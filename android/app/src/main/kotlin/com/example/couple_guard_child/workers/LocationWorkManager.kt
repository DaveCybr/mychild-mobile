package com.example.couple_guard_child.workers

import android.content.Context
import android.util.Log
import androidx.work.*
import java.util.concurrent.TimeUnit

object LocationWorkManager {
    private const val TAG = "LocationWorkManager"
    private const val WORK_NAME = "periodic_location_update"
    private const val INTERVAL_MINUTES = 5L

    fun schedulePeriodicLocationUpdates(context: Context) {
        Log.d(TAG, "========================================")
        Log.d(TAG, "📍 SCHEDULING PERIODIC LOCATION UPDATES")
        Log.d(TAG, "Interval: $INTERVAL_MINUTES minutes")

        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val workRequest = PeriodicWorkRequestBuilder<LocationWorker>(
            INTERVAL_MINUTES, 
            TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.LINEAR,
                WorkRequest.MIN_BACKOFF_MILLIS,  // ✅ FIX: Use WorkRequest instead of PeriodicWorkRequest
                TimeUnit.MILLISECONDS
            )
            .addTag("location_tracking")
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            workRequest
        )

        Log.d(TAG, "✅ Periodic location work scheduled")
        Log.d(TAG, "========================================")
    }

    fun cancelPeriodicLocationUpdates(context: Context) {
        Log.d(TAG, "🛑 Cancelling periodic location updates")
        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        Log.d(TAG, "✅ Periodic work cancelled")
    }

    fun isWorkScheduled(context: Context): Boolean {
        return try {
            val workInfos = WorkManager.getInstance(context)
                .getWorkInfosForUniqueWork(WORK_NAME)
                .get() // ✅ This is blocking call, OK for this use case

            workInfos.any { workInfo ->
                workInfo.state == WorkInfo.State.ENQUEUED || 
                workInfo.state == WorkInfo.State.RUNNING
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking work status", e)
            false
        }
    }
}