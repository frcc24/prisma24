import 'package:shared_preferences/shared_preferences.dart';

Future<String> getPlayerName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('player_name') ?? 'Jogador';
}
