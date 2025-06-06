import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressStorage {
  static const _kKey = 'progress';
  static const _kScoreKey = 'scores';
  static const _kUnlockedKey = 'unlocked_maps';
  final SharedPreferences _prefs;
  ProgressStorage._(this._prefs);

  static Future<ProgressStorage> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return ProgressStorage._(prefs);
  }

  Map<String, List<int>> _getAll() {
    final str = _prefs.getString(_kKey);
    if (str == null) return {};
    final decoded = jsonDecode(str) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, List<int>.from(v as List)));
  }

  List<String> _getUnlocked() {
    final str = _prefs.getString(_kUnlockedKey);
    if (str == null) return <String>[];
    return List<String>.from(jsonDecode(str) as List);
  }

  List<int> getCompleted(String mapId) {
    return _getAll()[mapId] ?? <int>[];
  }

  bool isMapUnlocked(String mapId) {
    return _getUnlocked().contains(mapId);
  }

  Future<void> unlockMap(String mapId) async {
    final unlocked = _getUnlocked();
    if (!unlocked.contains(mapId)) {
      unlocked.add(mapId);
      await _prefs.setString(_kUnlockedKey, jsonEncode(unlocked));
    }
  }

  Future<void> addCompletion(String mapId, int phaseIndex) async {
    final data = _getAll();
    final set = {...(data[mapId] ?? <int>[]), phaseIndex};
    data[mapId] = set.toList()..sort();
    await _prefs.setString(_kKey, jsonEncode(data));
  }

  Future<void> reset() async {
    await _prefs.remove(_kKey);
    await _prefs.remove(_kScoreKey);
    await _prefs.remove(_kUnlockedKey);
  }

  Map<String, Map<String, int>> _getScores() {
    final str = _prefs.getString(_kScoreKey);
    if (str == null) return {};
    final decoded = jsonDecode(str) as Map<String, dynamic>;
    return decoded.map((k, v) {
      final inner = v as Map<String, dynamic>;
      return MapEntry(
        k,
        inner.map((p, s) => MapEntry(p, s as int)),
      );
    });
  }

  int getHighScore(String mapId, int phaseIndex) {
    final mapScores = _getScores()[mapId];
    if (mapScores == null) return 0;
    return mapScores['$phaseIndex'] ?? 0;
  }

  int getMapTotal(String mapId) {
    final mapScores = _getScores()[mapId];
    if (mapScores == null) return 0;
    return mapScores.values.fold(0, (p, v) => p + v);
  }

  Future<void> setHighScore(String mapId, int phaseIndex, int score) async {
    final data = _getScores();
    final mapScores = data.putIfAbsent(mapId, () => {});
    final key = '$phaseIndex';
    final current = mapScores[key] ?? 0;
    if (score > current) {
      mapScores[key] = score;
      await _prefs.setString(_kScoreKey, jsonEncode(data));
    }
  }
}
