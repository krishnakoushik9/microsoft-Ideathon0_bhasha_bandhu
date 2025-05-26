import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

/// Service for interacting with the XTTS-v2 backend for high-quality TTS
class XTTSService {
  static const String baseUrl = 'http://localhost:8008'; // Default XTTS service URL
  
  /// Generate speech from text using XTTS-v2
  /// Returns a base64-encoded audio string that can be played
  static Future<XTTSResponse> generateSpeech({
    required String text,
    String personaRole = 'default',
    String language = 'en',
    double speed = 1.0,
    double temperature = 0.7,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'persona_role': personaRole,
          'language': language,
          'speed': speed,
          'temperature': temperature,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return XTTSResponse.fromJson(data);
      } else {
        throw Exception('Failed to generate speech: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to XTTS service: $e');
    }
  }
  
  /// Play audio from base64-encoded string
  static html.AudioElement playAudio(String base64Audio) {
    final audio = html.AudioElement();
    
    // Create data URL from base64 string
    final dataUrl = 'data:audio/wav;base64,$base64Audio';
    audio.src = dataUrl;
    audio.autoplay = true;
    
    // Add to document to ensure it plays (using correct DOM method)
    html.document.body?.append(audio);
    
    // Set up cleanup when audio finishes
    audio.onEnded.listen((_) {
      audio.remove();
    });
    
    return audio;
  }
  
  /// Check if the XTTS service is available
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Get available voice samples
  static Future<Map<String, bool>> getAvailableVoices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/voices'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, bool>.from(data['available_voices']);
      } else {
        throw Exception('Failed to get voices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to XTTS service: $e');
    }
  }
}

/// Response model for XTTS API
class XTTSResponse {
  final String audioBase64;
  final double durationSeconds;
  final int sampleRate;
  final String personaRole;
  
  XTTSResponse({
    required this.audioBase64,
    required this.durationSeconds,
    required this.sampleRate,
    required this.personaRole,
  });
  
  factory XTTSResponse.fromJson(Map<String, dynamic> json) {
    return XTTSResponse(
      audioBase64: json['audio_base64'],
      durationSeconds: json['duration_seconds'],
      sampleRate: json['sample_rate'],
      personaRole: json['persona_role'],
    );
  }
}
