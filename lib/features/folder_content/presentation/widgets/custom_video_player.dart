import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  final String videoPath;

  const CustomVideoPlayer({super.key, required this.videoPath});

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(File(widget.videoPath));

    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });

      _controller.addListener(() {
        setState(() {
          _isPlaying = _controller.value.isPlaying;
        });
      });
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
        _startHideControlsTimer();
      }
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    if (_controller.value.isPlaying) {
      _startHideControlsTimer();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Loading video...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _showControlsTemporarily,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),

            // Controls overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: _showControls ? _buildControls() : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: [0.0, 0.2, 0.8, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top bar with title
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.video_library_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Video Player',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center play/pause button
          _buildCenterPlayButton(),

          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildCenterPlayButton() {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: Color(0xFF4361EE),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Color(0xFF4361EE).withOpacity(0.3),
                  ),
                  child: Slider(
                    value: position.inMilliseconds.toDouble().clamp(
                      0.0,
                      duration.inMilliseconds.toDouble(),
                    ),
                    min: 0.0,
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _controller.seekTo(Duration(milliseconds: value.toInt()));
                    },
                    onChangeStart: (_) {
                      _hideControlsTimer?.cancel();
                    },
                    onChangeEnd: (_) {
                      if (_controller.value.isPlaying) {
                        _startHideControlsTimer();
                      }
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rewind 10s
              _buildControlButton(
                icon: Icons.replay_10_rounded,
                onTap: () {
                  final newPosition = position - Duration(seconds: 10);
                  _controller.seekTo(
                    newPosition < Duration.zero ? Duration.zero : newPosition,
                  );
                },
              ),

              SizedBox(width: 32),

              // Play/Pause
              _buildControlButton(
                icon: _isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                onTap: _togglePlayPause,
                size: 40,
              ),

              SizedBox(width: 32),

              // Forward 10s
              _buildControlButton(
                icon: Icons.forward_10_rounded,
                onTap: () {
                  final newPosition = position + Duration(seconds: 10);
                  _controller.seekTo(
                    newPosition > duration ? duration : newPosition,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 32,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
