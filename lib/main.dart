// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/game_page.dart';
import 'firebase_options.dart';
import 'presentation/pages/leaderboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as opções padrão
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: Prisma24App()));
}

class Prisma24App extends StatelessWidget {
  const Prisma24App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/game':  (_) => const GamePage(),
          '/rank':  (_) => const LeaderboardPage(),   // ← novo

      },
    );
  }
}
