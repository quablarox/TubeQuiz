package com.tubequiz.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.os.Bundle
import android.provider.Settings
import android.view.KeyEvent

class MainActivity : FlutterActivity() {
    private val methodChannelName = "com.tubequiz.app/media_control"
    private val eventChannelName = "com.tubequiz.app/media_events"
    private var savedMusicVolume: Int? = null

    companion object {
        private const val DUCK_VOLUME_FRACTION = 0.2
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isNotificationListenerEnabled" -> {
                        result.success(isNotificationServiceEnabled())
                    }
                    "openNotificationListenerSettings" -> {
                        openNotificationSettings()
                        result.success(true)
                    }
                    "getCurrentTrack" -> {
                        val track = getCurrentPlayingTrack()
                        result.success(track)
                    }
                    "seekTo" -> {
                        val position = call.argument<Long>("position")
                        if (position == null) {
                            result.error("INVALID_ARGUMENT", "position argument is required", null)
                        } else {
                            seekTo(position)
                            result.success(true)
                        }
                    }
                    "skipToNext" -> {
                        skipToNext()
                        result.success(true)
                    }
                    "play" -> {
                        play()
                        result.success(true)
                    }
                    "pause" -> {
                        pause()
                        result.success(true)
                    }
                    "duckAudio" -> {
                        duckAudio()
                        result.success(true)
                    }
                    "restoreAudio" -> {
                        restoreAudio()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    MediaNotificationListenerService.eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    MediaNotificationListenerService.eventSink = null
                }
            })
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val flat = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )
        return flat != null && flat.contains(
            ComponentName(this, MediaNotificationListenerService::class.java).flattenToString()
        )
    }

    private fun openNotificationSettings() {
        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
    }

    private fun getYouTubeMusicController(): MediaController? {
        try {
            val mediaSessionManager = getSystemService(MEDIA_SESSION_SERVICE) as MediaSessionManager
            val component = ComponentName(this, MediaNotificationListenerService::class.java)
            val controllers = mediaSessionManager.getActiveSessions(component)
            return controllers.firstOrNull { controller ->
                controller.packageName == "com.google.android.apps.youtube.music"
            }
        } catch (e: SecurityException) {
            return null
        }
    }

    private fun getCurrentPlayingTrack(): Map<String, Any?>? {
        val controller = getYouTubeMusicController() ?: return null
        val metadata = controller.metadata ?: return null
        val playbackState = controller.playbackState

        return mapOf(
            "title" to (metadata.getString(android.media.MediaMetadata.METADATA_KEY_TITLE) ?: ""),
            "artist" to (metadata.getString(android.media.MediaMetadata.METADATA_KEY_ARTIST) ?: ""),
            "duration" to (metadata.getLong(android.media.MediaMetadata.METADATA_KEY_DURATION)),
            "position" to (playbackState?.position ?: 0L),
            "isPlaying" to (playbackState?.state == android.media.session.PlaybackState.STATE_PLAYING)
        )
    }

    private fun seekTo(position: Long) {
        val controller = getYouTubeMusicController()
        controller?.transportControls?.seekTo(position)
    }

    private fun skipToNext() {
        val controller = getYouTubeMusicController()
        controller?.transportControls?.skipToNext()
    }

    private fun play() {
        val controller = getYouTubeMusicController()
        controller?.transportControls?.play()
    }

    private fun pause() {
        val controller = getYouTubeMusicController()
        controller?.transportControls?.pause()
    }

    private fun duckAudio() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        savedMusicVolume = currentVolume
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val duckedVolume = (maxVolume * DUCK_VOLUME_FRACTION).toInt().coerceAtLeast(1)
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, duckedVolume, 0)
    }

    private fun restoreAudio() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val volume = savedMusicVolume
        if (volume != null) {
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, volume, 0)
            savedMusicVolume = null
        }
    }
}
