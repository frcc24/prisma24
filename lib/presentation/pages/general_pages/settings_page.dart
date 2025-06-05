// lib/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
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
  static const _kLocaleKey = 'locale';

  bool _soundOn = true;
  String _playerName = 'Jogador';
  String _version = '';
  Locale _locale = const Locale('pt', 'BR');

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
      final code = prefs.getString(_kLocaleKey) ?? 'pt_BR';
      final parts = code.split('_');
      _locale = Locale(parts[0], parts.length > 1 ? parts[1] : '');
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
        title: Text('change_name'.tr),
        content: TextField(
          controller: controller,
          maxLength: 24,
          decoration: InputDecoration(hintText: 'player_name'.tr),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text('save'.tr)),
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

  Future<void> _changeLanguage() async {
    final result = await showDialog<Locale>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('select_language'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<Locale>(
              title: Text('english'.tr),
              value: const Locale('en', 'US'),
              groupValue: _locale,
              onChanged: (v) => Navigator.pop(context, v),
            ),
            RadioListTile<Locale>(
              title: Text('portuguese'.tr),
              value: const Locale('pt', 'BR'),
              groupValue: _locale,
              onChanged: (v) => Navigator.pop(context, v),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocaleKey, '${result.languageCode}_${result.countryCode}');
      setState(() => _locale = result);
      Get.updateLocale(result);
    }
  }

  Future<void> _resetProgress() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('reset_progress_q'.tr),
        content: Text('reset_progress_msg'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('confirm'.tr)),
        ],
      ),
    );
    if (confirm == true) {
      final storage = await ProgressStorage.getInstance();
      await storage.reset();
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text('progress_cleared'.tr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr)),
      body: ListView(
        children: [
          SwitchListTile(
            value: _soundOn,
            title: Text('sound'.tr),
            subtitle: Text('enable_audio'.tr),
            onChanged: _toggleSound,
          ),
          ListTile(
            title: Text('player_name'.tr),
            subtitle: Text(_playerName),
            trailing: const Icon(Icons.edit),
            onTap: _editName,
          ),
          ListTile(
            title: Text('app_version'.tr),
            subtitle: Text(_version.isEmpty ? '...' : _version),
          ),
          const Divider(),
          ListTile(
            title: Text('reset_phases'.tr),
            subtitle: const Text('Apagar progresso salvo'),
            trailing: const Icon(Icons.restore),
            onTap: _resetProgress,
          ),
          const Divider(),
          ListTile(
            title: Text('open_source_licenses'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => showLicensePage(context: context, applicationName: 'Prisma 24'),
          ),
          ListTile(
            title: Text('select_language'.tr),
            subtitle: Text(_locale.languageCode == 'pt' ? 'portuguese'.tr : 'english'.tr),
            trailing: const Icon(Icons.language),
            onTap: _changeLanguage,
          ),
        ],
      ),
    );
  }
}
