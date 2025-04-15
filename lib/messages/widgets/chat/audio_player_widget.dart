import 'dart:math';
import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/messages/schema/message_schema.dart';
import 'package:campus_conn/messages/utils/audio_utils.dart';
import 'package:campus_conn/messages/utils/message_formatter.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

/// A beautiful, animated audio player for voice messages
class AudioPlayerWidget extends StatefulWidget {
  /// The audio message
  final Message message;

  /// Whether this message is from the current user
  final bool isMe;

  /// Callback for playing audio
  final Function(String)? onPlayAudio;

  /// Constructor
  const AudioPlayerWidget({
    Key? key,
    required this.message,
    required this.isMe,
    this.onPlayAudio,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with SingleTickerProviderStateMixin {
  late final AudioUtils _audioUtils;
  late AnimationController _waveformAnimationController;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // For waveform visualization
  final List<double> _waveformHeights = [];

  @override
  void initState() {
    super.initState();
    _audioUtils = AudioUtils();

    // Initialize animation controller for waveform
    _waveformAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Generate random waveform heights (would be real data in production)
    _generateWaveformData();

    // Initialize audio
    _initializeAudio();
  }

  @override
  void dispose() {
    _waveformAnimationController.dispose();
    super.dispose();
  }

  /// Initialize audio player
  Future<void> _initializeAudio() async {
    await _audioUtils.initialize();

    // Listen for position updates
    _audioUtils.positionStream?.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Check if this message is currently playing
    _updatePlaybackState();
  }

  /// Update playback state
  void _updatePlaybackState() {
    final isPlaying = _audioUtils.currentlyPlayingId == widget.message.id;

    if (isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
        if (_isPlaying) {
          // Start waveform animation when playing
          _waveformAnimationController.repeat(reverse: true);

          // Get duration
          _duration = _audioUtils.duration ?? Duration.zero;
        } else {
          // Pause waveform animation when not playing
          _waveformAnimationController.stop();
        }
      });
    }
  }

  /// Generate random waveform data
  void _generateWaveformData() {
    // In a real app, this would be actual audio data
    _waveformHeights.clear();

    // Generate 20 random heights
    final random = Random();
    for (int i = 0; i < 20; i++) {
      // Create a natural looking waveform pattern
      double normalizedPosition = i / 20; // 0.0 to 1.0

      // Create a "bell curve" like pattern
      double amplitude = 0.3 + 0.7 * (1 - (2 * normalizedPosition - 1).abs());

      // Add some randomness
      amplitude += random.nextDouble() * 0.3;

      // Clamp to reasonable values
      amplitude = amplitude.clamp(0.2, 1.0);

      _waveformHeights.add(amplitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Regularly update playback state
    _updatePlaybackState();

    // Choose colors based on sender
    final Color primaryColor =
        widget.isMe ? Colors.white : AppTheme.primaryColor;
    final Color backgroundColor = widget.isMe
        ? Colors.white.withOpacity(0.2)
        : AppTheme.primaryColor.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/pause button
          _buildPlayButton(primaryColor),

          const SizedBox(width: 8),

          // Waveform or progress bar
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: backgroundColor,
              ),
              child: _isPlaying
                  ? _buildPlaybackProgress(primaryColor)
                  : _buildWaveform(primaryColor),
            ),
          ),

          const SizedBox(width: 8),

          // Duration text
          _buildDurationText(primaryColor),
        ],
      ),
    );
  }

  /// Build play/pause button
  Widget _buildPlayButton(Color color) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _togglePlayback,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey<bool>(_isPlaying),
                color: color,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build waveform visualization
  Widget _buildWaveform(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_waveformHeights.length, (index) {
          // Make bars higher in the middle for a nice curve
          final height = _waveformHeights[index] * 32; // max height

          return Container(
            width: 2,
            height: height,
            decoration: BoxDecoration(
              color: color.withOpacity(0.6),
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }

  /// Build playback progress visualization
  Widget _buildPlaybackProgress(Color color) {
    // Calculate progress percentage
    final progress = (_duration.inMilliseconds > 0)
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Progress bar background
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
        ),

        // Progress track
        Container(
          width: double.infinity,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Progress fill
        Container(
          width: progress *
              (MediaQuery.of(context).size.width -
                  120), // Adjust width based on screen size
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Progress indicator (small circle)
        Positioned(
          left: 12 + progress * (MediaQuery.of(context).size.width - 120),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),

        // Animated bars (changes with animation controller)
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AnimatedBuilder(
              animation: _waveformAnimationController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_waveformHeights.length, (index) {
                    // Calculate relative position in the waveform
                    final relativePosition = index / _waveformHeights.length;

                    // Get base height for this bar
                    final baseHeight = _waveformHeights[index];

                    // Add animation factor - a sin wave based on position and time
                    final animatedValue = _waveformAnimationController.value;
                    final animationOffset =
                        sin((animatedValue * 2 * pi) + (index / 5)) * 0.2;

                    // Calculate opacity based on progress
                    double opacity = 0.3;
                    if (relativePosition <= progress) {
                      opacity = 0.7; // Higher opacity for completed portion
                    }

                    // Calculate final height with animation
                    final height = (baseHeight + animationOffset) *
                        24; // Smaller height for less intrusive look

                    return Container(
                      width: 3,
                      height: height,
                      decoration: BoxDecoration(
                        color: color.withOpacity(opacity),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),

        // Position and duration text
        Positioned(
          right: 12,
          child: Text(
            MessageFormatter.formatDuration(_position) +
                ' / ' +
                MessageFormatter.formatDuration(_duration),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Build duration/position text
  Widget _buildDurationText(Color color) {
    final textColor = color.withOpacity(0.8);
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    return _isPlaying
        ? Text(
            MessageFormatter.formatDuration(_position),
            style: textStyle,
          )
        : Text(
            widget.message.imageUrl != null && _duration == Duration.zero
                ? '--:--'
                : MessageFormatter.formatDuration(_duration),
            style: textStyle,
          );
  }

  /// Toggle audio playback
  void _togglePlayback() {
    if (widget.message.imageUrl == null) return;

    if (widget.onPlayAudio != null) {
      widget.onPlayAudio!(widget.message.id);
    } else {
      _audioUtils.playAudio(widget.message.id, widget.message.imageUrl!);
    }

    // Update UI immediately for smoother response
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _waveformAnimationController.repeat(reverse: true);
      } else {
        _waveformAnimationController.stop();
      }
    });
  }
}
