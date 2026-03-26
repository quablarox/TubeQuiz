package com.tubequiz.app

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel

class MediaNotificationListenerService : NotificationListenerService() {

    companion object {
        var eventSink: EventChannel.EventSink? = null
        private const val YOUTUBE_MUSIC_PACKAGE = "com.google.android.apps.youtube.music"
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn?.packageName == YOUTUBE_MUSIC_PACKAGE) {
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
        if (sbn?.packageName == YOUTUBE_MUSIC_PACKAGE) {
            eventSink?.success(mapOf(
                "event" to "trackRemoved",
                "packageName" to YOUTUBE_MUSIC_PACKAGE
            ))
        }
    }
}
