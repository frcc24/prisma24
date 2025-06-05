// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';
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

  // Enable offline persistence for Firestore
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  await LifeManager().init();

  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString('locale') ?? 'pt_BR';
  final parts = code.split('_');
  final locale = Locale(parts[0], parts.length > 1 ? parts[1] : '');

  runApp(ProviderScope(child: Prisma24App(initialLocale: locale)));
}

class Prisma24App extends StatelessWidget {
  final Locale initialLocale;
  const Prisma24App({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {

    Get.put(TangoBoardController());
    Get.put(NonogramBoardController());

    return GetMaterialApp(
      title: 'Prisma 24',
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),
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
