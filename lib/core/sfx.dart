import 'package:audioplayers/audioplayers.dart';

class Sfx {
  Sfx._internal();

  static final Sfx _instance = Sfx._internal();
  factory Sfx() => _instance;

  final _cache = AudioPlayer(playerId: 'sfx')..setReleaseMode(ReleaseMode.stop);

  Future<void> tap() => _cache.play(AssetSource('audio/tap.wav'));
}
