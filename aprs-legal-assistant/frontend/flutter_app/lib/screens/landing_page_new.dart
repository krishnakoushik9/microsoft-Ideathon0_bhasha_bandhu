import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui';

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;
    
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
                      
                      const SizedBox(height: 80),
                      
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
                    ],
                  ),
                ),
              ),
              
              // Features section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
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
                        crossAxisCount: isTablet ? 3 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.85,
                        children: [
                          _buildFeatureCard(
                            icon: Icons.chat_bubble_outline,
                            title: 'AI Chat',
                            description: 'Get legal advice through natural conversation with our advanced AI',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00CCFF), Color(0xFF3366FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 0,
                          ),
                          _buildFeatureCard(
                            icon: Icons.mic,
                            title: 'Voice Interaction',
                            description: 'Speak your legal questions and get audio responses',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFFD500F9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 200,
                          ),
                          _buildFeatureCard(
                            icon: Icons.translate,
                            title: 'Multilingual',
                            description: 'Support for Telugu and English with Bhashini integration',
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF4081), Color(0xFFFF9E80)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 400,
                          ),
                          _buildFeatureCard(
                            icon: Icons.upload_file,
                            title: 'Document Upload',
                            description: 'Upload legal documents for analysis and questions',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00BFA5), Color(0xFF64FFDA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 600,
                          ),
                          _buildFeatureCard(
                            icon: Icons.picture_as_pdf,
                            title: 'PDF Generation',
                            description: 'Generate legal summaries and documents in PDF format',
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD180), Color(0xFFFF6D00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 800,
                          ),
                          _buildFeatureCard(
                            icon: Icons.search,
                            title: 'Legal Search',
                            description: 'Search across legal documents and precedents',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF536DFE), Color(0xFF8C9EFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 1000,
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
                  padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
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
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildTeamMemberCard(
                            name: 'P. KRISHNA KOUSHIK',
                            role: 'LEADER - MAIN DEV',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00CCFF), Color(0xFF3366FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 0,
                          ),
                          _buildTeamMemberCard(
                            name: 'VEERESH',
                            role: 'END PRODUCT TESTING',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFFD500F9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 200,
                          ),
                          _buildTeamMemberCard(
                            name: 'SRINITHA',
                            role: 'MARKETING',
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF4081), Color(0xFFFF9E80)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 400,
                          ),
                          _buildTeamMemberCard(
                            name: 'ASHWITHA',
                            role: 'BUG TESTING',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00BFA5), Color(0xFF64FFDA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            delay: 600,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Call to action
              SliverToBoxAdapter(
                child: Container(
                  height: 400,
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
                            fontSize: 28,
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
                            Navigator.pushReplacementNamed(context, '/home');
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
                        '© 2025 APRS LEGAL ASSISTANT',
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
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required int delay,
  }) {
    return Container(
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
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
  }) {
    return Container(
      width: 250,
      height: 300,
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                ),
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
}
