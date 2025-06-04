import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPhasePage extends StatefulWidget {
  const AddPhasePage({super.key});

  @override
  State<AddPhasePage> createState() => _AddPhasePageState();
}


class _AddPhasePageState extends State<AddPhasePage> {
  String? _status;
  final _controller = TextEditingController();

  Future<void> _uploadFromText() async {
    try {
      final text = _controller.text.trim();
      if (text.isEmpty) return;
      final decoded = json.decode(text);
      if (decoded is! Map<String, dynamic>) {
        setState(() => _status = 'JSON inválido: deve ser um objeto');
        return;
      }
      final data = Map<String, dynamic>.from(decoded);

      // Determine the target collection based on existing ones
      const base = 'maps';
      int index = 1;
      CollectionReference<Map<String, dynamic>> collection;
      while (true) {
        final name = index == 1 ? base : '$base$index';
        collection = FirebaseFirestore.instance.collection(name);
        final count = await collection.get().then((s) => s.size);
        if (count < 10) {
          break;
        }
        index++;
      }

      await collection.add(data);
      setState(() => _status = 'Fase adicionada com sucesso!');
    } catch (e) {
      setState(() => _status = 'Erro ao enviar mapa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar fase')),
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


/*{
  "game": "tango",
  "difficulty": "iniciante",
  "board": {
    "size": 4,
    "initial": [
      [1, 0, 0, 0],
      [0, 2, 0, 0],
      [0, 0, 1, 0],
      [0, 0, 0, 2]
    ],
    "solution": [
      [1, 2, 1, 2],
      [2, 2, 1, 1],
      [1, 1, 2, 2],
      [2, 1, 2, 1]
    ],
    "colors": ["moon", "triangle"]
  }
}
*/