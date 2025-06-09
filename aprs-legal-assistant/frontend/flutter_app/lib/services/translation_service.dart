import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _baseUrl = 'https://dhruva-api.bhashini.gov.in/services/inference/pipeline';
  static const Map<String, String> _headers = {
    'Authorization': 'ULCndVHFuQrOY6zFecDIx7sA2YlfujzTjeO0xIViNV8Pia_6TyunIVzfITYQvhyx',
    'Content-Type': 'application/json',
  };

  static final Map<String, String> _cache = {};

  static Future<String> translateText({
    required String text,
    String fromLang = 'en',
    String toLang = 'te',
    String fromScript = 'Latn',
    String toScript = 'Telu',
  }) async {
    if (fromLang == toLang) return text;
    
    // Check cache first
    final cacheKey = '$text-$fromLang-$toLang';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          'pipelineTasks': [
            {
              'taskType': 'translation',
              'config': {
                'language': {
                  'sourceLanguage': fromLang,
                  'sourceScriptCode': fromScript,
                  'targetLanguage': toLang,
                  'targetScriptCode': toScript,
                },
                'modelId': '641d1ca98ecee6735a1b3707',
                'serviceId': 'ai4bharat/indictrans-v2-all-gpu--t4'
              }
            }
          ],
          'inputData': {
            'input': [
              {'source': text}
            ],
            'audio': []
          }
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final translatedText = result['pipelineResponse'][0]['output'][0]['target'] as String? ?? text;
        
        // Cache the result
        _cache[cacheKey] = translatedText;
        return translatedText;
      } else {
        print('Translation failed: ${response.statusCode} - ${response.body}');
        return text;
      }
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }

  // Clear translation cache
  static void clearCache() {
    _cache.clear();
  }
}
