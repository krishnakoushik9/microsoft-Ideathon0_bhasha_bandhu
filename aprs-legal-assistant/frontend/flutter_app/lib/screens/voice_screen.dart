import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:async';
import 'dart:js' as js;

/// VoiceScreen: Record audio and display transcription
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({Key? key}) : super(key: key);

  @override
  _VoiceScreenState createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  // State variables
  html.MediaRecorder? _mediaRecorder;
  List<dynamic> _audioChunks = [];
  html.MediaStream? _stream;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  bool _simulateRecording = false;
  bool _isLoading = false;
  bool _isRecording = false;
  String _transcription = '';
  String _assistantResponse = '';
  String _originalTeluguText = '';
  String _translatedText = '';
  String _audioUrl = '';
  String _recordedAudioUrl = '';
  String _debugMsg = '';
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  double _sheetSize = 0.0;
  bool _useTeluguASR = true; // Default to Telugu
  bool _chatOnlyMode = false;
  String _directTranslatedText = '';
  // Chat input controller
  final TextEditingController _chatController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Voice Assistant Help'),
                  content: const Text(
                    'Tap the microphone to record your voice query.\n'
                    'The assistant will transcribe, translate, and answer your question using Azure and Gemini AI.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Center voice controls horizontally and vertically
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_isRecording) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (_debugMsg.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('DEBUG: $_debugMsg', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ToggleButtons(
                  isSelected: [_useTeluguASR, !_useTeluguASR],
                  onPressed: (index) {
                    setState(() {
                      _useTeluguASR = index == 0;
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text('Telugu', style: TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text('English', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                  selectedBorderColor: Theme.of(context).colorScheme.primary,
                  fillColor: Theme.of(context).colorScheme.primary,
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 32),
                _buildRecordingButton(),
                const SizedBox(height: 40),
                if (_isLoading)
                  Column(
                    children: const [
                      LinearProgressIndicator(minHeight: 4),
                      SizedBox(height: 8),
                      Text('Uploading & processing audio...', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                if (!_isLoading && _transcription.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text('Transcription:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_transcription, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  // Playback recorded audio
                  if (_recordedAudioUrl.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _playAudio(_recordedAudioUrl),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play Recording'),
                    ),
                  const SizedBox(height: 16),
                  Text('Translation:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_translatedText, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Text('Assistant Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_assistantResponse, style: TextStyle(fontSize: 16, color: Colors.blue)),
                  // Playback AI TTS audio
                  if (_audioUrl.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _playAudio(_audioUrl),
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Play AI Audio'),
                    ),
                ]
              ],
            ),
          ),
          _buildResponseSheet(context),
          // Chat input box
          Positioned(
            bottom: 240,
            left: 40,
            right: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_chatOnlyMode) ...[
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'EN: $_directTranslatedText',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type message…',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.grey[800],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.teal),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final text = _chatController.text.trim();
                              if (text.isEmpty) return;
                              setState(() {
                                _debugMsg += '💬 Chat input: $text\n';
                                _isLoading = true;
                                _directTranslatedText = '';
                              });
                              _chatController.clear();
                              try {
                                if (_chatOnlyMode) {
                                  // Direct Bhashini pipeline call
                                  final body = {
                                    'pipelineTasks': [
                                      {
                                        'taskType': 'translation',
                                        'config': {
                                          'language': {
                                            'sourceLanguage': 'te',
                                            'sourceScriptCode': 'Telu',
                                            'targetLanguage': 'en',
                                            'targetScriptCode': 'Latn'
                                          },
                                          'modelId': '641d1ca98ecee6735a1b3707',
                                          'serviceId': 'ai4bharat/indictrans-v2-all-gpu--t4'
                                        }
                                      }
                                    ],
                                    'inputData': {
                                      'input': [{'source': text}],
                                      'audio': []
                                    }
                                  };
                                  final resp = await http.post(
                                    Uri.parse('https://dhruva-api.bhashini.gov.in/services/inference/pipeline'),
                                    headers: {
                                      'Authorization': 'ULCndVHFuQrOY6zFecDIx7sA2YlfujzTjeO0xIViNV8Pia_6TyunIVzfITYQvhyx',
                                      'Content-Type': 'application/json'
                                    },
                                    body: jsonEncode(body),
                                  );
                                  if (resp.statusCode == 200) {
                                    final j = jsonDecode(resp.body);
                                    final pipeline = j['pipelineResponse'] as List;
                                    final target = pipeline.first['output'][0]['target'];
                                    setState(() {
                                      _directTranslatedText = target;
                                      _isLoading = false;
                                    });
                                  } else {
                                    setState(() {
                                      _debugMsg += '❌ Direct chat failed: ${resp.statusCode}\n';
                                      _isLoading = false;
                                    });
                                  }
                                } else {
                                  // Existing voice/chat integration via main.py
                                  // original onPressed logic
                                  await _handleVoiceQueryChat(text);
                                }
                              } catch (e) {
                                setState(() {
                                  _debugMsg += '❌ Direct chat error: $e\n';
                                  _isLoading = false;
                                });
                              }
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Voice/Chat mode toggle
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: () => setState(() => _chatOnlyMode = !_chatOnlyMode),
              style: ElevatedButton.styleFrom(
                backgroundColor: _chatOnlyMode ? Colors.orange : Colors.blue,
              ),
              child: Text(_chatOnlyMode ? 'Voice Mode' : 'Chat Only'),
            ),
          ),
          // Debug panel
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: 300,
              height: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: SingleChildScrollView(
                child: Text(
                  _debugMsg,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.greenAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeRecording() async {
    if (_simulateRecording) {
      setState(() {});
      return;
    }
    try {
      _stream = await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      _mediaRecorder = html.MediaRecorder(_stream!, {'mimeType': 'audio/webm'});
      _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
        final dataEvent = event as html.BlobEvent;
        if (dataEvent.data != null && dataEvent.data!.size > 0) {
          _audioChunks.add(dataEvent.data!);
        }
      });
      setState(() {});
    } catch (e) {
      print('Error initializing recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error accessing microphone: $e')));
    }
  }

  Future<void> _startRecording() async {
    await _initializeRecording();
    _audioChunks = [];
    _recordingDuration = 0;
    if (_simulateRecording) {
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });
      setState(() {
        _isRecording = true;
        _transcription = '';
        _assistantResponse = '';
        _originalTeluguText = '';
        _translatedText = '';
        _audioUrl = '';
      });
    } else if (_mediaRecorder != null) {
      _mediaRecorder!.start();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });
      setState(() {
        _isRecording = true;
        _transcription = '';
        _assistantResponse = '';
        _originalTeluguText = '';
        _translatedText = '';
        _audioUrl = '';
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recording ${_useTeluguASR ? 'Telugu' : 'English'} audio...'), duration: const Duration(seconds: 2)));
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    if (_simulateRecording) {
      setState(() => _isRecording = false);
      _simulateProcessRecording();
    } else if (_mediaRecorder != null && _mediaRecorder!.state == 'recording') {
      _mediaRecorder!.addEventListener('stop', (html.Event _) {
        _processRecording();
      });
      _mediaRecorder!.stop();
      setState(() => _isRecording = false);
    }
  }

  Future<void> _processRecording() async {
    setState(() => _debugMsg += 'Process start: simulate=$_simulateRecording, chunks=${_audioChunks.length}\n');
    setState(() => _isLoading = true);
    final audioData = await combineAudioChunks();
    // Preview recorded audio
    final recBlob = html.Blob([audioData], 'audio/webm');
    final recUrl = html.Url.createObjectUrlFromBlob(recBlob);
    setState(() => _recordedAudioUrl = recUrl);
    final base64Audio = base64Encode(audioData);
    setState(() => _debugMsg += 'Posting: lang=${_useTeluguASR ? 'te' : 'en'}, len=${base64Audio.length}\n');
    setState(() => _debugMsg += '🌐 Connecting to backend at /api/voice-query...\n');
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/voice-query'),
        body: {
          'audio_base64': base64Audio,
          'language': _useTeluguASR ? 'te' : 'en',
        },
      );
      setState(() => _debugMsg += '✅ Server responded: ${response.statusCode}\n');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() => _debugMsg += '✅ Success\n');
        if (jsonResponse.containsKey('ulca_status')) {
          setState(() => _debugMsg += '🛰️ ULCA Status: ${jsonResponse['ulca_status']}\n');
        }
        setState(() {
          _isLoading = false;
          _originalTeluguText = jsonResponse['asr_text'] ?? '';
          _translatedText = jsonResponse['translated_text'] ?? '';
          _assistantResponse = _useTeluguASR ? jsonResponse['ai_response_te'] ?? '' : jsonResponse['ai_response_en'] ?? '';
          _transcription = _useTeluguASR ? jsonResponse['asr_text'] ?? '' : jsonResponse['translated_text'] ?? '';
        });
        // Handle audio from backend
        if (jsonResponse['audio'] != null && (jsonResponse['audio'] as String).isNotEmpty) {
          final audioBase64 = jsonResponse['audio'] as String;
          final audioBytes = base64Decode(audioBase64);
          final blob = html.Blob([audioBytes], 'audio/wav');
          final url = html.Url.createObjectUrlFromBlob(blob);
          setState(() {
            _audioUrl = url;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _debugMsg += '❌ Failed to process: ${response.statusCode}\n';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to process recording: ${response.statusCode}')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugMsg += '❌ Error: $e\n';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing recording: $e')),
      );
    }
  }

  Future<Uint8List> combineAudioChunks() async {
    List<Future<Uint8List>> futures = _audioChunks.map((blob) async {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);
      await reader.onLoad.first;
      return Uint8List.view(reader.result as ByteBuffer);
    }).toList();
    List<Uint8List> byteArrays = await Future.wait(futures);
    final combined = BytesBuilder();
    for (var bytes in byteArrays) {
      combined.add(bytes);
    }
    return combined.toBytes();
  }

  Widget _buildRecordingButton() {
    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
              if (!_isRecording && !_isLoading) {
                setState(() => _debugMsg += '🎙️ Record button clicked\n');
                _startRecording();
              } else if (_isRecording) {
                setState(() => _debugMsg += '🛑 Recording stopped\n');
                _stopRecording();
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : Colors.blueAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _isRecording ? Colors.redAccent : Colors.blue.withOpacity(0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildResponseSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: _sheetSize,
      minChildSize: 0.0,
      maxChildSize: 0.7,
      controller: _sheetController,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),
              if (!_isLoading && _transcription.isNotEmpty) ...[
                Text('Transcription:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_originalTeluguText, style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Translation:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_translatedText, style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Assistant Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_assistantResponse, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary)),
                if (_audioUrl.isNotEmpty)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _playAudio(_audioUrl),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play Audio'),
                      ),
                    ],
                  ),
              ]
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _playAudio(String url) {
    final audio = html.AudioElement(url);
    audio.play();
  }

  Future<void> _simulateProcessRecording() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      final sampleText = _useTeluguASR 
          ? 'నాకు నాయశాస్త్ర సలహా కావాలి' // Telugu for "I need legal advice"
          : 'I need legal advice';
      
      final response = {
        'asr_text': sampleText,
        'translated_text': 'I need legal advice',
        'ai_response_en': 'I understand you need legal advice. What specific legal matter can I help you with?',
        'ai_response_te': 'మీకు నాయ సలహా అవసరమని నేను అర్థం చేసుకున్నాను. నేను మీకు ఏ నిర్దిష్ట చట్టపరమైన విషయంలో సహాయపడగలను?',
        'audio': 'simulated_audio_base64_data'
      };
      
      setState(() {
        _isLoading = false;
        _originalTeluguText = response['asr_text'] ?? '';
        _translatedText = response['translated_text'] ?? '';
        _assistantResponse = _useTeluguASR ? response['ai_response_te'] ?? '' : response['ai_response_en'] ?? '';
        _transcription = _useTeluguASR ? response['asr_text'] ?? '' : response['translated_text'] ?? '';
        _sheetSize = 0.4; // Show the sheet with transcription
      });
      
      if (response['audio'] != null && response['audio'] != '') {
        final audioBase64 = response['audio'] as String;
        if (audioBase64.isNotEmpty) {
          final audioBytes = base64Decode(audioBase64);
          final blob = html.Blob([audioBytes], 'audio/wav');
          final url = html.Url.createObjectUrlFromBlob(blob);
          setState(() => _audioUrl = url);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error in simulation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error in simulation: $e')),
      );
    }
  }

  Future<void> _handleVoiceQueryChat(String text) async {
    setState(() => _debugMsg += '💬 Chat input: $text\n');
    setState(() { _isLoading = true; _transcription = ''; _assistantResponse = ''; _audioUrl = ''; _recordedAudioUrl = ''; });
    try {
      final resp = await http.post(
        Uri.parse('http://localhost:8000/api/voice-query'),
        body: {'telugu_text': text},
      );
      setState(() => _debugMsg += '✅ Chat server responded: ${resp.statusCode}\n');
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        setState(() {
          _isLoading = false;
          _transcription = j['asr_text'] ?? text;
          _translatedText = j['translated_text'] ?? '';
          _assistantResponse = j['ai_response_te'] ?? j['ai_response_en'] ?? '';
        });
        if (j['audio'] != null && (j['audio'] as String).isNotEmpty) {
          final bytes = base64Decode(j['audio']);
          final blob = html.Blob([bytes], 'audio/wav');
          final url = html.Url.createObjectUrlFromBlob(blob);
          setState(() => _audioUrl = url);
        }
      } else {
        setState(() { _isLoading = false; _debugMsg += '❌ Chat failed: ${resp.statusCode}\n'; });
      }
    } catch (e) {
      setState(() { _isLoading = false; _debugMsg += '❌ Chat error: $e\n'; });
    }
  }
}
