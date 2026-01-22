package com.livekit.example.VoiceAssistantFlutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "audio_channel"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setAudioChannelMode" -> {
                        val modeStr = call.argument<String>("mode") ?: "stereo"
                        val mode = when (modeStr.lowercase()) {
                            "left" -> AudioChannelMode.LEFT
                            "right" -> AudioChannelMode.RIGHT
                            else -> AudioChannelMode.STEREO
                        }
                        val success = AudioChannelManager.setAudioChannelMode(this, mode)
                        result.success(success)
                    }
                    "getAudioChannelMode" -> {
                        val mode = AudioChannelManager.getAudioChannelMode()
                        result.success(mode.name.lowercase())
                    }
                    "canWriteSettings" -> {
                        result.success(AudioChannelManager.canWriteSettings(this))
                    }
                    "openWriteSettingsPermission" -> {
                        AudioChannelManager.openWriteSettingsPermission(this)
                        result.success(true)
                    }
                    // Legacy methods
                    "setLeftChannelOnly" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val success = AudioChannelManager.setLeftChannelOnly(this, enabled)
                        result.success(success)
                    }
                    "isLeftChannelOnly" -> {
                        result.success(AudioChannelManager.isLeftChannelOnly())
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
