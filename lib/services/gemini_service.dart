import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class GeminiService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  late final HttpsCallable _callGeminiChat;

  GeminiService() {
    _callGeminiChat = _functions.httpsCallable('callGeminiChat');
  }

  Future<String> sendMessage(String text) async {
    try {
      final HttpsCallableResult response = await _callGeminiChat.call({
        'text': text,
      });

      final String jsonString = jsonEncode(response.data);

      final Map<String, dynamic> data = jsonDecode(jsonString);

      final modelResponse = data['text'] as String?;

      if (modelResponse == null) {
        return 'Não foi possível gerar uma resposta.';
      }
      return modelResponse;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Erro na Cloud Function: ${e.code} - ${e.message}');
      return 'Deu erro no servidor! (Code: ${e.code})';
    } catch (e) {
      debugPrint('Erro inesperado: $e');
      return 'Deu erro!.';
    }
  }
}
