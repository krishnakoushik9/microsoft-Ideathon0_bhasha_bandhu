import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FindLawyerScreen extends StatefulWidget {
  const FindLawyerScreen({Key? key}) : super(key: key);

  @override
  State<FindLawyerScreen> createState() => _FindLawyerScreenState();
}

class _FindLawyerScreenState extends State<FindLawyerScreen> {
  final List<String> _caseTypes = ['Family', 'Property', 'Criminal', 'Corporate'];
  String? _selectedCase;
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<dynamic> _lawyers = [];

  Future<void> _searchLawyers() async {
    if (_selectedCase == null) {
      setState(() => _error = 'Please select a case type');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _lawyers = [];
    });
    final queryParams = {
      'case_type': _selectedCase!,
      if (_locationController.text.trim().isNotEmpty)
        'location': _locationController.text.trim(),
    };
    final uri = Uri.http('localhost:8000', '/lawyers', queryParams);
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        setState(() => _lawyers = data);
      } else {
        setState(() => _error = 'Error: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Network error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Lawyer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Case Type'),
              items: _caseTypes
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              value: _selectedCase,
              onChanged: (v) => setState(() => _selectedCase = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  prefixIcon: Icon(Icons.location_on)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _searchLawyers,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Search'),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _lawyers.length,
                itemBuilder: (ctx, i) {
                  final l = _lawyers[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Specialties: ${l['specializations'].join(', ')}'),
                          const SizedBox(height: 4),
                          Text('Rating: ${l['rating']}/5'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.email),
                                onPressed: () => ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                        content: Text(
                                            'Email: ${l['contact_email']}'))),
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone),
                                onPressed: () => ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                        content: Text(
                                            'Phone: ${l['contact_phone']}'))),
                              ),
                            ],
                          ),
                          if ((l['reviews'] as List).isNotEmpty) ...[
                            const Divider(),
                            Text(
                              '"${l['reviews'][0]['comment']}"',
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
