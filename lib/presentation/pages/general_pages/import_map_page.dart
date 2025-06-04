import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImportMapPage extends StatefulWidget {
  const ImportMapPage({super.key});

  @override
  State<ImportMapPage> createState() => _ImportMapPageState();
}

class _ImportMapPageState extends State<ImportMapPage> {
  String? _status;
  final _controller = TextEditingController();

  Future<void> _uploadFromText() async {
    try {
      final text = _controller.text.trim();
      if (text.isEmpty) return;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Cole o JSON aqui',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _uploadFromText,
                child: const Text('Enviar para Firestore'),
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
      ),
    );
  }
}