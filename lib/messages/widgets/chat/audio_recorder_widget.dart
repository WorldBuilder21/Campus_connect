import 'dart:async';
import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/messages/utils/audio_utils.dart';
import 'package:campus_conn/messages/utils/message_formatter.dart';

/// A beautiful audio recorder widget with waveform visualization
class AudioRecorderWidget extends StatefulWidget {
  /// Callback when recording is cancelled
  final VoidCallback onCancel;

  /// Callback when recording is completed with the file path
  final Function(String) onComplete;

  /// Constructor
  const AudioRecorderWidget({
    Key? key,
    required this.onCancel,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with TickerProviderStateMixin {
  late final AudioUtils _audioUtils;
  late final AnimationController _pulseAnimationController;
  late final AnimationController _amplitudeAnimationController;

  // Recording state
  bool _isRecording = false;
  String? _recordingPath;
  int _recordingDuration = 0; // in seconds
  Timer? _recordingTimer;

  // Visualization data
  final List<double> _amplitudes = List.filled(30, 0.0);
  final int _maxAmplitudeCount = 30;

  // Drag to cancel
  double _dragOffset = 0.0;
  final double _cancelDragThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _audioUtils = AudioUtils();

    // Initialize animation controllers
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _amplitudeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Start recording immediately
    _startRecording();
  }

  @override
  void dispose() {
    _stopTimer();
    _pulseAnimationController.dispose();
    _amplitudeAnimationController.dispose();
    super.dispose();
  }

  /// Start audio recording
  Future<void> _startRecording() async {
    if (_isRecording) return;

    // Start recording
    await _audioUtils.startRecording();

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });

    // Start duration timer
    _startTimer();

    // Start amplitude measurement
    _startAmplitudeMeasurement();
  }

  /// Stop audio recording
  Future<void> _stopRecording({bool cancelled = false}) async {
    if (!_isRecording) return;

    // Stop timer
    _stopTimer();

    // Stop recording
    final path = await _audioUtils.stopRecording();

    setState(() {
      _isRecording = false;
      _recordingPath = path;
    });

    // Handle completion or cancellation
    if (cancelled || path == null) {
      widget.onCancel();
    } else {
      widget.onComplete(path);
    }
  }

  /// Start recording timer
  void _startTimer() {
    _stopTimer(); // Ensure no existing timer

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });

      // Auto-stop after 2 minutes (optional)
      if (_recordingDuration >= 120) {
        _stopRecording();
      }
    });
  }

  /// Stop recording timer
  void _stopTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  /// Start measuring audio amplitude for visualization
  void _startAmplitudeMeasurement() {
    // Poll amplitude every 100ms for visualization
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      _updateAmplitude();
    });
  }

  /// Update amplitude values for visualization
  Future<void> _updateAmplitude() async {
    if (!_isRecording) return;

    // Get current amplitude (0.0 to 1.0)
    final amplitude = await _audioUtils.getRecordingAmplitude();

    // Shift values to the left and add new value
    if (mounted) {
      setState(() {
        for (int i = 0; i < _amplitudes.length - 1; i++) {
          _amplitudes[i] = _amplitudes[i + 1];
        }
        _amplitudes[_amplitudes.length - 1] = amplitude;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          // Track horizontal drag for cancel gesture
          _dragOffset += details.delta.dx;

          // Limit drag to left only and cap at threshold
          if (_dragOffset > 0) _dragOffset = 0;
          if (_dragOffset < -_cancelDragThreshold)
            _dragOffset = -_cancelDragThreshold;
        });
      },
      onHorizontalDragEnd: (details) {
        // Check if drag passes cancel threshold
        if (_dragOffset <= -_cancelDragThreshold) {
          _stopRecording(cancelled: true);
        } else {
          // Spring back animation
          setState(() {
            _dragOffset = 0;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Transform.translate(
          // Apply drag offset for slide-to-cancel effect
          offset: Offset(_dragOffset, 0),
          child: Row(
            children: [
              // Recording indicator and stop button
              _buildRecordingIndicator(),

              const SizedBox(width: 12),

              // Waveform visualization
              Expanded(
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child: Row(
                    children: [
                      // Waveform
                      Expanded(child: _buildWaveform()),

                      // Drag to cancel hint
                      _buildCancelHint(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the recording indicator/stop button
  Widget _buildRecordingIndicator() {
    return GestureDetector(
      onTap: () => _stopRecording(),
      child: AnimatedBuilder(
        animation: _pulseAnimationController,
        builder: (context, child) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
              // Pulsing effect
              boxShadow: [
                BoxShadow(
                  color: Colors.red
                      .withOpacity(0.3 * _pulseAnimationController.value),
                  blurRadius: 12.0,
                  spreadRadius: 4.0 + 4.0 * _pulseAnimationController.value,
                ),
              ],
            ),
            child: const Icon(
              Icons.stop_rounded,
              color: Colors.white,
              size: 24,
            ),
          );
        },
      ),
    );
  }

  /// Build the waveform visualization
  Widget _buildWaveform() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final barWidth = width / _maxAmplitudeCount - 2;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Duration text
              Container(
                width: 50,
                child: Text(
                  MessageFormatter.formatDuration(
                      Duration(seconds: _recordingDuration)),
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              // Waveform bars
              ...List.generate(_amplitudes.length, (index) {
                // Animate the bar heights based on amplitude
                final amplitude = _amplitudes[index];
                final height =
                    4.0 + (amplitude * 30.0); // Min height of 4, max of 34

                return Container(
                  width: barWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(barWidth / 2),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  /// Build the cancel hint
  Widget _buildCancelHint() {
    // Calculate opacity based on drag offset
    final cancelOpacity = (-_dragOffset / _cancelDragThreshold).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          // Sliding arrow indicator
          Icon(
            Icons.arrow_back,
            color: Colors.red.withOpacity(0.7 * (1 - cancelOpacity)),
            size: 16,
          ),
          const SizedBox(width: 4),

          // Cancel text
          Text(
            "Slide to cancel",
            style: TextStyle(
              color: Colors.red.withOpacity(0.7 * (1 - cancelOpacity)),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Cancel confirmation
          if (cancelOpacity > 0.5)
            Opacity(
              opacity: (cancelOpacity - 0.5) * 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Release to cancel",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
