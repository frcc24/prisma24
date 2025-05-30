// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/game_page.dart';

void main() {
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
      },
    );
  }
}
