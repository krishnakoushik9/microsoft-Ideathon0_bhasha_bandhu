import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AskVeraxPravaktaScreen extends StatefulWidget {
  const AskVeraxPravaktaScreen({Key? key}) : super(key: key);

  @override
  State<AskVeraxPravaktaScreen> createState() => _AskVeraxPravaktaScreenState();
}

class _AskVeraxPravaktaScreenState extends State<AskVeraxPravaktaScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<dynamic> _results = [];
  String? _geminiAnswer;

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
      _geminiAnswer = null;
    });
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Please enter a query.';
      });
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/kavvy-search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query, 'num_results': 5}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _results = data['results'] ?? [];
          _geminiAnswer = data['gemini_answer'] ?? '';
        });
      } else {
        setState(() {
          _error = 'Error: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to connect to backend: $e';
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Verax-Pravakta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Friendly intro banner
            Card(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.indigo.shade900 : Colors.indigo.shade100,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Icon(Icons.travel_explore, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.indigo.shade400, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Meet Verax-Pravakta!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
                          const SizedBox(height: 4),
                          Text('Verax-Pravakta is your AI legal search assistant. Ask any question and Verax-Pravakta will search the web, then answer using the latest AI (powered by Gemini).', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Ask Verax-Pravakta a legal or general question...',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.text.isNotEmpty && !_isLoading)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _results = [];
                            _geminiAnswer = null;
                            _error = null;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _isLoading ? null : _search,
                    ),
                  ],
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (_error != null) ...[
              Card(
                color: Colors.red.shade100,
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else ...[
              if (_geminiAnswer != null && _geminiAnswer!.isNotEmpty) ...[
                Card(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.green.shade900 : Colors.lightGreen.shade50,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.smart_toy, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.green, size: 22),
                            const SizedBox(width: 6),
                            Text('Verax-Pravakta (AI) says:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _geminiAnswer!,
                          style: TextStyle(fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                        ),
                        const SizedBox(height: 12),
                        // Answer actions: copy, share, feedback
                        Row(
                          children: [
                            Tooltip(
                              message: 'Copy answer',
                              child: IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: _geminiAnswer!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Verax-Pravakta\'s answer copied!')),
                                  );
                                },
                              ),
                            ),
                            Tooltip(
                              message: 'Share answer',
                              child: IconButton(
                                icon: const Icon(Icons.share, size: 20),
                                onPressed: () async {
                                  await Share.share(_geminiAnswer!);
                                },
                              ),
                            ),
                            const Spacer(),
                            Tooltip(
                              message: 'Thumbs up',
                              child: IconButton(
                                icon: Icon(Icons.thumb_up_alt_outlined, color: Colors.green.shade700, size: 20),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Thanks for your feedback!')),
                                  );
                                },
                              ),
                            ),
                            Tooltip(
                              message: 'Thumbs down',
                              child: IconButton(
                                icon: Icon(Icons.thumb_down_alt_outlined, color: Colors.red.shade700, size: 20),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Feedback noted.')),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Powered by ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png',
                              height: 16,
                              width: 16,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 4),
                            const Text('Gemini', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_results.isNotEmpty) ...[
                const Text('Top Search Results:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, idx) {
                      final item = _results[idx];
                      return Card(
                        child: ListTile(
                          title: Text(item['title'] ?? ''),
                          subtitle: Text(item['snippet'] ?? ''),
                          onTap: () async {
                            final urlStr = item['url'];
                            if (urlStr != null && urlStr.isNotEmpty) {
                              final uri = Uri.parse(urlStr);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                  webOnlyWindowName: '_blank',
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not launch URL')),
                                );
                              }
                            }
                          },
                          trailing: Icon(Icons.open_in_new),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
