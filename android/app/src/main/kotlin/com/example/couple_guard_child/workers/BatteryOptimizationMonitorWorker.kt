package com.example.couple_guard_child.workers

import android.content.Context
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.ExistingPeriodicWorkPolicy
import java.util.concurrent.TimeUnit

/**
 * BatteryOptimizationMonitorWorker
 * Monitor & alert jika battery optimization diaktifkan kembali
 */
class BatteryOptimizationMonitorWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        private const val TAG = "BatteryOptMonitor"
        private const val WORK_NAME = "battery_opt_monitor"
        
        fun schedule(context: Context) {
            val workRequest = PeriodicWorkRequestBuilder<BatteryOptimizationMonitorWorker>(
                1, TimeUnit.HOURS // Check every hour
            ).build()
            
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                workRequest
            )
            
            Log.d(TAG, "✅ Battery optimization monitor scheduled")
        }
    }

    override suspend fun doWork(): Result {
        Log.d(TAG, "========================================")
        Log.d(TAG, "🔋 CHECKING BATTERY OPTIMIZATION STATUS")
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = applicationContext.getSystemService(
                    Context.POWER_SERVICE
                ) as PowerManager
                
                val isIgnoring = powerManager.isIgnoringBatteryOptimizations(
                    applicationContext.packageName
                )
                
                Log.d(TAG, "Battery optimization ignored: $isIgnoring")
                
                if (!isIgnoring) {
                    Log.w(TAG, "⚠️ CRITICAL: Battery optimization is ENABLED!")
                    Log.w(TAG, "Services may be killed by system!")
                    
                    // ✅ Send notification to user
                    sendBatteryOptimizationAlert()
                    
                    // ✅ Try to request again (will open settings)
                    // requestBatteryOptimizationAgain()
                }
            }
            
            Log.d(TAG, "========================================")
            return Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error checking battery optimization", e)
            return Result.failure()
        }
    }
    
    private fun sendBatteryOptimizationAlert() {
        // TODO: Show notification to user
        Log.w(TAG, "Sending battery optimization alert to user")
    }
}