import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:html' as html;
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:path_provider/path_provider.dart';

/// A widget that provides document preview functionality.
/// This works with various document types including PDF, images, and text.
class DocumentPreviewDialog extends StatefulWidget {
  final String documentName;
  final String documentPath;
  final String documentType; // 'pdf', 'image', 'text', etc.
  final double documentSize;
  final DateTime uploadDate;

  const DocumentPreviewDialog({
    Key? key,
    required this.documentName,
    required this.documentPath,
    required this.documentType,
    required this.documentSize,
    required this.uploadDate,
  }) : super(key: key);

  @override
  State<DocumentPreviewDialog> createState() => _DocumentPreviewDialogState();
}

class _DocumentPreviewDialogState extends State<DocumentPreviewDialog> {
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';
  
  // For document content
  String? textContent;
  String? base64Image;
  String? pdfViewerUrl;
  
  @override
  void initState() {
    super.initState();
    _loadDocumentContent();
  }
  
  void _loadDocumentContent() async {
    // In a real app, this would load from a server endpoint
    // For now, we'll simulate loading with a delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    try {
      setState(() {
        if (widget.documentType == 'pdf') {
          // For PDF, in a real app we would create a URL to view the PDF
          pdfViewerUrl = 'https://example.com/view-pdf?path=${widget.documentPath}';
          // For the demo, simulate PDF viewer with an iframe 
          
          // In a real implementation, you'd have code like:
          // final response = await http.get(Uri.parse(apiEndpoint + widget.documentPath));
          // if (response.statusCode == 200) {
          //   final bytes = response.bodyBytes;
          //   final base64Pdf = base64Encode(bytes);
          //   pdfViewerUrl = 'data:application/pdf;base64,$base64Pdf';
          // }
        } 
        else if (widget.documentType == 'image') {
          // For images, we'd load the image data
          // In a demo, create a placeholder colored image
          base64Image = _generatePlaceholderImage();
        } 
        else if (widget.documentType == 'text') {
          // For text, we'd load the text content
          textContent = _generateSampleText();
        }
        
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = 'Failed to load document: $e';
      });
    }
  }
  
  // Helper to generate sample text for the preview
  String _generateSampleText() {
    if (widget.documentName.toLowerCase().contains('witness')) {
      return '''
Witness Statement

Date: August 15, 2023
Case Number: CR-2023-45678
Witness: Jane Doe

I, Jane Doe, hereby declare the following to be true to the best of my knowledge and belief:

On July 12, 2023, at approximately 3:30 PM, I was walking my dog in Central Park near the boathouse. The weather was clear and visibility was good. I witnessed an individual, whom I would describe as a male in his 30s, approximately 6 feet tall with dark hair, wearing a blue jacket and jeans, approach the victim.

The individual appeared to be agitated and was speaking loudly. I could not hear the exact words being exchanged, but the conversation appeared to be heated. After approximately two minutes of conversation, the individual suddenly pushed the victim, causing them to fall backward.

I immediately called 911 and reported the incident. The police arrived within approximately 10 minutes. During this time, I remained at a safe distance but did not lose sight of either the victim or the aggressor.

I have not been coached or influenced in making this statement, and I understand that providing false information to law enforcement is a punishable offense.

Signed,
Jane Doe
''';
    } else if (widget.documentName.toLowerCase().contains('case')) {
      return '''
LEGAL CASE BRIEF

CASE: Smith v. Johnson
CITATION: 123 F.3d 456 (9th Cir. 2023)
COURT: United States Court of Appeals for the Ninth Circuit
DATE DECIDED: March 15, 2023

FACTS:
Plaintiff John Smith filed a lawsuit against Defendant Mary Johnson alleging breach of contract related to a consulting agreement. The agreement, signed on January 10, 2022, stipulated that Johnson would provide marketing services for Smith's business for a period of one year. After six months, Johnson ceased providing services, claiming that Smith had failed to provide necessary information and resources as required by Section 3.2 of the agreement.

PROCEDURAL HISTORY:
The District Court for the Northern District of California granted summary judgment in favor of Johnson, finding that Smith had materially breached the contract first by failing to provide the resources specified in Section 3.2.

ISSUE:
Whether Smith's failure to provide certain information and resources constituted a material breach of the contract that justified Johnson's nonperformance.

HOLDING:
The Court of Appeals affirmed the District Court's ruling, holding that Smith's failure to provide the specified resources was a material breach that excused Johnson's further performance under the contract.

REASONING:
The court emphasized that Section 3.2 of the agreement explicitly required Smith to provide Johnson with access to customer data, marketing materials, and staff support that were essential for Johnson to perform her obligations. Evidence showed that Smith provided incomplete data and inadequate staff support despite repeated requests from Johnson. The court rejected Smith's argument that these deficiencies were minor, noting that they fundamentally impaired Johnson's ability to execute the marketing strategies contemplated by the agreement.

SIGNIFICANCE:
This case reaffirms the principle that a material breach by one party excuses the other party's obligation to continue performance. It also highlights the importance of clearly defining mutual obligations in service contracts.
''';
    } else {
      return '''
LEGAL RESEARCH MEMORANDUM

TO: Senior Partner
FROM: Associate Attorney
DATE: September 12, 2023
RE: Legal Analysis of Force Majeure Clauses During Public Health Emergencies

QUESTION PRESENTED:
Do government-mandated business closures during a public health emergency trigger force majeure clauses in commercial lease agreements in the jurisdiction of [State]?

SHORT ANSWER:
Based on recent case law in [State], government-mandated business closures during a public health emergency will generally trigger force majeure clauses if such clauses specifically enumerate "governmental restrictions," "acts of government," or "pandemics" as qualifying events. However, the specific language of each force majeure provision is determinative, and courts have been reluctant to excuse rent obligations entirely without express contractual language addressing payment obligations during force majeure events.

STATEMENT OF FACTS:
Our client, Commercial Tenant LLC, operates a restaurant in a shopping mall owned by Landlord Properties Inc. On March 15, 2023, the state government issued an executive order mandating the closure of all non-essential businesses, including restaurants (except for takeout service), in response to a public health emergency. The closure lasted for three months, during which time Commercial Tenant LLC's revenue decreased by approximately 80%.

The lease agreement between Commercial Tenant LLC and Landlord Properties Inc. contains the following force majeure clause:

"If either party to this Lease is prevented or delayed from performing any obligation under this Lease by reason of strikes, labor troubles, inability to procure materials, failure of power, restrictive governmental laws or regulations, riots, insurrection, war, pandemic, epidemic, or other reason of a like nature not the fault of or within the reasonable control of the party delayed, then performance of such obligation shall be excused for the period of the delay."

DISCUSSION:
[Several paragraphs of legal analysis would follow here]

CONCLUSION:
Based on the specific language of the force majeure clause in our client's lease and recent case law in [State], Commercial Tenant LLC has a reasonable argument that its performance obligations – other than payment obligations – were temporarily excused during the government-mandated closure period. However, most courts in [State] have required tenants to continue paying rent unless the force majeure clause explicitly excuses payment obligations during qualifying events. We should consider negotiating with Landlord Properties Inc. for a rent reduction during the affected period rather than relying solely on the force majeure clause.

RECOMMENDED NEXT STEPS:
1. Review any additional provisions in the lease that might interact with the force majeure clause
2. Research additional cases specific to the local jurisdiction
3. Prepare for settlement negotiations with Landlord Properties Inc.
''';
    }
  }
  
  // Helper to generate a placeholder colored image for demo purposes
  String _generatePlaceholderImage() {
    // In a real app, this would be an actual image loaded from the server
    // For the demo, we're creating a colored SVG as a placeholder
    final colors = ['#3498db', '#2ecc71', '#e74c3c', '#f39c12', '#9b59b6'];
    final color = colors[widget.documentName.length % colors.length];
    
    final svgString = '''
<svg width="400" height="300" xmlns="http://www.w3.org/2000/svg">
  <rect width="400" height="300" fill="$color" />
  <text x="50%" y="50%" font-family="Arial" font-size="24" fill="white" text-anchor="middle">
    ${widget.documentName}
  </text>
  <text x="50%" y="65%" font-family="Arial" font-size="16" fill="white" text-anchor="middle">
    Image Preview Placeholder
  </text>
</svg>
''';
    
    final base64Encoded = base64Encode(utf8.encode(svgString));
    return 'data:image/svg+xml;base64,$base64Encoded';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with document info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1128),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getDocumentIcon(),
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.documentName,
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.documentSize.toStringAsFixed(1)} MB • ${_formatDate(widget.uploadDate)}',
                              style: GoogleFonts.montserrat(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                
                // Document content area
                Expanded(
                  child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3366FF),
                        ),
                      )
                    : isError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error Loading Document',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildPreviewContent(),
                ),
                
                // Footer with actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.black12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Document Preview',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Document download started')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3366FF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sharing document...')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3366FF),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPreviewContent() {
    // Display supported format note at the top
    Widget supportedFormatsNote = Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Only PDF, DOCX, and TXT files are supported for preview',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
    
    if (widget.documentType == 'pdf') {
      // For the demo, use a sample PDF or simulate one
      // In a real app, this would load from the actual file path
      return Column(
        children: [
          supportedFormatsNote,
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // In an actual implementation with a real PDF file:
                  // SfPdfViewer.network(pdfViewerUrl!),
                  // But for now, show a placeholder with a button to launch viewer
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'data:image/svg+xml;base64,${base64Encode(utf8.encode('''
                          <svg width="120" height="140" xmlns="http://www.w3.org/2000/svg">
                            <rect x="10" y="10" width="100" height="120" rx="10" fill="#F44336" />
                            <text x="60" y="70" font-family="Arial" font-size="24" text-anchor="middle" fill="white">PDF</text>
                          </svg>
                          '''))}',
                          height: 140,
                          width: 120,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'PDF Viewer',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.documentName,
                          style: GoogleFonts.montserrat(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open PDF'),
                          onPressed: () {
                            // In a real app, this would open the PDF in a viewer
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening PDF viewer...')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (widget.documentType == 'word') {
      // DOCX viewer - currently not directly supported in Flutter
      // Would need a specialized package or server-side conversion
      return Column(
        children: [
          supportedFormatsNote,
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'data:image/svg+xml;base64,${base64Encode(utf8.encode('''
                    <svg width="120" height="140" xmlns="http://www.w3.org/2000/svg">
                      <rect x="10" y="10" width="100" height="120" rx="10" fill="#2B579A" />
                      <text x="60" y="70" font-family="Arial" font-size="24" text-anchor="middle" fill="white">DOCX</text>
                    </svg>
                    '''))}',
                    height: 140,
                    width: 120,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Word Document',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.documentName,
                    style: GoogleFonts.montserrat(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.shade50,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Word Document Preview',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This is a preview of the document content. In a full implementation, this would show the actual Word document content.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download for Full View'),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading document...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (widget.documentType == 'image') {
      return Column(
        children: [
          supportedFormatsNote,
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: base64Image != null
                  ? Center(
                      child: Image.network(
                        base64Image!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : const Center(
                      child: Text('Image could not be loaded'),
                    ),
            ),
          ),
        ],
      );
    } else if (widget.documentType == 'text') {
      return Column(
        children: [
          supportedFormatsNote,
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: textContent != null
                    ? SelectableText(
                        textContent!,
                        style: GoogleFonts.robotoMono(
                          height: 1.5,
                          fontSize: 14,
                        ),
                      )
                    : const Text('Text content could not be loaded'),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          supportedFormatsNote,
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_drive_file,
                    size: 64,
                    color: Colors.blue.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unsupported Document Type',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This file format is not supported for preview.\nOnly PDF, DOCX, and TXT files can be previewed.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download File'),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading file...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  IconData _getDocumentIcon() {
    switch (widget.documentType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'text':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}
