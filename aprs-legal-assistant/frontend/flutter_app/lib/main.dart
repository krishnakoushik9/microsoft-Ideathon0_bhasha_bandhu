import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';
import 'screens/chat_screen.dart' as chat_screen;
import 'screens/documents_screen.dart';
import 'screens/voice_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ask_kavvy_screen.dart';
import 'screens/landing_page.dart';
import 'screens/find_lawyer_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/glass_sidebar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageProvider = LanguageProvider();
  await languageProvider.loadLanguage();
  
  runApp(
    ChangeNotifierProvider.value(
      value: languageProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APRS Legal Assistant',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const AppShell(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _sidebarController;
  bool _isSidebarCollapsed = true;

  final _screens = [
    const chat_screen.ChatScreen(),
    const DocumentsScreen(),
    const VoiceScreen(),
    const FindLawyerScreen(),
    const AskVeraxPravaktaScreen(),
    const ProfileScreen(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Chat', 'icon': Icons.chat_outlined, 'activeIcon': Icons.chat},
    {'title': 'Documents', 'icon': Icons.description_outlined, 'activeIcon': Icons.description},
    {'title': 'Voice', 'icon': Icons.mic_outlined, 'activeIcon': Icons.mic},
    {'title': 'Find Lawyers', 'icon': Icons.gavel_outlined, 'activeIcon': Icons.gavel},
    {'title': 'Ask Verax-Pravakta', 'icon': Icons.travel_explore_outlined, 'activeIcon': Icons.travel_explore},
    {'title': 'Profile', 'icon': Icons.person_outline, 'activeIcon': Icons.person},
  ];

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
      if (_isSidebarCollapsed) {
        _sidebarController.reverse();
      } else {
        _sidebarController.forward();
      }
    });
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _menuItems[_selectedIndex]['title'],
          style: GoogleFonts.nunito(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: isWideScreen 
            ? null 
            : IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: _toggleSidebar,
              ),
      ),
      body: Stack(
        children: [
          // Main Content
          Positioned.fill(
            left: isWideScreen ? 80 : 0,
            child: _screens[_selectedIndex],
          ),
          
          // Glass Sidebar for Desktop/Tablet
          if (isWideScreen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GlassSidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: _onItemSelected,
                menuItems: _menuItems,
                isCollapsed: _isSidebarCollapsed,
                controller: _sidebarController,
              ),
            ),
        ],
      ),
      // Bottom Navigation for Mobile/Tablet
      bottomNavigationBar: isWideScreen
          ? null
          : Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: _onItemSelected,
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    selectedItemColor: theme.primaryColor,
                    unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
                    selectedLabelStyle: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.nunito(
                      fontSize: 12,
                    ),
                    items: _menuItems
                        .map(
                          (item) => BottomNavigationBarItem(
                            icon: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6, 
                                horizontal: 12,
                              ),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: _selectedIndex == _menuItems.indexOf(item)
                                    ? theme.primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _selectedIndex == _menuItems.indexOf(item)
                                    ? item['activeIcon']
                                    : item['icon'],
                                size: 24,
                              ),
                            ),
                            label: item['title'],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
    );
  }
}
