import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:audio_waveforms/audio_waveforms.dart';

/// Utility class for audio recording and playback
class AudioUtils {
  /// Singleton instance
  static final AudioUtils _instance = AudioUtils._internal();

  /// Factory constructor
  factory AudioUtils() => _instance;

  /// Internal constructor for singleton
  AudioUtils._internal();

  /// Audio recorder instance
  AudioRecorder? _audioRecorder;

  /// Audio player instance
  just_audio.AudioPlayer? _audioPlayer;

  /// Currently playing message ID
  String? currentlyPlayingId;

  /// Stream subscriptions map for audio playback state tracking
  final Map<String, StreamSubscription<just_audio.PlayerState>>
      _audioListeners = {};

  /// Recording state
  bool _isRecording = false;

  /// Recording path
  String? _recordingPath;

  /// Initialize audio components
  Future<void> initialize() async {
    _audioRecorder ??= AudioRecorder();
    _audioPlayer ??= just_audio.AudioPlayer();
  }

  /// Dispose audio components
  void dispose() {
    // Cancel all stream subscriptions
    for (final subscription in _audioListeners.values) {
      subscription.cancel();
    }
    _audioListeners.clear();

    // Dispose audio components
    _audioPlayer?.dispose();
    _audioRecorder?.dispose();

    _audioRecorder = null;
    _audioPlayer = null;
    currentlyPlayingId = null;
  }

  /// Check if recording is in progress
  bool get isRecording => _isRecording;

  /// Start audio recording
  Future<void> startRecording() async {
    if (_isRecording) return;

    await initialize();

    // Request recording permission
    if (await _audioRecorder!.hasPermission()) {
      // Create a temporary file path
      final directory = await getTemporaryDirectory();
      _recordingPath =
          '${directory.path}/audio_message_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: _recordingPath!,
      );

      _isRecording = true;
    }
  }

  /// Stop audio recording
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _audioRecorder!.stop();
    _isRecording = false;

    return path;
  }

  /// Play audio from URL or file path
  Future<void> playAudio(String messageId, String audioUrl) async {
    await initialize();

    // If already playing this audio, pause it
    if (currentlyPlayingId == messageId) {
      await _audioPlayer!.pause();
      currentlyPlayingId = null;
      return;
    }

    // If playing a different audio, stop it first
    if (currentlyPlayingId != null) {
      await _audioPlayer!.stop();

      // Remove old listener
      await _audioListeners[currentlyPlayingId]?.cancel();
      _audioListeners.remove(currentlyPlayingId);

      currentlyPlayingId = null;
    }

    // Set new audio source
    try {
      currentlyPlayingId = messageId;

      await _audioPlayer!.setUrl(audioUrl);
      await _audioPlayer!.play();

      // Listen for completion
      final subscription = _audioPlayer!.playerStateStream.listen((state) {
        if (state.processingState == just_audio.ProcessingState.completed) {
          if (currentlyPlayingId == messageId) {
            currentlyPlayingId = null;

            // Clean up the listener
            _audioListeners[messageId]?.cancel();
            _audioListeners.remove(messageId);
          }
        }
      });

      _audioListeners[messageId] = subscription;
    } catch (e) {
      debugPrint('Error playing audio: $e');
      currentlyPlayingId = null;
    }
  }

  /// Get audio player position stream
  Stream<Duration>? get positionStream {
    return _audioPlayer?.positionStream;
  }

  /// Get current audio duration
  Duration? get duration {
    return _audioPlayer?.duration;
  }

  /// Pause audio playback
  Future<void> pauseAudio() async {
    await _audioPlayer?.pause();
  }

  /// Get raw audio amplitude during recording
  Future<double?> getAmplitude() async {
    if (!_isRecording) return 0.0;
    return await _audioRecorder?.getAmplitude().then((amp) => amp.current);
  }

  /// Get recorder's max amplitude (for UI visualization)
  Future<double> getRecordingAmplitude() async {
    if (!_isRecording) return 0.0;
    final amplitude = await _audioRecorder?.getAmplitude();
    // Convert to a percentage (0.0 to 1.0) for better UI control
    return ((amplitude?.current ?? 0) / -160.0).clamp(0.0, 1.0);
  }

  /// Initialize a recorder controller for visualization
  Future<RecorderController> createRecorderController() async {
    final controller = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100
      ..bitRate = 128000;

    return controller;
  }

  /// Initialize a player controller for visualization
  Future<PlayerController> createPlayerController(String path) async {
    final controller = PlayerController();
    await controller.preparePlayer(path: path);
    return controller;
  }
}
