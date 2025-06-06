import 'dart:convert';

/// Converts a JSON string representation of a matrix into a list of lists.
List<List<int>> stringParaMatriz(String s) {
  final listaDinamica = jsonDecode(s) as List<dynamic>;
  return listaDinamica
      .map((linha) => List<int>.from(linha as List<dynamic>))
      .toList();
}

/// Encodes a matrix (list of lists) into a JSON string.
String matrizParaString(List<List<int>> matriz) {
  return jsonEncode(matriz);
}
