// lib/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/progress_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /* chaves no SharedPreferences */
  static const _kSoundKey = 'sound_on';
  static const _kNameKey  = 'player_name';

  bool _soundOn = true;
  String _playerName = 'Jogador';
  String _version = '';

  /* carregamento inicial */
  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final pkg   = await PackageInfo.fromPlatform();
    setState(() {
      _soundOn     = prefs.getBool(_kSoundKey) ?? true;
      _playerName  = prefs.getString(_kNameKey) ?? 'Jogador';
      _version     = '${pkg.version}+${pkg.buildNumber}';
    });
  }

  Future<void> _toggleSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundKey, value);
    setState(() => _soundOn = value);
  }

  Future<void> _registerUser(String name) async {
    final users = FirebaseFirestore.instance.collection('users');
    final query = await users.where('name', isEqualTo: name).limit(1).get();
    if (query.docs.isEmpty) {
      await users.add({'name': name, 'ts': FieldValue.serverTimestamp()});
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _playerName);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alterar nome'),
        content: TextField(
          controller: controller,
          maxLength: 24,
          decoration: const InputDecoration(hintText: 'Seu nome no ranking'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kNameKey, result);
      setState(() => _playerName = result);
      await _registerUser(result);
    }
  }

  Future<void> _resetProgress() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resetar progresso?'),
        content: const Text(
            'Fases concluídas serão removidas e você terá que jogar tudo novamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm == true) {
      final storage = await ProgressStorage.getInstance();
      await storage.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progresso apagado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          SwitchListTile(
            value: _soundOn,
            title: const Text('Som'),
            subtitle: const Text('Ativar efeitos de áudio'),
            onChanged: _toggleSound,
          ),
          ListTile(
            title: const Text('Nome no placar'),
            subtitle: Text(_playerName),
            trailing: const Icon(Icons.edit),
            onTap: _editName,
          ),
          ListTile(
            title: const Text('Versão do app'),
            subtitle: Text(_version.isEmpty ? '...' : _version),
          ),
          const Divider(),
          ListTile(
            title: const Text('Resetar fases'),
            subtitle: const Text('Apagar progresso salvo'),
            trailing: const Icon(Icons.restore),
            onTap: _resetProgress,
          ),
          const Divider(),
          ListTile(
            title: const Text('Licenças de código aberto'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => showLicensePage(context: context, applicationName: 'Prisma 24'),
          ),
        ],
      ),
    );
  }
}
