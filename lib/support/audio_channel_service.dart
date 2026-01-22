import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

/// Audio channel mode options
enum AudioChannelMode {
  stereo,  // Normal stereo output
  left,    // Left channel only
  right,   // Right channel only
}

/// Service to control audio channel routing on Android.
/// Allows routing all audio to left channel, right channel, or stereo.
class AudioChannelService {
  static const MethodChannel _channel = MethodChannel('audio_channel');
  static final _logger = Logger('AudioChannelService');
  
  /// Check if the app has WRITE_SETTINGS permission (needed for audio routing)
  static Future<bool> canWriteSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('canWriteSettings');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return true; // Assume permission granted on non-Android platforms
    }
  }
  
  /// Open system settings to grant WRITE_SETTINGS permission
  static Future<void> openWriteSettingsPermission() async {
    try {
      await _channel.invokeMethod('openWriteSettingsPermission');
    } on PlatformException catch (e) {
      _logger.warning('Failed to open settings: ${e.message}');
    } on MissingPluginException {
      _logger.warning('openWriteSettingsPermission not available on this platform');
    }
  }
  
  /// Set the audio channel mode.
  /// 
  /// [mode] can be stereo, left, or right.
  /// This only works on Android. On other platforms, this is a no-op.
  static Future<bool> setAudioChannelMode(AudioChannelMode mode) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setAudioChannelMode', 
        {'mode': mode.name},
      );
      _logger.info('Audio channel mode set to: ${mode.name}, result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      _logger.warning('Failed to set audio channel mode: ${e.message}');
      return false;
    } on MissingPluginException {
      _logger.warning('AudioChannelService not available on this platform');
      return false;
    }
  }
  
  /// Get the current audio channel mode.
  static Future<AudioChannelMode> getAudioChannelMode() async {
    try {
      final result = await _channel.invokeMethod<String>('getAudioChannelMode');
      return AudioChannelMode.values.firstWhere(
        (m) => m.name == result,
        orElse: () => AudioChannelMode.stereo,
      );
    } on PlatformException {
      return AudioChannelMode.stereo;
    } on MissingPluginException {
      return AudioChannelMode.stereo;
    }
  }
  
  // Legacy methods for backwards compatibility
  static Future<bool> setLeftChannelOnly(bool enabled) async {
    return setAudioChannelMode(enabled ? AudioChannelMode.left : AudioChannelMode.stereo);
  }
  
  static Future<bool> isLeftChannelOnly() async {
    final mode = await getAudioChannelMode();
    return mode == AudioChannelMode.left;
  }
}
