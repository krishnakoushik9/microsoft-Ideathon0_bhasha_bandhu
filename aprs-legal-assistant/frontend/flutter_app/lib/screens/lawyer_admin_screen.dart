import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LawyerAdminScreen extends StatefulWidget {
  const LawyerAdminScreen({Key? key}) : super(key: key);

  @override
  State<LawyerAdminScreen> createState() => _LawyerAdminScreenState();
}

class _LawyerAdminScreenState extends State<LawyerAdminScreen> {
  List<dynamic> _lawyers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLawyers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  Future<void> _fetchLawyers() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.get(Uri.parse('http://localhost:8000/lawyers'));
      if (resp.statusCode == 200) {
        setState(() => _lawyers = jsonDecode(resp.body));
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _showLawyerDialog([Map<String, dynamic>? lawyer]) async {
    final nameCtrl = TextEditingController(text: lawyer?['name']);
    final specCtrl = TextEditingController(
        text: lawyer?['specializations'].join(', '));
    final locCtrl = TextEditingController(text: lawyer?['location']);
    final rateCtrl = TextEditingController(
        text: lawyer?['rating']?.toString());
    final emailCtrl = TextEditingController(text: lawyer?['contact_email']);
    final phoneCtrl = TextEditingController(text: lawyer?['contact_phone']);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lawyer == null ? 'Add Lawyer' : 'Edit Lawyer'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: specCtrl,
                decoration: const InputDecoration(
                    labelText: 'Specializations (comma separated)'),
              ),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: rateCtrl,
                decoration: const InputDecoration(labelText: 'Rating'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final payload = {
                'name': nameCtrl.text,
                'specializations': specCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .toList(),
                'location': locCtrl.text,
                'rating': double.tryParse(rateCtrl.text) ?? 0,
                'contact_email': emailCtrl.text,
                'contact_phone': phoneCtrl.text,
                'reviews': [],
              };
              if (lawyer == null) {
                await http.post(
                  Uri.parse('http://localhost:8000/lawyers'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload),
                );
              } else {
                await http.put(
                  Uri.parse('http://localhost:8000/lawyers/${lawyer['id']}'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload),
                );
              }
              Navigator.of(context).pop();
              _fetchLawyers();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLawyer(String id) async {
    await http.delete(Uri.parse('http://localhost:8000/lawyers/$id'));
    _fetchLawyers();
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Welcome to APRS Legal Assistant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Why Lawyers Should Join the APRS Legal Assistant Platform:'),
                const SizedBox(height: 16),
                ...[
                  'High-Intent Client Base\nUsers reaching out are already seeking legal help—filtered, engaged, and ready to consult.',
                  'Direct Lead Generation\nGet matched with users whose queries fall under your specialization (civil, property, consumer law, etc.).',
                  'Chat-to-PDF Export Feature\nEvery legal conversation is converted to a clean, shareable PDF—reducing your time spent on documentation.',
                  'Multilingual Legal Queries\nReach rural and regional users via chat/voice in Telugu, Hindi, and more—boosting your regional practice.',
                  'Voice-to-Text Client Communication\nUsers who can’t type can record voice messages in local languages; these are transcribed and translated for you.',
                  'AI-Assisted Pre-Screening\nChatbots handle repetitive and non-serious inquiries—so you only engage with serious, filtered leads.',
                  'Document Upload from Clients\nUsers can upload FIRs, notices, contracts, and case details for your easy review—saving back-and-forth.',
                  'One Dashboard to Manage Clients\nHandle multiple chats, queries, and follow-ups in a clean lawyer dashboard designed for professionals.',
                  'Legal Marketplace for Visibility\nBe featured in our “Find a Lawyer” section where users can browse and connect based on location, rating, or expertise.',
                  'Earn Reputation & Reviews\nVerified lawyer profiles can gain public ratings based on professionalism, helpfulness, and case support.',
                  'Secure Client Data Handling\nAll conversations and files are encrypted and securely stored, ensuring full confidentiality and data protection.',
                  'Grow Your Online Presence\nUse the platform as a digital footprint builder—more clients, more visibility, more trust.',
                  'No Middleman Commission\nWe don’t charge commission on your consulting—what you earn is 100% yours.',
                  'Early Lawyer Access Perks\nEarly adopters get top listing placement, free profile verification, and access to upcoming premium tools.',
                  'Built for the Future of Legal Tech\nStay ahead of the curve by embracing AI, legal automation, and smart user insights—before others do.',
                ].map((text) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(text),
                      ),
                    )).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lawyer Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showLawyerDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _lawyers.length,
              itemBuilder: (ctx, i) {
                final l = _lawyers[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    title: Text(l['name']),
                    subtitle: Text(
                        '${l['specializations'].join(', ')} • ${l['location']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showLawyerDialog(l),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteLawyer(l['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
