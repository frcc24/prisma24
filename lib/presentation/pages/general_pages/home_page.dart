// lib/presentation/pages/home_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // gradiente sutil esquerda-direita
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF0E0E11),
              Color(0xFF141418),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child:
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // logotipo maior – 40 % da largura da tela
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Image.asset(
                    'assets/images/ui/logo.png',
                    width: size.width * 0.8,
                    fit: BoxFit.contain,
                  ),
                ),
                // botões ocupam 80 % da largura; máx 380 px
                _MenuButton(
                  color: Colors.green,
                  label: 'start_prism'.tr,
                  icon: Icons.play_arrow,
                  onTap: () => Navigator.pushNamed(context, '/prism'),
                ),
                // _MenuButton(
                //   color: Colors.lightGreen,
                //   label: 'Iniciar jogo Tango',
                //   icon: Icons.play_arrow,
                //   onTap: () => Navigator.pushNamed(context, '/tango'),
                // ),
                // _MenuButton(
                //   color: Colors.tealAccent,
                //   label: 'Iniciar jogo Nonogram',
                //   icon: Icons.play_arrow,
                //   onTap: () => Navigator.pushNamed(context, '/nonogram'),
                // ),
                _MenuButton(
                  color: Colors.purpleAccent,
                  label: 'start_full'.tr,
                  icon: Icons.map,
                  onTap: () => Navigator.pushNamed(context, '/full'),
                ),
                _MenuButton(
                  color: Colors.blue,
                  label: 'leaderboards'.tr,
                  icon: Icons.bar_chart,
                  onTap: () => Navigator.pushNamed(context, '/rank'),
                ),
                _MenuButton(
                  color: Colors.orange,
                  label: 'settings'.tr,
                  icon: Icons.settings,
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                _MenuButton(
                  color: Colors.cyan,
                  label: 'add_phase'.tr,
                  icon: Icons.upload_file,
                  onTap: () => Navigator.pushNamed(context, '/add_phase'),
                ),
                  _MenuButton(
                  color: Colors.red,
                  label: 'exit'.tr,
                  icon: Icons.logout,
                  onTap: () => Future.delayed(
                    Duration(milliseconds: 100),
                    () => Navigator.of(context).maybePop().then((_) {
                    Future.delayed(Duration(milliseconds: 200), () {
                      exit(0);
                    });
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*────────────────── Botão reutilizável ──────────────────*/
class _MenuButton extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuButton({
    required this.color,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = (size.width * 0.8).clamp(0, 380.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: width.toDouble(),
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }
}
