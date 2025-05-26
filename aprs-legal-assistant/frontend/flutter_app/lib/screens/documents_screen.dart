import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../widgets/document_preview.dart';

/// DocumentsScreen: Lists and manages uploaded legal documents.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({Key? key}) : super(key: key);

  @override
  _DocumentsScreenState createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool isLoading = true;
  bool isDarkMode = true;
  List<LegalDocument> documents = [];
  
  @override
  void initState() {
    super.initState();
    // Load sample documents for now
    _loadSampleDocuments();
  }
  
  void _loadSampleDocuments() {
    // Mock data for UI development
    final sampleDocuments = [
      LegalDocument(
        id: '1',
        name: 'Contract Agreement.pdf',
        size: 2.4,
        uploadDate: DateTime.now().subtract(const Duration(days: 2)),
        type: DocumentType.pdf,
        path: '/documents/contract_agreement.pdf',
      ),
      LegalDocument(
        id: '2',
        name: 'Case Brief.docx',
        size: 1.2,
        uploadDate: DateTime.now().subtract(const Duration(days: 5)),
        type: DocumentType.word,
        path: '/documents/case_brief.docx',
      ),
      LegalDocument(
        id: '3',
        name: 'Evidence Photo.jpg',
        size: 3.8,
        uploadDate: DateTime.now().subtract(const Duration(days: 1)),
        type: DocumentType.image,
        path: '/documents/evidence_photo.jpg',
      ),
      LegalDocument(
        id: '4',
        name: 'Witness Statement.txt',
        size: 0.5,
        uploadDate: DateTime.now().subtract(const Duration(days: 7)),
        type: DocumentType.text,
        path: '/documents/witness_statement.txt',
      ),
      LegalDocument(
        id: '5',
        name: 'Legal Research.pdf',
        size: 5.1,
        uploadDate: DateTime.now().subtract(const Duration(days: 10)),
        type: DocumentType.pdf,
        path: '/documents/legal_research.pdf',
      ),
    ];
    
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        documents = sampleDocuments;
        isLoading = false;
      });
    });
  }

  Future<void> _uploadDocument() async {
    // We'll implement this in the next chunk
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
    );
    
    if (result != null) {
      setState(() {
        // Show a loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading document...')),
        );
      });
      
      // In a real app, we would upload the file to the server here
      // For now, we'll just add it to our list with mock data
      final file = result.files.first;
      final newDoc = LegalDocument(
        id: (documents.length + 1).toString(),
        name: file.name,
        size: file.size / (1024 * 1024), // Convert to MB
        uploadDate: DateTime.now(),
        type: _getDocumentType(file.extension ?? ''),
        path: '/documents/${file.name}',
      );
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        documents.add(newDoc);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully!')),
        );
      });
      
      // If image or pdf, run OCR and show results
      if (newDoc.type == DocumentType.image || newDoc.type == DocumentType.pdf) {
        try {
          final result = await _performOCR(file);
          final text = result['text'] as String;
          final tags = List<String>.from(result['tags'] as List);
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('OCR Result'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: tags.map((t) => Chip(label: Text(t))).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OCR failed')),
          );
        }
      }
    }
  }
  
  // Perform OCR via backend
  Future<Map<String, dynamic>> _performOCR(PlatformFile file) async {
    final uri = Uri.http('localhost:8000', '/ocr');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
    );
    final streamedResp = await request.send();
    if (streamedResp.statusCode != 200) {
      throw Exception('OCR failed');
    }
    final respStr = await streamedResp.stream.bytesToString();
    return jsonDecode(respStr);
  }

  DocumentType _getDocumentType(String extension) {
    extension = extension.toLowerCase();
    if (extension == 'pdf') return DocumentType.pdf;
    if (extension == 'doc' || extension == 'docx') return DocumentType.word;
    if (extension == 'txt') return DocumentType.text;
    if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') return DocumentType.image;
    return DocumentType.other;
  }

  void _showDocumentPreview(LegalDocument document) {
    // Import the document preview widget
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DocumentPreviewDialog(
        documentName: document.name,
        documentPath: document.path,
        documentType: _getDocumentTypeString(document.type),
        documentSize: document.size,
        uploadDate: document.uploadDate,
      ),
    );
  }
  
  // Helper to convert enum to string for the preview dialog
  String _getDocumentTypeString(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return 'pdf';
      case DocumentType.word:
        return 'word';
      case DocumentType.text:
        return 'text';
      case DocumentType.image:
        return 'image';
      case DocumentType.other:
        return 'other';
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return Icons.picture_as_pdf;
      case DocumentType.word:
        return Icons.description;
      case DocumentType.text:
        return Icons.text_snippet;
      case DocumentType.image:
        return Icons.image;
      case DocumentType.other:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1C2331) : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Legal Documents',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF0A1128) : Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality to be implemented later
            },
          ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
          ),
        ],
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator(color: const Color(0xFF00CCFF)))
        : documents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No documents yet',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload your first document using the button below',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _uploadDocument,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      'Upload Document',
                      style: GoogleFonts.montserrat(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00CCFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Your Documents',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final document = documents[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isDarkMode ? const Color(0xFF2A3752) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getDocumentColor(document.type).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getDocumentIcon(document.type),
                                color: _getDocumentColor(document.type),
                              ),
                            ),
                            title: Text(
                              document.name,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              '${document.size.toStringAsFixed(1)} MB • ${_formatDate(document.uploadDate)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                  onPressed: () => _showDocumentPreview(document),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.redAccent,
                                  onPressed: () {
                                    // Delete functionality to be implemented later
                                    setState(() {
                                      documents.removeAt(index);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Document deleted')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () => _showDocumentPreview(document),
                          ),
                        ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideX(begin: 0.1, end: 0, duration: 300.ms, delay: (50 * index).ms);
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: documents.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _uploadDocument,
              backgroundColor: const Color(0xFF00CCFF),
              child: const Icon(Icons.upload_file),
            ),
    );
  }

  Color _getDocumentColor(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return Colors.red;
      case DocumentType.word:
        return Colors.blue;
      case DocumentType.text:
        return Colors.amber;
      case DocumentType.image:
        return Colors.green;
      case DocumentType.other:
        return Colors.purple;
    }
  }
}

enum DocumentType { pdf, word, text, image, other }

class LegalDocument {
  final String id;
  final String name;
  final double size; // in MB
  final DateTime uploadDate;
  final DocumentType type;
  final String path;

  LegalDocument({
    required this.id,
    required this.name,
    required this.size,
    required this.uploadDate,
    required this.type,
    required this.path,
  });
}
