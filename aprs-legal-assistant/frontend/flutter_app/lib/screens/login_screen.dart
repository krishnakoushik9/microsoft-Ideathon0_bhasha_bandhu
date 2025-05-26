import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  void _showComingSoonDialog(String service) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          '$service Login',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Integration with $service login is still in development.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome Back',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 16),
              Text(
                'Please log in to continue',
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
              const SizedBox(height: 32),
              SizedBox(
                width: 260,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _showComingSoonDialog('Google'),
                ).animate().slideY(begin: 1, end: 0, delay: 400.ms),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 260,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.apple, color: Colors.white),
                  label: const Text('Sign in with Apple'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _showComingSoonDialog('Apple'),
                ).animate().slideY(begin: 1, end: 0, delay: 600.ms),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 260,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.code, color: Colors.white),
                  label: const Text('Sign in with GitHub'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _showComingSoonDialog('GitHub'),
                ).animate().slideY(begin: 1, end: 0, delay: 800.ms),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 260,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.sms, color: Colors.white),
                  label: const Text('Sign in with SMS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _showComingSoonDialog('SMS'),
                ).animate().slideY(begin: 1, end: 0, delay: 1000.ms),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 260,
                child: TextButton(
                  child: const Text('Continue as Guest', style: TextStyle(color: Colors.white70)),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                ).animate().fadeIn(duration: 600.ms, delay: 1200.ms),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 260,
                child: ElevatedButton(
                  onPressed: () => _showComingSoonDialog('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Login', style: TextStyle(color: Colors.black)),
                ).animate().fadeIn(duration: 600.ms, delay: 1400.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
