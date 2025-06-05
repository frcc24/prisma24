import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LifeManager extends ChangeNotifier {
  LifeManager._internal();
  static final LifeManager _instance = LifeManager._internal();
  factory LifeManager() => _instance;

  static const int maxLives = 5;
  static const Duration refillDuration = Duration(minutes: 10);

  static const _kLivesKey = 'lives';

  late SharedPreferences _prefs;
  int _lives = maxLives;
  Timer? _timer;
  Duration _timeLeft = refillDuration;

  int get lives => _lives;
  Duration get timeLeft => _timeLeft;
  bool get isFull => _lives >= maxLives;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _lives = _prefs.getInt(_kLivesKey) ?? maxLives;
    if (_lives < maxLives) {
      _startTimer();
    }
    notifyListeners();
  }

  Future<void> _saveLives() async {
    await _prefs.setInt(_kLivesKey, _lives);
  }

  void loseLife() {
    if (_lives == 0) return;
    _lives--;
    _saveLives();
    notifyListeners();
    if (_lives < maxLives && _timer == null) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timeLeft = refillDuration;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _timeLeft -= const Duration(seconds: 1);
      if (_timeLeft.isNegative) _timeLeft = Duration.zero;
      notifyListeners();
      if (_timeLeft.inSeconds <= 0) {
        t.cancel();
        _timer = null;
        _addLife();
      }
    });
  }

  void _addLife() {
    if (_lives < maxLives) {
      _lives++;
      _saveLives();
      notifyListeners();
      if (_lives < maxLives) {
        _startTimer();
      }
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }
}
