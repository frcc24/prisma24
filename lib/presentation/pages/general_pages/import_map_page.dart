import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class ImportMapPage extends StatefulWidget {
  const ImportMapPage({super.key});

  @override
  State<ImportMapPage> createState() => _ImportMapPageState();
}

class _ImportMapPageState extends State<ImportMapPage> {
  String? _status;

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final text = await File(path).readAsString();
      final data = json.decode(text);
      await FirebaseFirestore.instance.collection('full_mode_maps').add(data);
      setState(() => _status = 'Mapa enviado com sucesso!');
    } catch (e) {
      setState(() => _status = 'Erro ao enviar mapa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar mapa')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickAndUpload,
              child: const Text('Selecionar JSON'),
            ),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _status!,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
