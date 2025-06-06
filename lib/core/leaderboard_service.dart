import '../data/score_repository.dart';
import 'progress_storage.dart';
import 'player_prefs.dart';

class LeaderboardService {
  LeaderboardService._([ScoreRepository? repository])
      : _scores = repository ?? ScoreRepository();
  static final LeaderboardService _instance = LeaderboardService._();
  factory LeaderboardService() => _instance;

  final ScoreRepository _scores;

  Future<int> getMinScore(String mapId, int phaseIndex) {
    return _scores.lowestTopScore(mapId, phaseIndex);
  }

  Future<void> maybeSavePhaseScore(
      String mapId, int phaseIndex, int score, int threshold) async {
    if (score > threshold) {
      await savePhaseScore(mapId, phaseIndex, score);
    }
  }

  Future<void> savePhaseScore(String mapId, int phaseIndex, int score) async {
    final name = await getPlayerName();

    await _scores.savePhaseScore(mapId, phaseIndex, name, score);

    final storage = await ProgressStorage.getInstance();
    await storage.setHighScore(mapId, phaseIndex, score);
  }
}
