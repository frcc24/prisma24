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

      // ─────────────────── Escolher ou criar o mapa ───────────────────
      final maps = FirebaseFirestore.instance.collection('maps');
      int index = 1;
      late DocumentReference<Map<String, dynamic>> mapDoc;
      late CollectionReference<Map<String, dynamic>> phases;

      while (true) {
        mapDoc = maps.doc('mapa$index');
        final docSnapshot = await mapDoc.get();

        // 1. verificar se o mapax ja existe e tem menos de 10 fases
        if (!docSnapshot.exists) {
          // 2. se nao existir cria o mapax
          try {
            await mapDoc.set({'createdAt': FieldValue.serverTimestamp()});
          } on FirebaseException catch (e) {
            setState(() => _status = 'Erro do Firestore: ${e.message}');
            return;
          } catch (e) {
            setState(() => _status = 'Erro ao criar mapa: $e');
            return;
          }
          phases = mapDoc.collection('phases');
          break;
        } else {
          phases = mapDoc.collection('phases');
          final phaseSnap = await phases.get();
          if (phaseSnap.size < 10) {
            break;
          }
        }
        index++;
      }

      // 3 e 4. adicionar a fase apos garantir a existencia do mapa
      try {
        // cria o documento somente com o atributo 'game'
        final docRef = await phases.add({'game': decoded['game']});
        // em seguida adiciona o atributo 'difficulty'
        await docRef.update({'difficulty': decoded['difficulty']});
        // adiciona createdAt com timestamp do servidor
        await docRef.update({'createdAt': FieldValue.serverTimestamp()});
        // e finalmente adiciona o tabuleiro
        final board = decoded['board'];
        if (board is Map<String, dynamic>) {
          await docRef.update({
            'board': {
              'size': board['size'],
              'initial': board['initial'],
              'solution': board['solution'],
              'colors': board['colors'],
            }
          });
        } else {
          setState(() => _status = 'Tabuleiro inválido: deve ser um objeto');
          return;
        }



        setState(() => _status = 'Fase adicionada com sucesso!');

      } on FirebaseException catch (e) {
        setState(() => _status = 'Erro do Firestore: ${e.message}');
      } catch (e) {
        setState(() => _status = 'Erro ao enviar mapa: $e');
      }
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


/*

{
  "game": "tango",
  "difficulty": "iniciante",
  "board": {
    "size": 4,
    "initial": "[[1,0,0,0],[0,2,0,0],[0,0,1,0],[0,0,0,2]]",
    "solution": "[[1,2,1,2],[2,2,1,1],[1,1,2,2],[2,1,2,1]]",
    "colors": ["moon", "triangle"]
  }
}


*/

List<List<int>> stringParaMatriz(String s) {
  final listaDinamica = jsonDecode(s) as List<dynamic>;
  return listaDinamica
      .map((linha) => List<int>.from(linha as List<dynamic>))
      .toList();
}

String matrizParaString(List<List<int>> matriz) {
  return jsonEncode(matriz);
}