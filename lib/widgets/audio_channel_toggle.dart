import 'package:flutter/material.dart';

import '../support/audio_channel_service.dart';

/// A toggle widget to control audio channel routing.
/// Allows users to switch between left, right, and stereo audio output.
class AudioChannelToggle extends StatefulWidget {
  const AudioChannelToggle({super.key});

  @override
  State<AudioChannelToggle> createState() => _AudioChannelToggleState();
}

class _AudioChannelToggleState extends State<AudioChannelToggle> with WidgetsBindingObserver {
  AudioChannelMode _currentMode = AudioChannelMode.stereo;
  bool _isLoading = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentState();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  // Re-check permission when app resumes (user returns from settings)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCurrentState();
    }
  }

  Future<void> _loadCurrentState() async {
    final permission = await AudioChannelService.canWriteSettings();
    final current = await AudioChannelService.getAudioChannelMode();
    if (mounted) {
      setState(() {
        _hasPermission = permission;
        _currentMode = current;
      });
    }
  }

  Future<void> _setMode(AudioChannelMode mode) async {
    if (mode == _currentMode) return;
    
    // Check permission first
    if (!_hasPermission) {
      _showPermissionDialog();
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    final success = await AudioChannelService.setAudioChannelMode(mode);
    
    if (mounted) {
      setState(() {
        if (success) {
          _currentMode = mode;
        }
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? '已切換到${_getModeLabel(mode)}' 
            : '無法更改音頻設定'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  String _getModeLabel(AudioChannelMode mode) {
    switch (mode) {
      case AudioChannelMode.left:
        return '左聲道';
      case AudioChannelMode.right:
        return '右聲道';
      case AudioChannelMode.stereo:
        return '立體聲';
    }
  }
  
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('需要系統權限'),
        content: const Text(
          '要控制音頻聲道，需要「修改系統設定」權限。\n\n'
          '點擊「前往設定」後，請開啟「允許修改系統設定」選項。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              AudioChannelService.openWriteSettingsPermission();
            },
            child: const Text('前往設定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.speaker_group,
            color: colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '音頻輸出',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!_hasPermission)
            GestureDetector(
              onTap: _showPermissionDialog,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.warning_amber, color: Colors.orange, size: 14),
              ),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          const SizedBox(width: 12),
          // Circular buttons
          _buildModeButton(
            mode: AudioChannelMode.left,
            icon: Icons.arrow_back,
          ),
          const SizedBox(width: 6),
          _buildModeButton(
            mode: AudioChannelMode.stereo,
            icon: Icons.surround_sound,
          ),
          const SizedBox(width: 6),
          _buildModeButton(
            mode: AudioChannelMode.right,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }
  Widget _buildModeButton({
    required AudioChannelMode mode,
    required IconData icon,
  }) {
    final isSelected = _currentMode == mode;
    final colorScheme = Theme.of(context).colorScheme;
    final size = 32.0;
    
    return GestureDetector(
      onTap: _isLoading ? null : () => _setMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected 
              ? colorScheme.primary 
              : colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary 
                : colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            size: 14,
          ),
        ),
      ),
    );
  }
}
