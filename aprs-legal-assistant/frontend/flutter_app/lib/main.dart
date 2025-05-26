import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'screens/chat_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/voice_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ask_kavvy_screen.dart';
import 'screens/landing_page.dart';
import 'screens/find_lawyer_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
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

/// AppShell: Main scaffold with bottom navigation
class AppShell extends StatefulWidget {
  const AppShell({Key? key}) : super(key: key);
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final _screens = [
    const ChatScreen(),
    const DocumentsScreen(),
    const VoiceScreen(),
    const FindLawyerScreen(),
    const AskKavvyScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isTablet) {
          // Tablet layout with NavigationRail
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: constraints.maxWidth > 800,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.chat_outlined),
                      selectedIcon: Icon(Icons.chat),
                      label: Text('Chat'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.description_outlined),
                      selectedIcon: Icon(Icons.description),
                      label: Text('Documents'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.mic_outlined),
                      selectedIcon: Icon(Icons.mic),
                      label: Text('Voice'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.gavel_outlined),
                      selectedIcon: Icon(Icons.gavel),
                      label: Text('Lawyers'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.travel_explore_outlined),
                      selectedIcon: Icon(Icons.travel_explore),
                      label: Text('Ask Kavvy'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Phone layout with BottomNavigationBar
          return Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ).animate().fadeIn(duration: 300.ms),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_outlined),
                  activeIcon: Icon(Icons.chat),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.description_outlined),
                  activeIcon: Icon(Icons.description),
                  label: 'Documents',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.mic_outlined),
                  activeIcon: Icon(Icons.mic),
                  label: 'Voice',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.gavel_outlined),
                  activeIcon: Icon(Icons.gavel),
                  label: 'Lawyers',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.travel_explore_outlined),
                  activeIcon: Icon(Icons.travel_explore),
                  label: 'Ask Kavvy',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        }
      }
    );
  }
}
