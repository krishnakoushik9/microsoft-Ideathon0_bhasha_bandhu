import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseName;
  const CourseDetailScreen({Key? key, required this.courseName}) : super(key: key);

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isLoading = true;
  String _content = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourseContent();
  }

  Future<void> _loadCourseContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/kavvy-search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': 'Provide a certification course outline and lesson content for certification course: ${widget.courseName}',
          'num_results': 3
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _content = data['gemini_answer'] ?? 'No content available.';
        });
      } else {
        setState(() {
          _error = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch course content: $e';
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
        title: Text(widget.courseName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    child: Text(
                      _content,
                      style: GoogleFonts.montserrat(fontSize: 16, height: 1.5),
                    ),
                  )),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Certificate generation coming soon!')),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Generate Certificate'),
        ),
      ),
    );
  }
}
