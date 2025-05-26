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
  }

  Future<void> _fetchLawyers() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.get(Uri.http('localhost:8000', '/lawyers'));
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
                  Uri.http('localhost:8000', '/lawyers'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload),
                );
              } else {
                await http.put(
                  Uri.http('localhost:8000', '/lawyers/${lawyer['id']}'),
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
    await http.delete(Uri.http('localhost:8000', '/lawyers/$id'));
    _fetchLawyers();
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
