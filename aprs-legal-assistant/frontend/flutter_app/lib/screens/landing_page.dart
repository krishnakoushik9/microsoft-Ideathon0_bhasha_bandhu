import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'notice_page.dart';
import 'lawyer_admin_screen.dart';
import 'course_detail_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _backgroundAnimationController;
  late AnimationController _floatingElementsController;
  late AnimationController _heroTextController;
  
  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _floatingElementsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    
    _heroTextController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _backgroundAnimationController.dispose();
    _floatingElementsController.dispose();
    _heroTextController.dispose();
    super.dispose();
  }
  
  Widget _buildBulletPoint(String text, {Color color = const Color(0xFF00CCFF)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchitectureBox(String title, Color color, IconData icon) {
    return Container(
      width: 120,
      height: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchitectureArrow() {
    return Icon(
      Icons.arrow_forward,
      color: Colors.white.withOpacity(0.6),
      size: 24,
    );
  }

  Widget _buildArchitectureComponent(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStructureCard({required String title, required List<String> items, required Color color, required int delay}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 800.ms, delay: Duration(milliseconds: delay))
      .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: delay));
  }

  Widget _buildLibrariesCard({required String title, required List<Map<String, String>> items, required Color color, required int delay}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['name']!,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item['desc']!,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 800.ms, delay: Duration(milliseconds: delay))
      .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: delay));
  }



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;
    final courseList = [
      'Contract Law Essentials',
      'Criminal Law Fundamentals',
      'Family Law Practicum',
      'Property Law Overview',
      'Intellectual Property Rights',
      'Environmental Law Seminar',
      'Tax Law & Policy',
      'Corporate Governance',
      'Cyber Law & Data Privacy',
    ];
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [
                      Color(0xFF0A1128), // Deep navy
                      Color(0xFF1C3144), // Rich blue
                      Color(0xFF3E1C33), // Deep purple
                      Color(0xFF801336), // Burgundy
                    ],
                    stops: [
                      0.0,
                      0.3 + 0.1 * math.sin(_backgroundAnimationController.value * math.pi * 2),
                      0.6 + 0.1 * math.cos(_backgroundAnimationController.value * math.pi * 2),
                      1.0,
                    ],
                    transform: GradientRotation(_backgroundAnimationController.value * math.pi / 4),
                  ),
                ),
              );
            },
          ),
          
          // Floating elements (scales, paragraphs, gavel icons)
          ...List.generate(20, (index) {
            final random = math.Random(index);
            final size = random.nextDouble() * 30 + 10;
            final x = random.nextDouble() * MediaQuery.of(context).size.width;
            final y = random.nextDouble() * MediaQuery.of(context).size.height;
            final opacity = random.nextDouble() * 0.2 + 0.05;
            final rotationSpeed = random.nextDouble() * 2 + 1;
            
            return Positioned(
              left: x,
              top: y,
              child: AnimatedBuilder(
                animation: _floatingElementsController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _floatingElementsController.value * math.pi * 2 * rotationSpeed,
                    child: Opacity(
                      opacity: opacity,
                      child: Icon(
                        index % 3 == 0 ? Icons.gavel : 
                        index % 3 == 1 ? Icons.balance : 
                        Icons.library_books,
                        size: size,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          
          // Main content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero section
              SliverToBoxAdapter(
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App logo/title
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.balance,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ).animate(controller: _heroTextController)
                        .slideY(begin: -0.5, end: 0, duration: 1000.ms, curve: Curves.easeOutQuad)
                        .fadeIn(duration: 800.ms),
                      
                      const SizedBox(height: 40),
                      
                      // App title
                      Text(
                        'APRS LEGAL ASSISTANT',
                        style: GoogleFonts.montserrat(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(controller: _heroTextController)
                        .slideY(begin: 0.5, end: 0, duration: 1000.ms, delay: 300.ms, curve: Curves.easeOutQuad)
                        .fadeIn(duration: 800.ms, delay: 300.ms),
                      
                      const SizedBox(height: 24),
                      
                      // Tagline
                      Text(
                        'Justice Made Accessible Through AI',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(controller: _heroTextController)
                        .slideY(begin: 0.5, end: 0, duration: 1000.ms, delay: 600.ms, curve: Curves.easeOutQuad)
                        .fadeIn(duration: 800.ms, delay: 600.ms),
                      
                      const SizedBox(height: 20),
                      
                      // Scroll indicator
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white.withOpacity(0.7),
                        size: 36,
                      ).animate(
                        onPlay: (controller) => controller.repeat(),
                      )
                        .fadeIn(duration: 700.ms)
                        .then()
                        .fadeOut(duration: 700.ms)
                        .then()
                        .fadeIn(duration: 700.ms),
                      
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF4081),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 10,
                              shadowColor: const Color(0xFFFF4081).withOpacity(0.5),
                            ),
                            child: const Text('START USING OUR LEGAL SERVICE'),
                          ).animate()
                            .fadeIn(duration: 800.ms, delay: 400.ms)
                            .slideY(begin: 0.2, end: 0, delay: 400.ms)
                            .then(delay: 1000.ms)
                            .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.8))
                            .then()
                            .shimmer(delay: 2000.ms, duration: 1200.ms, color: Colors.white.withOpacity(0.8)),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LawyerAdminScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('LAWYER ADMIN PANEL'),
                          ).animate()
                            .fadeIn(duration: 800.ms, delay: 600.ms)
                            .slideY(begin: 0.2, end: 0, delay: 600.ms),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Project Overview section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROJECT OVERVIEW',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms)
                        .slideX(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      Container(
                        width: 80,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00CCFF),
                              Color(0xFFD500F9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms, delay: 300.ms)
                        .slideX(begin: -0.2, end: 0, delay: 300.ms),
                      
                      const SizedBox(height: 30),
                      
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'APRS Legal Assistant is an AI-powered legal platform designed to make legal assistance accessible to everyone.',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Our application combines cutting-edge AI technologies with legal expertise to provide:',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildBulletPoint('Conversational legal assistance through chat and voice interfaces'),
                                _buildBulletPoint('Multilingual support with Bhashini integration for Indian languages'),
                                _buildBulletPoint('Document analysis and information extraction'),
                                _buildBulletPoint('Legal document generation and summarization'),
                                _buildBulletPoint('Secure and private handling of sensitive legal information'),
                              ],
                            ),
                          ),
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms, delay: 500.ms)
                        .slideY(begin: 0.2, end: 0, delay: 500.ms),
                    ],
                  ),
                ),
              ),
              
              // Architecture Diagram section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ARCHITECTURE',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms)
                        .slideX(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      Container(
                        width: 80,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF7C4DFF),
                              Color(0xFFD500F9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms, delay: 300.ms)
                        .slideX(begin: -0.2, end: 0, delay: 300.ms),
                      
                      const SizedBox(height: 30),
                      
                      Container(
                        height: 300,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildArchitectureBox('Flutter Frontend', const Color(0xFF00CCFF), Icons.phone_android),
                                    const SizedBox(width: 20),
                                    _buildArchitectureArrow(),
                                    const SizedBox(width: 20),
                                    _buildArchitectureBox('FastAPI Backend', const Color(0xFF7C4DFF), Icons.storage),
                                    const SizedBox(width: 20),
                                    _buildArchitectureArrow(),
                                    const SizedBox(width: 20),
                                    _buildArchitectureBox('AI Services', const Color(0xFFFF4081), Icons.psychology),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildArchitectureComponent('RAG System', const Color(0xFF00BFA5)),
                                    _buildArchitectureComponent('Bhashini Voice', const Color(0xFFFFD180)),
                                    _buildArchitectureComponent('PDF Generator', const Color(0xFF536DFE)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms, delay: 500.ms),
                    ],
                  ),
                ),
              ),
              
              // Project Structure section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROJECT STRUCTURE',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms)
                        .slideX(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      Container(
                        width: 80,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00BFA5),
                              Color(0xFF64FFDA),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms, delay: 300.ms)
                        .slideX(begin: -0.2, end: 0, delay: 300.ms),
                      
                      const SizedBox(height: 30),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildStructureCard(
                              title: 'Frontend (Flutter)',
                              items: [
                                'screens/ - UI screens',
                                'widgets/ - Reusable components',
                                'theme/ - App styling',
                                'main.dart - Entry point',
                              ],
                              color: const Color(0xFF00CCFF),
                              delay: 0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStructureCard(
                              title: 'Backend (FastAPI)',
                              items: [
                                'main.py - API endpoints',
                                'rag.py - Retrieval system',
                                'tts.py - Voice processing',
                                'bhashini_voice.py - Multilingual',
                                'pdf_generator.py - Documents',
                              ],
                              color: const Color(0xFF7C4DFF),
                              delay: 200,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStructureCard(
                              title: 'Data',
                              items: [
                                'legal_documents/ - Repository',
                                'document_chunks/ - RAG chunks',
                                'audio/ - Voice recordings',
                                'pdf_exports/ - Generated PDFs',
                                'uploaded_docs/ - User files',
                              ],
                              color: const Color(0xFFFF4081),
                              delay: 400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Libraries & Technologies section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIBRARIES & TECHNOLOGIES',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms)
                        .slideX(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      Container(
                        width: 80,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFD180),
                              Color(0xFFFF6D00),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms, delay: 300.ms)
                        .slideX(begin: -0.2, end: 0, delay: 300.ms),
                      
                      const SizedBox(height: 30),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildLibrariesCard(
                              title: 'Frontend',
                              items: [
                                {'name': 'flutter_animate', 'desc': 'Powerful animations'},
                                {'name': 'flutter_speed_dial', 'desc': 'Modern FAB'},
                                {'name': 'google_fonts', 'desc': 'Typography'},
                                {'name': 'flutter_tts', 'desc': 'Text-to-speech'},
                                {'name': 'speech_to_text', 'desc': 'Voice input'},
                              ],
                              color: const Color(0xFF00CCFF),
                              delay: 0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildLibrariesCard(
                              title: 'Backend',
                              items: [
                                {'name': 'FastAPI', 'desc': 'High-performance API'},
                                {'name': 'Bhashini', 'desc': 'Multilingual voice'},
                                {'name': 'NeMo ASR', 'desc': 'Speech recognition'},
                                {'name': 'RAG System', 'desc': 'Legal information'},
                                {'name': 'CORS', 'desc': 'Cross-origin security'},
                              ],
                              color: const Color(0xFF7C4DFF),
                              delay: 200,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Features section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REVOLUTIONARY FEATURES',
                        style: GoogleFonts.montserrat(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms)
                        .slideX(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      Container(
                        width: 100,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00CCFF),
                              Color(0xFFD500F9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms, delay: 300.ms)
                        .slideX(begin: -0.2, end: 0, delay: 300.ms),
                      
                      const SizedBox(height: 60),
                      
                      // Features grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isTablet ? 3 : 2,
                        childAspectRatio: isTablet ? 1.5 : 1.8,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          _buildFeatureCard(
                            icon: Icons.chat_bubble_outline,
                            title: 'AI Legal Chat',
                            description: 'Get instant legal advice through our intuitive chat interface powered by advanced AI.',
                            color: const Color(0xFF00CCFF),
                            delay: 0,
                            bulletPoints: [
                              'Natural language understanding for complex legal queries',
                              'Instant responses based on up-to-date legal information',
                              'Personalized advice based on your specific situation',
                              'Secure and confidential conversation history',
                            ],
                          ),
                          _buildFeatureCard(
                            icon: Icons.mic,
                            title: 'Voice Assistant',
                            description: 'Speak naturally with our AI assistant for hands-free legal guidance on the go.',
                            color: const Color(0xFF7C4DFF),
                            delay: 200,
                            bulletPoints: [
                              'High-accuracy speech recognition technology',
                              'Natural-sounding voice responses with emotion',
                              'Hands-free operation for accessibility',
                              'Voice commands for navigating legal documents',
                            ],
                          ),
                          _buildFeatureCard(
                            icon: Icons.g_translate,
                            title: 'Multilingual Support',
                            description: 'Access legal assistance in multiple Indian languages through Bhashini integration.',
                            color: const Color(0xFFFF4081),
                            delay: 400,
                            bulletPoints: [
                              'Support for 10+ Indian languages including Hindi, Telugu, Tamil',
                              'Real-time translation of legal terms and concepts',
                              'Voice input and output in regional languages',
                              'Culturally appropriate legal advice',
                            ],
                          ),
                          _buildFeatureCard(
                            icon: Icons.description,
                            title: 'Document Analysis',
                            description: 'Upload legal documents for AI analysis, summarization, and key information extraction.',
                            color: const Color(0xFF00BFA5),
                            delay: 600,
                            bulletPoints: [
                              'Automatic extraction of key clauses and terms',
                              'Plain language summaries of complex legal documents',
                              'Risk assessment and flagging of potential issues',
                              'Comparison with standard legal templates',
                            ],
                          ),
                          _buildFeatureCard(
                            icon: Icons.picture_as_pdf,
                            title: 'PDF Generation',
                            description: 'Generate legal summaries and documents in PDF format',
                            color: const Color(0xFFFFD180),
                            delay: 800,
                            bulletPoints: [
                              'Professional-quality document formatting',
                              'Digital signature and authentication options',
                              'Custom templates for different legal needs',
                              'Secure sharing with password protection',
                            ],
                          ),
                          _buildFeatureCard(
                            icon: Icons.search,
                            title: 'Legal Search',
                            description: 'Search across legal documents and precedents',
                            color: const Color(0xFF536DFE),
                            delay: 1000,
                            bulletPoints: [
                              'Advanced semantic search beyond keywords',
                              'Access to comprehensive legal database',
                              'Citation tracking and reference linking',
                              'Relevance ranking based on your specific case',
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Team section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEET OUR TEAM',
                        style: GoogleFonts.montserrat(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms)
                        .slideX(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      Container(
                        width: 100,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF4081),
                              Color(0xFFFF9E80),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms, delay: 300.ms)
                        .slideX(begin: -0.2, end: 0, delay: 300.ms),
                      
                      const SizedBox(height: 60),
                      
                      // Team members
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildTeamMemberCard(
                            name: 'P. KRISHNA KOUSHIK',
                            role: 'LEADER - MAIN DEV',
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF00CCFF),
                                Color(0xFF3366FF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 0,
                            imagePath: 'krishna.jpg', // Team member image
                          ),
                          _buildTeamMemberCard(
                            name: 'VEERESH',
                            role: 'END PRODUCT TESTING',
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF7C4DFF),
                                Color(0xFFD500F9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 200,
                            imagePath: 'veeresh.jpg', // Team member image
                          ),
                          _buildTeamMemberCard(
                            name: 'SRINITHA',
                            role: 'MARKETING',
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF4081),
                                Color(0xFFFF9E80),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 400,
                            imagePath: 'sri.jpg', // Team member image
                          ),
                          _buildTeamMemberCard(
                            name: 'ASHWITHA',
                            role: 'BUG TESTING',
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF00BFA5),
                                Color(0xFF64FFDA),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 600,
                            imagePath: 'shu.jpg', // Team member image
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Business Potential section for investors
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF232946), // Deep blue for contrast
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Potential',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBulletPoint('Sponsored Content & Advertising: Run non‑intrusive ads for legal services, continuing‑ed courses, or allied services (process servers, translators).', color: Colors.amberAccent),
                      _buildBulletPoint('Publish sponsored “law firm spotlights” or “legal tech partners” in your newsletter or app dashboard.', color: Colors.cyanAccent),
                      _buildBulletPoint('Partnerships & Training: Partner with law schools or bar councils to license the tool for students and members.', color: Colors.greenAccent),
                      _buildBulletPoint('Run paid webinars, certification courses, or “Verax-Pravakta-powered” workshops on research methods.', color: Colors.pinkAccent),
                    ],
                  ),
                ),
              ),
              
              // Call to action
              SliverToBoxAdapter(
                child: Container(
                  height: 300,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A1128), // Deep navy
                        Color(0xFF1C3144), // Rich blue
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'READY TO TRANSFORM YOUR LEGAL EXPERIENCE?',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ).animate()
                          .fadeIn(duration: 800.ms)
                          .slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: 40),
                        
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4081),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            textStyle: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 10,
                            shadowColor: const Color(0xFFFF4081).withOpacity(0.5),
                          ),
                          child: const Text('START USING OUR LEGAL SERVICE'),
                        ).animate()
                          .fadeIn(duration: 800.ms, delay: 400.ms)
                          .slideY(begin: 0.2, end: 0, delay: 400.ms)
                          .then(delay: 1000.ms)
                          .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.8))
                          .then()
                          .shimmer(delay: 2000.ms, duration: 1200.ms, color: Colors.white.withOpacity(0.8)),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.black,
                  child: Column(
                    children: [
                      Text(
                        ' 2025 APRS LEGAL ASSISTANT',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'DEVELOPED FOR IDEATHON 2025',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NoticePage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'IMPORTANT NOTICE',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required int delay,
    required List<String> bulletPoints,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                ...bulletPoints.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 800.ms, delay: Duration(milliseconds: delay))
      .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: delay))
      .then(delay: Duration(milliseconds: delay + 1500))
      .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.2));
  }

  Widget _buildTeamMemberCard({
    required String name,
    required String role,
    required Gradient gradient,
    required int delay,
    String? imagePath,
  }) {
    // Extract just the filename from the path for web deployment
    String? imageFileName;
    if (imagePath != null && imagePath.isNotEmpty) {
      imageFileName = imagePath.split('/').last;
    }
    
    return MouseRegion(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 220,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Team member image with gradient background
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: imageFileName != null
                          ? Image.asset(
                              'assets/images/$imageFileName',
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to a colored circle with initials if image fails to load
                                return Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0] : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                name.isNotEmpty ? name[0] : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2000.ms),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    name,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Role with animation
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      role,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .shimmer(duration: 2000.ms, delay: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 800.ms, delay: Duration(milliseconds: delay))
      .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: delay));
  }
}
