package com.livekit.example.VoiceAssistantFlutter

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.provider.Settings
import android.util.Log

/**
 * Audio channel mode options
 */
enum class AudioChannelMode {
    STEREO,  // Normal stereo output
    LEFT,    // Left channel only
    RIGHT    // Right channel only
}

/**
 * Manager class to control audio channel routing.
 * Provides functionality to route audio to left channel, right channel, or stereo.
 */
object AudioChannelManager {
    private const val TAG = "AudioChannelManager"
    private var currentMode = AudioChannelMode.STEREO
    
    /**
     * Check if the app has WRITE_SETTINGS permission
     */
    fun canWriteSettings(context: Context): Boolean {
        return Settings.System.canWrite(context)
    }
    
    /**
     * Open system settings to grant WRITE_SETTINGS permission
     */
    fun openWriteSettingsPermission(context: Context) {
        val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
            data = Uri.parse("package:${context.packageName}")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(intent)
    }
    
    /**
     * Set the audio channel mode.
     * 
     * @param context Android context
     * @param mode The desired audio channel mode
     * @return True if setting was applied successfully
     */
    fun setAudioChannelMode(context: Context, mode: AudioChannelMode): Boolean {
        currentMode = mode
        Log.d(TAG, "Setting audio channel mode: $mode")
        
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        var success = false
        
        // Get balance value based on mode
        // -1.0 = full left, 0.0 = center, 1.0 = full right
        val balance = when (mode) {
            AudioChannelMode.LEFT -> "-1.0"
            AudioChannelMode.RIGHT -> "1.0"
            AudioChannelMode.STEREO -> "0.0"
        }
        
        // Method 1: Try to set volume balance using setParameters
        try {
            audioManager.setParameters("stereo_balance=$balance")
            Log.d(TAG, "Set stereo balance to $balance via setParameters")
            success = true
        } catch (e: Exception) {
            Log.w(TAG, "Could not set stereo balance: ${e.message}")
        }
        
        // Method 2: Try using audio_channel_balance (some devices use this)
        try {
            audioManager.setParameters("audio_channel_balance=$balance")
            Log.d(TAG, "Set audio_channel_balance to $balance")
            success = true
        } catch (e: Exception) {
            Log.w(TAG, "Could not set audio_channel_balance: ${e.message}")
        }
        
        // Method 3: Set mono audio (requires WRITE_SETTINGS permission)
        if (canWriteSettings(context)) {
            try {
                val isMono = mode != AudioChannelMode.STEREO
                Settings.System.putInt(
                    context.contentResolver,
                    "master_mono",  // Use string directly as MASTER_MONO constant may not exist
                    if (isMono) 1 else 0
                )
                Log.d(TAG, "Set master_mono to ${if (isMono) 1 else 0}")
                success = true
            } catch (e: Exception) {
                Log.e(TAG, "Error setting master_mono: ${e.message}")
            }
        } else {
            Log.w(TAG, "WRITE_SETTINGS permission not granted - need to request from user")
        }
        
        return success
    }
    
    /**
     * Get the current audio channel mode.
     */
    fun getAudioChannelMode(): AudioChannelMode {
        return currentMode
    }
    
    // Legacy method for backwards compatibility
    fun setLeftChannelOnly(context: Context, enabled: Boolean): Boolean {
        return setAudioChannelMode(context, if (enabled) AudioChannelMode.LEFT else AudioChannelMode.STEREO)
    }
    
    fun isLeftChannelOnly(): Boolean {
        return currentMode == AudioChannelMode.LEFT
    }
}
