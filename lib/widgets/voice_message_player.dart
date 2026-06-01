import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../config/app_theme.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String voiceUrl;

  const VoiceMessagePlayer({
    super.key,
    required this.voiceUrl,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _hasError = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
          _isLoading = false;
          _hasError = false;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });

    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      if (kDebugMode) {
        final isDataUrl = widget.voiceUrl.startsWith('data:');
        debugPrint('VoicePlayer: Loading audio (isDataUrl: $isDataUrl, len: ${widget.voiceUrl.length})');
      }

      if (widget.voiceUrl.startsWith('data:')) {
        // Data URL — decode base64 and use AsBytes source
        final commaIndex = widget.voiceUrl.indexOf(',');
        if (commaIndex == -1) throw Exception('Invalid data URL format');
        final base64Data = widget.voiceUrl.substring(commaIndex + 1);
        final bytes = base64Decode(base64Data);

        if (kDebugMode) {
          debugPrint('VoicePlayer: Decoded ${(bytes.length / 1024).toStringAsFixed(1)} KB of audio data');
        }

        await _audioPlayer.setSource(BytesSource(Uint8List.fromList(bytes)));
      } else {
        // Network URL
        await _audioPlayer.setSourceUrl(widget.voiceUrl);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('VoicePlayer: Error loading audio: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_hasError) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      await _loadAudio();
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.resume();
        if (mounted) setState(() => _isPlaying = true);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('VoicePlayer: Error playing: $e');
      }
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayPause,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _hasError ? AppColors.error : AppColors.warning,
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _hasError
                          ? Icons.refresh
                          : (_isPlaying ? Icons.pause : Icons.play_arrow),
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),

          const SizedBox(width: 10),

          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasError)
                  const Text(
                    'Ошибка загрузки. Нажмите для повтора.',
                    style: TextStyle(fontSize: 11, color: AppColors.error),
                  )
                else ...[
                  SliderTheme(
                    data: SliderThemeData(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      trackHeight: 3,
                      activeTrackColor: AppColors.warning,
                      inactiveTrackColor: AppColors.warning.withValues(alpha: 0.3),
                      thumbColor: AppColors.warning,
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    ),
                    child: Slider(
                      value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble().clamp(1.0, double.infinity)),
                      max: _duration.inSeconds.toDouble().clamp(1.0, double.infinity),
                      onChanged: (value) async {
                        final position = Duration(seconds: value.toInt());
                        await _audioPlayer.seek(position);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 4),

          const Icon(
            Icons.mic,
            color: AppColors.warning,
            size: 18,
          ),
        ],
      ),
    );
  }
}
