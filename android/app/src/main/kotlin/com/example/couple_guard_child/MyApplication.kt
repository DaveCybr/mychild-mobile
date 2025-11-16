package com.example.couple_guard_child

import android.app.Application
import android.util.Log
import androidx.work.Configuration

class MyApplication : Application(), Configuration.Provider {
    private val TAG = "MyApplication"

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "✅ Application onCreate")
        
        // Initialize Firebase
        try {
            com.google.firebase.FirebaseApp.initializeApp(this)
            Log.d(TAG, "✅ Firebase initialized")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Firebase initialization failed", e)
        }
    }

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setMinimumLoggingLevel(Log.DEBUG)
            .build()
}