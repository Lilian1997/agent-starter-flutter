package com.livekit.example.VoiceAssistantFlutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "audio_channel"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 啟用 WebRTC log 輸出到 logcat（用反射避免 compile 依賴問題）
        try {
            val loggingClass = Class.forName("org.webrtc.Logging")
            val severityClass = Class.forName("org.webrtc.Logging\$Severity")
            val severityValues = severityClass.enumConstants as Array<*>
            // LS_INFO is typically index 2 (LS_VERBOSE=0, LS_INFO=1... or similar)
            
            // 重要：必須先載入 native library，否則會報 UnsatisfiedLinkError
            try {
                System.loadLibrary("jingle_peerconnection_so")
                Log.w("MainActivity", "Loaded jingle_peerconnection_so successfully")
            } catch (e: UnsatisfiedLinkError) {
                // 如果失敗有可能已經載入過了，或者名字不一樣
                Log.e("MainActivity", "Failed to load jingle_peerconnection_so: ${e.message}")
            }

            val lsInfo = severityValues.firstOrNull { it.toString() == "LS_INFO" } 
                ?: severityValues.getOrNull(1) // Fallback to index 1 (usually LS_INFO or LS_WARNING)
                ?: severityValues.firstOrNull()
            
            if (lsInfo != null) {
                val enableMethod = loggingClass.getMethod("enableLogToDebugOutput", severityClass)
                enableMethod.invoke(null, lsInfo)
                Log.w("MainActivity", "WebRTC Logging enabled successfully with severity: $lsInfo")
            } else {
                Log.e("MainActivity", "Could not find valid Logging.Severity value")
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to enable WebRTC logging", e)
        }

        // Dump audio device info to /sdcard/audio_diag.txt for diagnostics
        try {
            AudioChannelManager.dumpAudioInfo(this)
            Log.e("MainActivity", "Audio diagnostic dump completed")
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to dump audio info: ${e.message}")
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "dumpAudioInfo" -> {
                        AudioChannelManager.dumpAudioInfo(this)
                        result.success(null)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
