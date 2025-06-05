import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressStorage {
  static const _kKey = 'progress';
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

  List<int> getCompleted(String mapId) {
    return _getAll()[mapId] ?? <int>[];
  }

  Future<void> addCompletion(String mapId, int phaseIndex) async {
    final data = _getAll();
    final set = {...(data[mapId] ?? <int>[]), phaseIndex};
    data[mapId] = set.toList()..sort();
    await _prefs.setString(_kKey, jsonEncode(data));
  }

  Future<void> reset() async {
    await _prefs.remove(_kKey);
  }
}
