// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'presentation/pages/general_pages/home_page.dart';
import 'presentation/pages/prism_game/game_page.dart';
import 'firebase_options.dart';
import 'presentation/pages/general_pages/leaderboard_page.dart';
import 'presentation/pages/general_pages/settings_page.dart';
import 'presentation/pages/general_pages/full_mode_page.dart';
import 'presentation/pages/general_pages/full_mode_map_page.dart';
import 'presentation/pages/general_pages/add_phase_page.dart';
import 'presentation/pages/tango_game/tango_board_controller.dart' show TangoBoardController;
import 'presentation/pages/tango_game/tango_board_page.dart';
import 'presentation/pages/nonogram_game/nonogram_board_controller.dart'
    show NonogramBoardController;
import 'presentation/pages/nonogram_game/nonogram_board_page.dart';
import 'core/life_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as opções padrão
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await LifeManager().init();

  runApp(const ProviderScope(child: Prisma24App()));
}

class Prisma24App extends StatelessWidget {
  const Prisma24App({super.key});

  @override
  Widget build(BuildContext context) {

    Get.put(TangoBoardController());
    Get.put(NonogramBoardController());

    return GetMaterialApp(
      title: 'Prisma 24',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF00A8E8),
      ),
      initialRoute: '/',
      routes: {
        '/':      (_) => const HomePage(),
        '/prism':  (_) => const GamePage(),
        '/full':   (_) => const FullModePage(),
        '/full_map': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String;
          return FullModeMapPage(mapId: id);
        },
        '/rank':  (_) => const LeaderboardPage(),
        '/settings': (_) => const SettingsPage(),
        '/tango': (_) => TangoBoardPage(),
        '/nonogram': (_) => NonogramBoard(),
        '/add_phase': (_) => const AddPhasePage(),

      },
    );
  }
}
