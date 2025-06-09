import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart';

class BhashiniService implements AIService {
  final String _apiKey = const String.fromEnvironment('BHASHINI_API_KEY');
  final String _apiUrl = 'https://api.bhashini.ai/v1/translate';

  @override
  Future<String> chat(String message, String language) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': message,
          'source': language == 'te' ? 'te_IN' : 'en_IN',
          'target': language == 'te' ? 'en_IN' : 'te_IN',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translatedText'] ?? 'Translation not available';
      } else {
        throw Exception('Failed to translate: ${response.statusCode}');
      }
    } catch (e) {
      return 'Error in translation: $e';
    }
  }
}
