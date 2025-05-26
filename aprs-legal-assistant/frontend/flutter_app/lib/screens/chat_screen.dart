import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'dart:html' if (dart.library.html) 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../widgets/chat_bubble.dart';
import '../models/ai_provider.dart';
import 'ar_case_explorer_screen.dart';
import '../widgets/ai_provider_toggle.dart';
import 'animated_model_switch_shimmer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Dynamic color scheme for provider switching
  Color get _primaryColor => _aiProvider == AIProvider.gemini ? Color(0xFF8E24AA) : Theme.of(context).colorScheme.primary;
  Color get _secondaryColor => _aiProvider == AIProvider.gemini ? Color(0xFFD1C4E9) : Theme.of(context).colorScheme.secondary;
  Color get _onPrimary => _aiProvider == AIProvider.gemini ? Colors.white : Theme.of(context).colorScheme.onPrimary;
  Color get _onSecondary => _aiProvider == AIProvider.gemini ? Color(0xFF4A148C) : Theme.of(context).colorScheme.onSecondary;
  Color get _backgroundColor => _aiProvider == AIProvider.gemini ? Color(0xFFF3E5F5) : Theme.of(context).scaffoldBackgroundColor;
  Color get _surfaceColor => _aiProvider == AIProvider.gemini ? Color(0xFFE1BEE7) : Theme.of(context).colorScheme.surface;
  Color get _onBackground => _aiProvider == AIProvider.gemini ? Color(0xFF4A148C) : Theme.of(context).colorScheme.onBackground;
  Color get _onSurface => _aiProvider == AIProvider.gemini ? Color(0xFF4A148C) : Theme.of(context).colorScheme.onSurface;

  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool _isLoading = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  AIProvider _aiProvider = AIProvider.huggingFace;
  bool _showModelSwitchShimmer = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Group messages by date for separators
  Map<String, List<Map<String, dynamic>>> get _groupedMessages {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final message in messages) {
      final date = message['timestamp'] ?? DateTime.now();
      final dateStr = '${date.year}-${date.month}-${date.day}';
      grouped.putIfAbsent(dateStr, () => []);
      grouped[dateStr]!.add(message);
    }
    return grouped;
  }
  
  // Function to generate and download PDF
  bool _isGeneratingPdf = false;
  
  // PDF generation functionality using direct API integration
  Future<void> _generateAndDownloadPdf() async {
    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No conversation to summarize')),
      );
      return;
    }
    
    setState(() {
      _isGeneratingPdf = true;
    });
    
    try {
      // Format the conversation for the PDF
      final conversationText = messages.map((msg) => 
        "${msg['sender'] == 'user' ? 'Client' : 'Legal Assistant'}: ${msg['text']}"
      ).join('\n\n');
      
      // Current date and time for the document
      final now = DateTime.now();
      final dateStr = "${now.day}/${now.month}/${now.year}";
      final timeStr = "${now.hour}:${now.minute}";
      
      try {
        // Use Gemini API to generate a legal summary
        final geminiApiKey = "AIzaSyBDB6r6ucOBrqkckO0QaIJhcO9E1_73d_4";
        final geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";
        
        // Create a prompt for legal summary
        final prompt = """
        You are a legal assistant tasked with creating a formal legal summary document.
        Based on the following conversation between a client and a legal assistant, create a structured legal summary with these sections:
        
        1. SUMMARY OF LEGAL CONSULTATION
        2. KEY LEGAL ISSUES IDENTIFIED
        3. RECOMMENDED ACTIONS
        4. LEGAL REFERENCES AND AUTHORITIES
        5. NEXT STEPS
        
        Format this as a formal legal document with proper legal terminology and structure.
        Include a disclaimer at the end stating this is an AI-generated summary for informational purposes only and not legal advice.
        
        Here is the conversation to summarize:
        
        $conversationText
        """;
        
        // Call Gemini API for the legal summary
        final summaryResponse = await http.post(
          Uri.parse('$geminiEndpoint?key=$geminiApiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [{'text': prompt}]
              }
            ],
            'generationConfig': {
              'temperature': 0.2,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 2048,
            }
          }),
        );
        
        if (summaryResponse.statusCode == 200) {
          final jsonResponse = jsonDecode(summaryResponse.body);
          final legalSummary = jsonResponse['candidates'][0]['content']['parts'][0]['text'] ?? 
                      'Unable to generate legal summary.';
          
          // Generate PDF using pdfjs or another PDF library
          // For now, we'll create a simple HTML that can be converted to PDF
          final htmlContent = '''
          <!DOCTYPE html>
          <html>
          <head>
            <title>Legal Consultation Summary</title>
            <style>
              body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
              .header { text-align: center; margin-bottom: 30px; }
              .title { font-size: 24px; font-weight: bold; margin-bottom: 5px; }
              .date { font-size: 14px; color: #666; }
              .content { margin-top: 20px; }
              .footer { margin-top: 50px; font-size: 12px; color: #999; text-align: center; }
              .section { margin-top: 20px; }
              .section-title { font-weight: bold; border-bottom: 1px solid #ccc; padding-bottom: 5px; }
            </style>
          </head>
          <body>
            <div class="header">
              <div class="title">LEGAL CONSULTATION SUMMARY</div>
              <div class="date">Date: $dateStr | Time: $timeStr</div>
            </div>
            <div class="content">
              ${legalSummary.replaceAll('\n', '<br>')}
            </div>
            <div class="footer">
              <p>This document was generated based on an AI-assisted legal consultation. This summary is for informational purposes only and does not constitute legal advice.</p>
            </div>
          </body>
          </html>
          ''';
          
          // Save HTML and trigger download (web-compatible)
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'legal_summary_$timestamp.html';

          // The following code works for Flutter Web
          final bytes = utf8.encode(htmlContent);
          final blob = html.Blob([bytes], 'text/html');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();
          html.Url.revokeObjectUrl(url);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Legal summary downloaded. Open it in a browser and use Print to save as PDF.'),
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          print('Gemini API error: ${summaryResponse.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating legal summary. Status: ${summaryResponse.statusCode}')),
          );
        }
      } catch (apiError) {
        print('Error with API: $apiError');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating legal summary: ${apiError.toString().substring(0, min(apiError.toString().length, 100))}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
      print('Error generating PDF: $e');
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {},
      onError: (error) {},
    );
    setState(() {});
  }

  void _toggleListening() {
    if (!_speechAvailable) return;
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() => _controller.text = result.recognizedWords);
        },
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    HapticFeedback.lightImpact(); // Haptic feedback on send

    final userMessage = {
      'sender': 'user',
      'text': trimmedText,
      'timestamp': DateTime.now()
    };

    setState(() {
      messages.add(userMessage);
      _isLoading = true;
      _controller.clear();
    });

    // Scroll to bottom after adding message
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollToBottom();
    });

    try {
      String responseText;
      
      // Direct API integration without backend
      if (_aiProvider == AIProvider.gemini) {
        // Direct Gemini API call
        try {
          // Using Google Generative AI API directly
          final geminiApiKey = "AIzaSyBDB6r6ucOBrqkckO0QaIJhcO9E1_73d_4"; // Using the provided API key
          final geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";
          
          final response = await http.post(
            Uri.parse('$geminiEndpoint?key=$geminiApiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [{'text': trimmedText}]
                }
              ],
              'generationConfig': {
                'temperature': 0.7,
                'topK': 40,
                'topP': 0.95,
                'maxOutputTokens': 1024,
              }
            }),
          );
          
          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            responseText = jsonResponse['candidates'][0]['content']['parts'][0]['text'] ?? 
                          'Sorry, I couldn\'t generate a response.';
          } else {
            print('Gemini API error: ${response.statusCode}');
            responseText = 'Sorry, I encountered an error with the Gemini API. Status: ${response.statusCode}';
          }
        } catch (e) {
          print('Error with Gemini API: $e');
          responseText = 'Sorry, I encountered an error with the Gemini API: ${e.toString().substring(0, min(e.toString().length, 100))}';
        }
      } else {
        // HuggingFace API direct call
        try {
          final huggingFaceApiKey = "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"; // Using the provided API key
          final huggingFaceEndpoint = "https://api-inference.huggingface.co/models/mistralai/Mixtral-8x7B-Instruct-v0.1";
          
          final response = await http.post(
            Uri.parse(huggingFaceEndpoint),
            headers: {
              'Authorization': 'Bearer $huggingFaceApiKey',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'inputs': trimmedText,
              'parameters': {
                'max_length': 1000,
                'temperature': 0.7,
                'top_p': 0.95,
              }
            }),
          );
          
          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            if (jsonResponse is List && jsonResponse.isNotEmpty) {
              responseText = jsonResponse[0]['generated_text'] ?? 'No response found';
            } else {
              responseText = jsonResponse['generated_text'] ?? 'No response found';
            }
          } else {
            print('HuggingFace API error: ${response.statusCode}');
            responseText = 'Sorry, I encountered an error with the HuggingFace API. Status: ${response.statusCode}';
          }
        } catch (e) {
          print('Error with HuggingFace API: $e');
          responseText = 'Sorry, I encountered an error with the HuggingFace API: ${e.toString().substring(0, min(e.toString().length, 100))}';
        }
      }

      final assistantMessage = {
        'sender': 'assistant',
        'text': responseText,
        'timestamp': DateTime.now()
      };

      setState(() => messages.add(assistantMessage));

      // Scroll to bottom after receiving response
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() => messages.add({
            'sender': 'assistant',
            'text': 'Sorry, I encountered an error. Please try again.',
            'timestamp': DateTime.now()
          }));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: _onPrimary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('APRS Legal Assistant', style: TextStyle(color: _onPrimary)),
            const SizedBox(width: 14),
            AIProviderToggle(
              provider: _aiProvider,
              onChanged: (newProvider) async {
                if (_aiProvider != newProvider) {
                  setState(() {
                    _aiProvider = newProvider;
                    _showModelSwitchShimmer = true;
                  });
                  // Play sound effect
                  await _audioPlayer.play(AssetSource('sounds/model_switch.mp3'), volume: 0.85);
                  await Future.delayed(const Duration(milliseconds: 1100));
                  setState(() => _showModelSwitchShimmer = false);
                }
              },
            ),
          ],
        ),
        centerTitle: true,
        actions: [

          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            tooltip: 'Download Legal Summary PDF',
            onPressed: _isGeneratingPdf ? null : _generateAndDownloadPdf,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'APRS Legal Assistant',
                    applicationVersion: '1.0.0',
                    applicationIcon: Icon(
                      Icons.balance,
                      size: 50,
                      color: _primaryColor,
                    ),
                    children: [
                      Text('A legal assistant application using NeMo ASR and AI.'),
                    ],
                  );
                },
              ),
              if (_isGeneratingPdf)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.view_in_ar),
            tooltip: 'AR Case Explorer',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ARCaseExplorerScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Section button (assumed to be present in your UI)
          // Insert AR Corner button right below
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.view_in_ar),
              label: Text('AR Corner'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ARCaseExplorerScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _secondaryColor,
                foregroundColor: _onSecondary,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? _buildWelcomeScreen()
                : _buildChatList(),
          ),
          _buildLoadingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: _primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to APRS Legal Assistant',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: _onBackground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Ask me anything!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _onBackground.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slide(begin: Offset(0, 0.1), end: Offset.zero),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[messages.length - 1 - index];
        return ChatBubble(
          message: msg['text'] ?? '',
          isUser: msg['sender'] == 'user',
          timestamp: msg['timestamp'] ?? DateTime.now(),
          userColor: _primaryColor,
          userTextColor: _onPrimary,
          assistantColor: _surfaceColor,
          assistantTextColor: _onSurface,
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return _isLoading
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _showModelSwitchShimmer
                ? AnimatedModelSwitchShimmer()
                : CircularProgressIndicator(),
          )
        : SizedBox.shrink();
  }

  Widget _buildInputBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Type your question...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: theme.brightness == Brightness.light
                      ? Colors.grey.shade100
                      : Colors.grey.shade800,
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (text) => setState(() {}),
                onSubmitted: _sendMessage,
                minLines: 1,
                maxLines: 3,
              ),
            ),
            SizedBox(width: 8),
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.red.withOpacity(0.1)
                    : theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                onPressed: _speechAvailable ? _toggleListening : null,
                color: _isListening
                    ? Colors.red
                    : theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 8),
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: (_controller.text.trim().isNotEmpty && !_isLoading)
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: (_controller.text.trim().isNotEmpty && !_isLoading)
                    ? () => _sendMessage(_controller.text)
                    : null,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
