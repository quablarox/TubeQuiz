package com.tubequiz.app

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel

class MediaNotificationListenerService : NotificationListenerService() {

    companion object {
        var eventSink: EventChannel.EventSink? = null
        private val SUPPORTED_MUSIC_PACKAGES = setOf(
            "com.google.android.apps.youtube.music",
            "com.amazon.mp3",
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn?.packageName in SUPPORTED_MUSIC_PACKAGES) {
            val extras = sbn.notification.extras
            val title = extras.getString("android.title", "")
            val artist = extras.getString("android.text", "")

            val trackInfo = mapOf(
                "title" to title,
                "artist" to artist,
                "packageName" to sbn.packageName
            )

            eventSink?.success(trackInfo)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (sbn?.packageName in SUPPORTED_MUSIC_PACKAGES) {
            eventSink?.success(mapOf(
                "event" to "trackRemoved",
                "packageName" to sbn?.packageName
            ))
        }
    }
}
