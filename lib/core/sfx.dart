import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sfx {
  Sfx._internal();

  static final Sfx _instance = Sfx._internal();
  factory Sfx() => _instance;

  static const soundPrefKey = 'sound_on';

  final AudioPlayer _cache =
      AudioPlayer(playerId: 'sfx')..setReleaseMode(ReleaseMode.stop);

  bool _enabled = true;

  bool get enabled => _enabled;
  set enabled(bool v) => _enabled = v;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(soundPrefKey) ?? true;
  }

  Future<void> tap() async {
    if (!_enabled) return;
    await _cache.play(AssetSource('audio/tap.wav'));
  }

  Future<void> win() async {
    if (!_enabled) return;
    await _cache.play(AssetSource('audio/win.wav'));
  }

  Future<void> fail() async {
    if (!_enabled) return;
    await _cache.play(AssetSource('audio/fail.mp3'));
  }
}
