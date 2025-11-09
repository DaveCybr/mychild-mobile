package com.example.couple_guard_child

import android.content.Context

object NativeBridge {
    private const val PREF = "child_prefs"
    private const val KEY_DEVICE_ID = "device_id"

    fun setDeviceId(ctx: Context, id: String) {
        val sp = ctx.getSharedPreferences(PREF, Context.MODE_PRIVATE)
        sp.edit().putString(KEY_DEVICE_ID, id).apply()
    }

    fun getDeviceId(ctx: Context): String? {
        val sp = ctx.getSharedPreferences(PREF, Context.MODE_PRIVATE)
        return sp.getString(KEY_DEVICE_ID, null)
    }
}
