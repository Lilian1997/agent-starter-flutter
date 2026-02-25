package com.livekit.example.VoiceAssistantFlutter

import android.content.Context
import android.content.Intent
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.AudioTrack
import android.media.AudioFormat
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Manager class to output diagnostic audio information.
 */
object AudioChannelManager {
    private const val TAG = "AudioChannelManager"

    /**
     * Dump comprehensive audio device info to /sdcard/audio_diag.txt
     * Call this at app startup to diagnose car head unit audio issues.
     */
    fun dumpAudioInfo(context: Context) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val sb = StringBuilder()
        val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())

        sb.appendLine("=== Audio Diagnostic Report ===")
        sb.appendLine("Timestamp: $timestamp")
        sb.appendLine("Device: ${Build.MANUFACTURER} ${Build.MODEL} (${Build.DEVICE})")
        sb.appendLine("Android: ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})")
        sb.appendLine("Package: ${context.packageName}")
        sb.appendLine()

        // --- Stream Volumes ---
        sb.appendLine("=== Stream Volumes ===")
        val streamNames = mapOf(
            AudioManager.STREAM_VOICE_CALL to "VOICE_CALL (0)",
            AudioManager.STREAM_SYSTEM to "SYSTEM (1)",
            AudioManager.STREAM_RING to "RING (2)",
            AudioManager.STREAM_MUSIC to "MUSIC (3)",
            AudioManager.STREAM_ALARM to "ALARM (4)",
            AudioManager.STREAM_NOTIFICATION to "NOTIFICATION (5)",
            AudioManager.STREAM_DTMF to "DTMF (8)"
        )
        for ((streamType, name) in streamNames) {
            try {
                val vol = audioManager.getStreamVolume(streamType)
                val max = audioManager.getStreamMaxVolume(streamType)
                sb.appendLine("  $name: $vol / $max")
            } catch (e: Exception) {
                sb.appendLine("  $name: ERROR (${e.message})")
            }
        }
        sb.appendLine()

        // --- Audio Mode & State ---
        sb.appendLine("=== Audio Mode & State ===")
        val modeStr = when (audioManager.mode) {
            AudioManager.MODE_NORMAL -> "NORMAL"
            AudioManager.MODE_RINGTONE -> "RINGTONE"
            AudioManager.MODE_IN_CALL -> "IN_CALL"
            AudioManager.MODE_IN_COMMUNICATION -> "IN_COMMUNICATION"
            else -> "UNKNOWN(${audioManager.mode})"
        }
        sb.appendLine("  Mode: $modeStr")
        sb.appendLine("  isSpeakerphoneOn: ${audioManager.isSpeakerphoneOn}")
        sb.appendLine("  isMusicActive: ${audioManager.isMusicActive}")
        sb.appendLine("  isBluetoothScoOn: ${audioManager.isBluetoothScoOn}")
        sb.appendLine("  isBluetoothA2dpOn: ${audioManager.isBluetoothA2dpOn}")
        sb.appendLine("  isWiredHeadsetOn: ${audioManager.isWiredHeadsetOn}")
        sb.appendLine("  isVolumeFixed: ${audioManager.isVolumeFixed}")
        sb.appendLine()

        // --- Native AudioTrack properties ---
        sb.appendLine("=== Native Audio Properties ===")
        val nativeSR = AudioTrack.getNativeOutputSampleRate(AudioManager.STREAM_MUSIC)
        sb.appendLine("  Native output sample rate (MUSIC): $nativeSR Hz")
        val nativeSR_VC = AudioTrack.getNativeOutputSampleRate(AudioManager.STREAM_VOICE_CALL)
        sb.appendLine("  Native output sample rate (VOICE_CALL): $nativeSR_VC Hz")

        // Check minimum buffer sizes for mono and stereo
        val minBufMono = AudioTrack.getMinBufferSize(48000, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
        val minBufStereo = AudioTrack.getMinBufferSize(48000, AudioFormat.CHANNEL_OUT_STEREO, AudioFormat.ENCODING_PCM_16BIT)
        sb.appendLine("  MinBufferSize (48kHz MONO): $minBufMono bytes")
        sb.appendLine("  MinBufferSize (48kHz STEREO): $minBufStereo bytes")
        sb.appendLine()

        // --- Audio Devices (API 23+) ---
        if (Build.VERSION.SDK_INT >= 23) {
            sb.appendLine("=== Output Audio Devices ===")
            val outputDevices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            if (outputDevices.isEmpty()) {
                sb.appendLine("  (none)")
            }
            for (device in outputDevices) {
                val typeName = getDeviceTypeName(device.type)
                val chCounts = device.channelCounts
                val chStr = if (chCounts.isEmpty()) "any" else chCounts.joinToString(",")
                val sampleRates = device.sampleRates
                val srStr = if (sampleRates.isEmpty()) "any" else sampleRates.joinToString(",")
                sb.appendLine("  [${device.id}] $typeName")
                sb.appendLine("       productName: ${device.productName}")
                sb.appendLine("       channels: $chStr")
                sb.appendLine("       sampleRates: $srStr")
                sb.appendLine("       isSink: ${device.isSink}")
            }
            sb.appendLine()

            sb.appendLine("=== Input Audio Devices ===")
            val inputDevices = audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)
            if (inputDevices.isEmpty()) {
                sb.appendLine("  (none)")
            }
            for (device in inputDevices) {
                val typeName = getDeviceTypeName(device.type)
                val chCounts = device.channelCounts
                val chStr = if (chCounts.isEmpty()) "any" else chCounts.joinToString(",")
                sb.appendLine("  [${device.id}] $typeName (channels: $chStr)")
            }
            sb.appendLine()
        }

        // --- Audio Parameters (vendor specific) ---
        sb.appendLine("=== Audio Parameters (vendor) ===")
        val paramsToCheck = listOf(
            "stereo_balance", "audio_channel_balance", "isNaviProcType",
            "ro.hardware.audio.primary", "audio_devices_out"
        )
        for (param in paramsToCheck) {
            try {
                val value = audioManager.getParameters(param)
                sb.appendLine("  $param = ${if (value.isNullOrEmpty()) "(empty)" else value}")
            } catch (e: Exception) {
                sb.appendLine("  $param = ERROR(${e.message})")
            }
        }
        sb.appendLine()

        // --- System Settings related to audio ---
        sb.appendLine("=== System Settings ===")
        try {
            val masterMono = Settings.System.getInt(context.contentResolver, "master_mono", -1)
            sb.appendLine("  master_mono: $masterMono")
        } catch (e: Exception) {
            sb.appendLine("  master_mono: ERROR(${e.message})")
        }

        val report = sb.toString()

        // Output to logcat with ERROR level (always visible)
        Log.e(TAG, "[AUDIO_DIAG] ========== START ==========")
        for (line in report.lines()) {
            Log.e(TAG, "[AUDIO_DIAG] $line")
        }
        Log.e(TAG, "[AUDIO_DIAG] ========== END ==========")
    }

    private fun getDeviceTypeName(type: Int): String {
        return when (type) {
            AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> "BUILTIN_EARPIECE"
            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "BUILTIN_SPEAKER"
            AudioDeviceInfo.TYPE_WIRED_HEADSET -> "WIRED_HEADSET"
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "WIRED_HEADPHONES"
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "BLUETOOTH_SCO"
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "BLUETOOTH_A2DP"
            AudioDeviceInfo.TYPE_HDMI -> "HDMI"
            AudioDeviceInfo.TYPE_USB_DEVICE -> "USB_DEVICE"
            AudioDeviceInfo.TYPE_USB_ACCESSORY -> "USB_ACCESSORY"
            AudioDeviceInfo.TYPE_LINE_ANALOG -> "LINE_ANALOG"
            AudioDeviceInfo.TYPE_LINE_DIGITAL -> "LINE_DIGITAL"
            AudioDeviceInfo.TYPE_AUX_LINE -> "AUX_LINE"
            AudioDeviceInfo.TYPE_BUS -> "BUS"
            else -> "UNKNOWN($type)"
        }
    }
}
