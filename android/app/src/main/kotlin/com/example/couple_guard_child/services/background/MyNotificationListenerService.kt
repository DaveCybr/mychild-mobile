package com.example.couple_guard_child.services.background

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import org.json.JSONObject
import java.io.IOException

class MyNotificationListenerService : NotificationListenerService() {

    private val client = OkHttpClient()

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn?.let {
            val pkg = it.packageName
            val extras = it.notification.extras

            val title = extras.getString("android.title", "")
            val text = extras.getCharSequence("android.text", "")?.toString() ?: ""

            Log.d("MyNotifService", "Notif dari $pkg : $title - $text")

            val payload = JSONObject().apply {
                put("device_id", "CHILD-123") // bisa ambil dari sharedPref / unique device ID
                put("app_name", pkg)
                put("title", title)
                put("content", text)
                put("timestamp", System.currentTimeMillis()) // timestamp sekarang
            }

            // Ganti URL sesuai endpoint Laravel API kamu
            val url = "https://parentalcontrol.satelliteorbit.cloud/api/device/notifications"

            val body = RequestBody.create(
                "application/json; charset=utf-8".toMediaTypeOrNull(),
                payload.toString()
            )
            val request = Request.Builder()
                .url(url)
                .post(body)
                .build()

            client.newCall(request).enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    Log.e("MyNotifService", "Gagal kirim ke API: ${e.message}")
                }

                override fun onResponse(call: Call, response: Response) {
                    if (response.isSuccessful) {
                        Log.d("MyNotifService", "Notif berhasil dikirim ke API")
                    } else {
                        Log.e("MyNotifService", "Response gagal: ${response.code}")
                    }
                }
            })
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // optional, kalau mau kirim event saat notif dihapus
    }
}
