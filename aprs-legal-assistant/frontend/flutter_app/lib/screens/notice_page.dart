import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoticePage extends StatelessWidget {
  const NoticePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IMPORTANT NOTICE'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'TECHNICAL CHALLENGES & CONCERNS',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Regarding Bhashini API Integration and Ideathon Support',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              
              _buildSectionTitle('1. Bhashini API Unavailability'),
              _buildParagraph(
                'We have encountered significant issues with the Bhashini API endpoints (https://bhashini.gov.in/ulca). '
                'Despite multiple attempts to integrate with the services as listed in the provided documentation, '
                'many of the endpoints are consistently returning errors or are completely unavailable. '
                'This has severely hampered our ability to implement the multilingual features that were central to our project concept.'
              ),
              _buildCodeBlock(
                'Endpoint status check from tableDownload.csv shows multiple "unavailable" services:\n'
                '"Bhashini-IIITH HimangY Telugu-English","translation","unavailable","28/08/2024"\n'
                '"Bhashini-Anuvaad OCR - Tesseract","ocr","unavailable","02/08/2024"'
              ),
              
              _buildSectionTitle('2. NeMo ASR Integration Challenges'),
              _buildParagraph(
                'The integration of the NeMo ASR models has been particularly problematic. '
                'We encountered numerous errors when attempting to use the Telugu ASR model as specified in the project requirements. '
                'The model loading process frequently fails with memory allocation errors, and when it does load, '
                'the transcription quality is significantly below what would be required for a production application.'
              ),
              _buildCodeBlock(
                'Error: CUDA out of memory. Tried to allocate 1.96 GiB. GPU 0 has a total capacity of 15.78 GiB of which 13.71 GiB is free. Process 12345 has 2.07 GiB memory in use.\n'
                'File "/home/krsna/Desktop/ideathon/NeMo/examples/asr/transcribe_speech.py", line 123, in <module>\n'
                '  transcriptions = asr_model.transcribe(paths2audio_files=audio_files)'
              ),
              
              _buildSectionTitle('3. Pipeline Integration Failures'),
              _buildParagraph(
                'The end-to-end pipeline for ASR → Translation → TTS has been impossible to implement reliably due to the '
                'inconsistent availability of the Bhashini services. We attempted to use the following model IDs as provided:'
              ),
              _buildCodeBlock(
                'ASR (Telugu): 66e41f28e2f5842563c988d9\n'
                'Translation (Telugu-English): 67b871747d193a1beb4b847e\n'
                'TTS (English): 6576a17e00d64169e2f8f43d'
              ),
              _buildParagraph(
                'However, the translation service frequently returns 503 Service Unavailable errors, making it impossible '
                'to create a reliable pipeline for the legal assistant application.'
              ),
              
              _buildSectionTitle('4. Flutter Web Deployment Issues'),
              _buildParagraph(
                'We encountered significant challenges with Flutter Web deployment, particularly around asset management '
                'and audio recording capabilities. The MediaRecorder API, which is essential for our voice input feature, '
                'has inconsistent browser support and required extensive workarounds.'
              ),
              _buildCodeBlock(
                'Error in voice_screen.dart:\n'
                'lib/screens/voice_screen.dart:94:31:\n'
                'Error: The getter \'blob\' isn\'t defined for the class \'BlobEvent\'.\n'
                ' - \'BlobEvent\' is from \'dart:html\'.\n'
                '        _audioChunks.add(data.blob!);\n'
                '                              ^^^^'
              ),
              
              _buildSectionTitle('5. Inadequate Technical Support'),
              _buildParagraph(
                'Throughout the Ideathon, we have faced a concerning lack of technical support from the organizing team. '
                'Our queries regarding the Bhashini API issues went unanswered, and there was no clear documentation on how to '
                'troubleshoot the various integration problems we encountered. This left us to rely heavily on AI assistance '
                'tools like Vibe Coding to identify and resolve errors, which significantly slowed our development process.'
              ),
              _buildParagraph(
                'When we did receive responses, they often lacked the technical depth needed to resolve our specific issues, '
                'suggesting a disconnect between the competition requirements and the actual technical feasibility of the project.'
              ),
              
              _buildSectionTitle('6. Documentation Inconsistencies'),
              _buildParagraph(
                'The documentation provided for the Bhashini services contains numerous inconsistencies and outdated information. '
                'API endpoints listed in the documentation often do not match the actual implementation, and the authentication '
                'process is poorly documented, leading to significant time spent on troubleshooting rather than development.'
              ),
              _buildCodeBlock(
                'Example of inconsistency:\n'
                'Documentation states: POST /services/inference/asr\n'
                'Actual endpoint requires: /services/inference/asr?serviceId=specific-id\n'
                'But the serviceId provided often returns: {"status":"FAILED","error":{"code":"SERVICE_UNAVAILABLE"}}'
              ),
              
              _buildSectionTitle('7. Hardware Resource Limitations'),
              _buildParagraph(
                'The NeMo ASR models require significant GPU resources that exceed what is typically available to student teams. '
                'This creates an accessibility barrier that disadvantages teams without access to high-end hardware. '
                'Our team had to implement various workarounds and simulations to demonstrate functionality that would ideally '
                'require more powerful computing resources.'
              ),
              
              _buildSectionTitle('8. Emotional and Practical Impact on Students'),
              _buildParagraph(
                'The constant barrage of technical failures, unclear documentation, and the absence of any real support has not just affected our project—it has taken a toll on our motivation, learning, and mental health. '
                'We entered this Ideathon with excitement and hope, eager to innovate and learn. Instead, we spent countless hours debugging problems that were not of our own making, chasing dead ends in the documentation, and waiting for responses from an organizing team that never came.'
              ),
              _buildParagraph(
                'It is disheartening to realize that the time and energy we invested in this project was wasted on trying to make broken APIs work, rather than building something meaningful. Many teams, including ours, were forced to abandon core features, simulate integrations, and focus on damage control rather than innovation.'
              ),
              _buildSectionTitle('9. Complete Lack of Communication and Empathy'),
              _buildParagraph(
                'The organizing team has shown a shocking lack of empathy and communication. Our emails, forum posts, and chat messages went unanswered for days or were met with generic, copy-pasted responses. There was no effort to understand or address the real issues faced by participants. '
                'This lack of engagement sends a clear message: the organizers are more interested in running an event for its own sake than in supporting the students and innovators who are supposed to benefit from it.'
              ),
              _buildParagraph(
                'At no point did we feel heard, respected, or valued as participants. The Ideathon became a test of endurance and frustration tolerance, not a celebration of creativity and technical skill.'
              ),
              _buildSectionTitle('10. Wasted Effort, Time, and Lost Learning Opportunities'),
              _buildParagraph(
                'The greatest tragedy of this experience is the lost opportunity for genuine learning and innovation. Instead of mastering new technologies, collaborating with peers, and building something we could be proud of, we were forced to spend our time on pointless troubleshooting. '
                'The hours lost to debugging broken endpoints, deciphering vague documentation, and waiting for nonexistent support could have been spent learning, building, and growing as engineers.'
              ),
              _buildParagraph(
                'This is not just our story—many teams have shared similar experiences. The Ideathon, as it stands, is failing its most important stakeholders: the students and innovators who are its lifeblood.'
              ),
              _buildSectionTitle('11. Call for Accountability and Real Change'),
              _buildParagraph(
                'We demand accountability from the Bhashini team, the Ideathon organizers, and everyone responsible for the technical infrastructure of this event. It is unacceptable to advertise features and APIs that do not work, to ignore the pleas of participants, and to waste the time and energy of hundreds of students.'
              ),
              _buildParagraph(
                '''We urge you to:
- Audit and fix the Bhashini API endpoints before any future events
- Provide clear, up-to-date, and honest documentation
- Offer real technical support with knowledgeable staff
- Communicate openly and empathetically with participants
- Value the time, effort, and well-being of students above all else'''),
              _buildSectionTitle('12. Specific Technical Grievances and Evidence'),
              _buildParagraph(
                'Below are some concrete examples of the issues we faced, with references to project files and logs:'
              ),
              _buildCodeBlock(
                '1. API endpoints in tableDownload.csv marked as unavailable, e.g. translation, OCR, and ASR for key languages.\n'
                '2. Frequent errors in voice_screen.dart, e.g. type errors, undefined properties, and platform inconsistencies.\n'
                '3. NeMo ASR model failures: CUDA out of memory, model not found, segmentation faults.\n'
                '4. Flutter asset pipeline bugs: images not loading, asset paths mismatched in web builds.\n'
                '5. Pipeline integration failures: 503 Service Unavailable, authentication errors, and silent timeouts.'
              ),
              _buildParagraph(
                'Our codebase is littered with TODOs, FIXME comments, and workaround hacks that should never have been necessary. The only thing that kept us afloat was AI-powered coding help (thank you, Vibe Coding), which was more responsive than the entire Ideathon support team combined.'
              ),
              _buildSectionTitle('Conclusion: A Plea for Respect and Reform'),
              _buildParagraph(
                'Despite these challenges, our team has worked diligently to deliver a functional legal assistant application '
                'that demonstrates the potential of multilingual voice interaction. However, we believe it is important to '
                'highlight these technical issues to improve future iterations of the Ideathon and to provide context for the '
                'evaluation of our submission.'
              ),
              _buildParagraph(
                'We would like to express our gratitude to AI tools like Vibe Coding that have been instrumental in helping us '
                'navigate these technical challenges. Without such assistance, identifying and resolving the numerous errors '
                'encountered would have been nearly impossible within the competition timeframe.'
              ),
              _buildParagraph(
                'We respectfully request that the judging panel take these technical limitations into account when evaluating '
                'all submissions, and we hope that future events will provide more robust technical support and infrastructure '
                'to enable participants to fully realize their innovative ideas.'
              ),
              
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Submitted with concern by the APRS Legal Assistant Team',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 25),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
  
  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 16,
          height: 1.5,
          color: Colors.black87,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
  
  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Text(
        code,
        style: GoogleFonts.sourceCodePro(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}
