import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:async';
import 'dart:js' as js;
import 'dart:math';

/// VoiceScreen: Record audio and display transcription
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({Key? key}) : super(key: key);

  @override
  _VoiceScreenState createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  // Audio recording
  html.MediaRecorder? _mediaRecorder;
  List<dynamic> _audioChunks = [];
  html.MediaStream? _stream;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  
  // Flag to simulate recording for testing
  bool _simulateRecording = false; // Set to false for actual recording
  
  bool _isLoading = false;
  bool _isRecording = false;
  String _transcription = '';
  String _assistantResponse = '';
  String _originalTeluguText = '';
  String _translatedText = '';
  String _audioUrl = '';
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  double _sheetSize = 0.0;
  
  // Language selection
  bool _useTeluguASR = true; // Default to Telugu
  
  // Bhashini model IDs for Telugu → English voice pipeline
  final String _asrTeluguModelId = '66e41f28e2f5842563c988d9';
  final String _translationTeluguEnglishModelId = '67b871747d193a1beb4b847e';
  final String _ttsEnglishModelId = '6576a17e00d64169e2f8f43d';

  // Custom pulsing bar for audio visualization
  Widget _buildPulsingBar(int index) {
    // Randomize the animation to make it look more natural
    final randomHeight = 20.0 + (index * 10.0);
    final randomDuration = 600 + (index * 100);

    return Container(
      width: 8,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
      .custom(
        duration: Duration(milliseconds: randomDuration),
        builder: (context, value, child) => SizedBox(
          width: 8,
          height: 20 + randomHeight * value,
          child: child,
        ),
      );
  }

  @override
  void dispose() {
    _stopRecording();
    _recordingTimer?.cancel();
    _stream?.getTracks().forEach((track) => track.stop());
    _sheetController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // No initialization needed until recording starts
  }

  // Initialize audio recording with user's microphone
  Future<void> _initializeRecording() async {
    if (_simulateRecording) {
      setState(() {
        // Ready to record (simulated)
      });
      return;
    }
    
    try {
      // Request microphone access
      _stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'audio': true,
      });
      
      // Create a MediaRecorder instance
      _mediaRecorder = html.MediaRecorder(_stream!, {'mimeType': 'audio/webm'});
      
      // Set up event handlers using addEventListener instead of properties
      _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
        final dataEvent = event as html.BlobEvent;
        if (dataEvent.data != null && dataEvent.data!.size > 0) {
          _audioChunks.add(dataEvent.data!);
        }
      });
      
      setState(() {
        // Ready to record
      });
    } catch (e) {
      print('Error initializing recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing microphone: $e')),
      );
    }
  }

  // Start recording audio
  Future<void> _startRecording() async {
    await _initializeRecording();
    
    // Clear previous recording data
    _audioChunks = [];
    _recordingDuration = 0;
    
    if (_simulateRecording) {
      // Start a timer to track recording duration and simulate recording
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
      // Start the media recorder and timer
      _mediaRecorder!.start();
      
      // Start a timer to track recording duration
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
    
    // Show recording indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recording ${_useTeluguASR ? 'Telugu' : 'English'} audio...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Stop recording and process the audio
  void _stopRecording() {
    _recordingTimer?.cancel();
    
    if (_simulateRecording) {
      setState(() => _isRecording = false);
      _simulateProcessRecording();
    } else if (_mediaRecorder != null && _mediaRecorder!.state == 'recording') {
      // Add stop event listener before stopping
      _mediaRecorder!.addEventListener('stop', (html.Event _) {
        _processRecording();
      });
      
      // Stop the media recorder
      _mediaRecorder!.stop();
      
      setState(() => _isRecording = false);
    }
  }

  // Simulate processing of recording for testing purposes
  Future<void> _simulateProcessRecording() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate a delay as if we were processing audio
      await Future.delayed(const Duration(seconds: 2));
      
      // Generate sample response data based on the language
      final sampleText = _useTeluguASR 
          ? 'నాకు నాయశాస్త్ర సలహా కావాలి' // Telugu for "I need legal advice"
          : 'I need legal advice';
      
      // Create a simulated response
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
        _transcription = _useTeluguASR ? response['asr_text'] ?? '' : response['translated_text'] ?? '';
        _assistantResponse = _useTeluguASR ? response['ai_response_te'] ?? '' : response['ai_response_en'] ?? '';
        _sheetSize = 0.4; // Show the sheet with transcription
      });
      
      // Create audio URL if audio data is available
      if (response['audio'] != null && response['audio'] != '') {
        final audioBase64 = response['audio'] as String;
        // Make sure audioBase64 is not null before decoding
        if (audioBase64.isNotEmpty) {
          final audioBytes = base64Decode(audioBase64);
          final blob = html.Blob([audioBytes], 'audio/wav');
          final url = html.Url.createObjectUrlFromBlob(blob);
          setState(() {
            _audioUrl = url;
          });
        }
        
        // Optionally play audio automatically
        // _playAudio(url);
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

  // Process the actual recording and send to backend
  Future<void> _processRecording() async {
    setState(() => _isLoading = true);
    
    try {
      // Create a blob from the audio chunks
      final blob = html.Blob(_audioChunks, 'audio/webm');
      
      // Convert the blob to a base64 string for sending
      final reader = html.FileReader();
      final readerCompleter = Completer<String>();
      
      reader.onLoadEnd.listen((event) {
        if (reader.readyState == html.FileReader.DONE) {
          // Get the base64 data (remove the data URL prefix)
          final base64Data = reader.result as String;
          final base64Audio = base64Data.split(',')[1]; // Remove 'data:audio/webm;base64,' prefix
          readerCompleter.complete(base64Audio);
        } else {
          readerCompleter.completeError('Failed to read file');
        }
      });
      
      reader.onError.listen((event) {
        readerCompleter.completeError('Error reading file: ${reader.error}');
      });
      
      // Read as data URL
      reader.readAsDataUrl(blob);
      
      // Wait for the read to complete
      final base64Audio = await readerCompleter.future;
      
      // Use http package to make the request with form data
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8000/api/voice-query'),
      );
      
      // Add the audio_base64 field
      request.fields['audio_base64'] = base64Audio;
      request.fields['language'] = _useTeluguASR ? 'te' : 'en';
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Check if fallback was used
        final usedFallback = responseData['used_fallback'] == true;
        
        if (usedFallback) {
          // Show popup about using offline NeMo ASR
          _showFallbackPopup();
        }
        
        setState(() {
          _isLoading = false;
          _originalTeluguText = responseData['asr_text'] ?? '';
          _translatedText = responseData['translated_text'] ?? '';
          _transcription = _useTeluguASR ? responseData['asr_text'] ?? '' : responseData['translated_text'] ?? '';
          _assistantResponse = _useTeluguASR ? responseData['ai_response_te'] ?? '' : responseData['ai_response_en'] ?? '';
          _sheetSize = 0.4; // Show the sheet with transcription
        });
        
        // Create audio URL if audio data is available
        if (responseData['audio'] != null && responseData['audio'] != '') {
          final audioBase64 = responseData['audio'] as String;
          // Make sure audioBase64 is not null before decoding
          if (audioBase64.isNotEmpty) {
            final audioBytes = base64Decode(audioBase64);
            final blob = html.Blob([audioBytes], 'audio/wav');
            final url = html.Url.createObjectUrlFromBlob(blob);
            setState(() {
              _audioUrl = url;
            });
            
            // Optionally play audio automatically
            _playAudio(url);
          }
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error processing recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing recording: $e'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              // Clear audio chunks and try again
              _audioChunks.clear();
              _startRecording();
            },
          ),
        ),
      );
    }
  }

  // Show popup when fallback to NeMo ASR is used
  void _showFallbackPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 10),
            Text('Using Offline Mode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The Bhashini API is currently unavailable. Your audio has been processed using the offline NeMo ASR model instead.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Your audio has been saved to the test_audio folder and processed using librosa.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Play audio from URL
  void _playAudio(String url) {
    try {
      final audioElement = html.AudioElement(url);
      audioElement.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  // Build the recording button
  Widget _buildRecordingButton() {
    return GestureDetector(
      onTapDown: (_) {
        if (!_isRecording && !_isLoading) {
          _startRecording();
        }
      },
      onTapUp: (_) {
        if (_isRecording) {
          _stopRecording();
        }
      },
      onTapCancel: () {
        if (_isRecording) {
          _stopRecording();
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: _isRecording
              ? Colors.red
              : Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 36,
              ),
      ),
    );
  }

  // Build the audio visualization
  Widget _buildAudioVisualization() {
    return Container(
      height: 80,
      width: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          5,
          (index) => _buildPulsingBar(index),
        ),
      ),
    );
  }

  // Build the recording timer
  Widget _buildRecordingTimer() {
    final minutes = (_recordingDuration / 60).floor().toString().padLeft(2, '0');
    final seconds = (_recordingDuration % 60).toString().padLeft(2, '0');
    
    return Text(
      '$minutes:$seconds',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // Build language selection toggle
  Widget _buildLanguageToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Language:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        ToggleButtons(
          borderRadius: BorderRadius.circular(8),
          selectedBorderColor: Theme.of(context).colorScheme.primary,
          selectedColor: Colors.white,
          fillColor: Theme.of(context).colorScheme.primary,
          color: Theme.of(context).colorScheme.primary,
          constraints: const BoxConstraints(
            minHeight: 40,
            minWidth: 100,
          ),
          isSelected: [_useTeluguASR, !_useTeluguASR],
          onPressed: (index) {
            setState(() {
              _useTeluguASR = index == 0;
            });
          },
          children: const [
            Text('Telugu', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // Build the response sheet
  Widget _buildResponseSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: _sheetSize,
      minChildSize: 0.0,
      maxChildSize: 0.9,
      controller: _sheetController,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // You said (transcription)
              if (_transcription.isNotEmpty) ...[
                const Text(
                  'You said:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _transcription,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      if (_useTeluguASR && _translatedText.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 10),
                        const Text(
                          'Translated to English:',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _translatedText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Assistant response
              if (_assistantResponse.isNotEmpty) ...[
                Row(
                  children: [
                    const Text(
                      'Assistant response:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_audioUrl.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () {
                          _playAudio(_audioUrl);
                        },
                        tooltip: 'Play audio response',
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _assistantResponse,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

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
                    'Tap and hold the microphone button to start recording, release to stop.\n\n'
                    'You can speak in Telugu, and the assistant will respond in Telugu.\n\n'
                    'Use the language toggle to switch between Telugu and English.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Language toggle at the top
              _buildLanguageToggle(),
              
              const SizedBox(height: 40),
              
              // Voice recording UI
              _isRecording
                  ? Column(
                      children: [
                        _buildAudioVisualization(),
                        const SizedBox(height: 20),
                        _buildRecordingTimer(),
                        const SizedBox(height: 20),
                        const Text(
                          'Release to stop recording',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.mic,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isLoading
                              ? 'Processing...'
                              : 'Tap and hold to speak in ${_useTeluguASR ? 'Telugu' : 'English'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
              
              const SizedBox(height: 40),
              
              // Recording button
              _buildRecordingButton(),
            ],
          ),
          
          // Response sheet
          _buildResponseSheet(context),
        ],
      ),
    );
  }
}
