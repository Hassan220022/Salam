// lib/services/audio_player_service.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerService with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isDisposed = false;

  late StreamSubscription _completeSubscription;
  late StreamSubscription _stateSubscription;

  AudioPlayerService() {
    _completeSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (!_isDisposed) {
        _isPlaying = false;
        notifyListeners();
      }
    });

    _stateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (!_isDisposed) {
        _isPlaying = state == PlayerState.playing;
        notifyListeners();
      }
    });
  }

  Future<void> play(String url) async {
    if (_isDisposed) return;

    try {
      await _audioPlayer.play(UrlSource(url));
      if (!_isDisposed) {
        _isPlaying = true;
        notifyListeners();
      }
    } catch (e) {
      // Handle play failure
      if (!_isDisposed) {
        _isPlaying = false;
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    if (_isDisposed) return;

    await _audioPlayer.stop();
    if (!_isDisposed) {
      _isPlaying = false;
      notifyListeners();
    }
  }

  bool get isPlaying => _isPlaying;

  @override
  void dispose() {
    _isDisposed = true;
    _completeSubscription.cancel();
    _stateSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
