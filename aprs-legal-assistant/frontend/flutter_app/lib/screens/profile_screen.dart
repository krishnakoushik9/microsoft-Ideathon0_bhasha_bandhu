import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'course_detail_screen.dart';

/// ProfileScreen: Settings and user preferences for the legal assistant app.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Profile information
  String userName = 'User Name';
  String email = 'user@example.com';
  String phone = '+91 9876543210';
  String userRole = 'Client';

  // Settings
  bool isDarkMode = true;
  bool enableNotifications = true;
  bool enableSoundEffects = true;
  bool enableBiometricAuth = true;
  bool useTelugu = false;
  String selectedFont = 'Montserrat';
  String selectedFontSize = 'Medium';
  String dataRetentionPeriod = '90 days';
  String privacyMode = 'Standard';
  
  // Bhashini Model IDs
  final String asrTeluguModelId = '66e41f28e2f5842563c988d9';
  final String translationTeluguEnglishModelId = '67b871747d193a1beb4b847e';
  final String ttsEnglishModelId = '6576a17e00d64169e2f8f43d';

  // List of certification courses
  final List<String> courseList = [
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1C2331) : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF0A1128) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          _buildProfileSection(),
          const SizedBox(height: 24),
          // Certification Courses
          Text(
            'Certification Courses',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: courseList.length,
            itemBuilder: (context, idx) {
              final course = courseList[idx];
              return ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailScreen(courseName: course),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? const Color(0xFF0A1128) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  course,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Account settings
          _buildSettingsSection('Account Settings', [
            _buildSettingItem(
              'Edit Profile Information',
              'Update your name, email, and other details',
              Icons.person_outline,
              const Color(0xFF00CCFF),
              () => _showProfileEditDialog(),
            ),
            _buildSettingItem(
              'Legal Documents',
              'Manage your uploaded legal documents',
              Icons.folder_outlined,
              const Color(0xFF536DFE),
              () {},
            ),
            _buildSettingItem(
              'Case History',
              'View your case history and interactions',
              Icons.history,
              const Color(0xFF7C4DFF),
              () {},
            ),
            _buildSettingItem(
              'Saved Conversations',
              'View and manage saved legal conversations',
              Icons.bookmark_border,
              const Color(0xFFFF4081),
              () {},
            ),
          ]),
          const SizedBox(height: 16),
          
          // Preferences
          _buildSettingsSection('Preferences', [
            _buildSwitchSettingItem(
              'Dark Mode',
              isDarkMode ? 'Using dark theme' : 'Using light theme',
              Icons.dark_mode_outlined,
              const Color(0xFF00BFA5),
              isDarkMode,
              (value) {
                setState(() {
                  isDarkMode = value;
                });
              },
            ),
            _buildDropdownSettingItem(
              'Language',
              'Select your preferred language',
              Icons.language,
              const Color(0xFFFFD180),
              useTelugu ? 'Telugu' : 'English',
              ['English', 'Telugu'],
              (value) {
                setState(() {
                  useTelugu = value == 'Telugu';
                });
              },
            ),
            _buildDropdownSettingItem(
              'Font Size',
              'Adjust the text size throughout the app',
              Icons.format_size,
              const Color(0xFF00CCFF),
              selectedFontSize,
              ['Small', 'Medium', 'Large', 'Extra Large'],
              (value) {
                setState(() {
                  selectedFontSize = value;
                });
              },
            ),
            _buildDropdownSettingItem(
              'Font Style',
              'Change the font style throughout the app',
              Icons.font_download_outlined,
              const Color(0xFF7C4DFF),
              selectedFont,
              ['Montserrat', 'Roboto', 'Poppins', 'Open Sans'],
              (value) {
                setState(() {
                  selectedFont = value;
                });
              },
            ),
          ]),
          const SizedBox(height: 16),
          
          // Privacy and security
          _buildSettingsSection('Privacy & Security', [
            _buildSwitchSettingItem(
              'Biometric Authentication',
              enableBiometricAuth ? 'Enabled' : 'Disabled',
              Icons.fingerprint,
              const Color(0xFFFF4081),
              enableBiometricAuth,
              (value) {
                setState(() {
                  enableBiometricAuth = value;
                });
              },
            ),
            _buildDropdownSettingItem(
              'Data Retention',
              'How long to keep your conversation data',
              Icons.access_time,
              const Color(0xFF00BFA5),
              dataRetentionPeriod,
              ['30 days', '60 days', '90 days', '180 days', '1 year'],
              (value) {
                setState(() {
                  dataRetentionPeriod = value;
                });
              },
            ),
            _buildDropdownSettingItem(
              'Privacy Mode',
              'Choose your default privacy level for conversations',
              Icons.security,
              const Color(0xFF536DFE),
              privacyMode,
              ['Standard', 'Enhanced', 'Maximum'],
              (value) {
                setState(() {
                  privacyMode = value;
                });
              },
            ),
            _buildSettingItem(
              'Delete All Data',
              'Permanently delete all your data and history',
              Icons.delete_outline,
              Colors.red,
              () => _showDeleteDataDialog(),
            ),
          ]),
          const SizedBox(height: 16),
          
          // Notifications
          _buildSettingsSection('Notifications', [
            _buildSwitchSettingItem(
              'Push Notifications',
              enableNotifications ? 'Enabled' : 'Disabled',
              Icons.notifications_none,
              const Color(0xFFFFD180),
              enableNotifications,
              (value) {
                setState(() {
                  enableNotifications = value;
                });
              },
            ),
            _buildSwitchSettingItem(
              'Sound Effects',
              enableSoundEffects ? 'Enabled' : 'Disabled',
              Icons.volume_up_outlined,
              const Color(0xFF00CCFF),
              enableSoundEffects,
              (value) {
                setState(() {
                  enableSoundEffects = value;
                });
              },
            ),
          ]),
          const SizedBox(height: 16),
          
          // Advanced settings for voice models
          _buildSettingsSection('Advanced Settings', [
            _buildAdvancedModelIdSetting(
              'ASR Model (Telugu)',
              asrTeluguModelId,
              Icons.record_voice_over,
              const Color(0xFF7C4DFF),
            ),
            _buildAdvancedModelIdSetting(
              'Translation Model (Telugu-English)',
              translationTeluguEnglishModelId,
              Icons.translate,
              const Color(0xFF00BFA5),
            ),
            _buildAdvancedModelIdSetting(
              'TTS Model (English)',
              ttsEnglishModelId,
              Icons.headphones,
              const Color(0xFFFF4081),
            ),
          ]),
          const SizedBox(height: 16),
          
          // Help and Support
          _buildSettingsSection('Help & Support', [
            _buildSettingItem(
              'Legal FAQ',
              'Frequently asked questions about legal topics',
              Icons.help_outline,
              const Color(0xFF00CCFF),
              () {},
            ),
            _buildSettingItem(
              'Contact Support',
              'Reach out to our support team for assistance',
              Icons.support_agent,
              const Color(0xFF536DFE),
              () {},
            ),
            _buildSettingItem(
              'Terms of Service',
              'View the terms of service for this application',
              Icons.gavel,
              const Color(0xFF7C4DFF),
              () {},
            ),
            _buildSettingItem(
              'Privacy Policy',
              'Review our privacy policy',
              Icons.privacy_tip_outlined,
              const Color(0xFFFF4081),
              () {},
            ),
          ]),
          const SizedBox(height: 24),
          
          // App information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black12 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDarkMode ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'APRS Legal Assistant',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    backgroundColor: const Color(0xFF3366FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Profile section with avatar and basic info
  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A1128),
            Color(0xFF1C3144),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userRole,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(Icons.email_outlined, email),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(Icons.phone_outlined, phone),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _showProfileEditDialog(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white70),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Edit Profile',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0, duration: 600.ms);
  }

  // Info chip for profile
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Settings section with title
  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? const Color(0xFF00CCFF) : const Color(0xFF1C3144),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black12 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDarkMode ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: isDarkMode ? ImageFilter.blur(sigmaX: 10, sigmaY: 10) : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Column(
                children: items,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.1, end: 0, duration: 600.ms, delay: 200.ms);
  }

  // Standard setting item with icon and action
  Widget _buildSettingItem(String title, String subtitle, IconData icon, Color iconColor, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: isDarkMode ? Colors.white54 : Colors.black45,
          ),
          onTap: onTap,
        ),
        Divider(
          height: 1,
          indent: 70,
          endIndent: 20,
          color: isDarkMode ? Colors.white12 : Colors.black12,
        ),
      ],
    );
  }

  // Switch setting item
  Widget _buildSwitchSettingItem(String title, String subtitle, IconData icon, Color iconColor, bool value, Function(bool) onChanged) {
    return Column(
      children: [
        SwitchListTile(
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          value: value,
          activeColor: const Color(0xFF00CCFF),
          onChanged: onChanged,
        ),
        Divider(
          height: 1,
          indent: 70,
          endIndent: 20,
          color: isDarkMode ? Colors.white12 : Colors.black12,
        ),
      ],
    );
  }

  // Dropdown setting item
  Widget _buildDropdownSettingItem(String title, String subtitle, IconData icon, Color iconColor, String value, List<String> options, Function(String) onChanged) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          trailing: DropdownButton<String>(
            value: value,
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 24,
            elevation: 16,
            style: GoogleFonts.montserrat(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            underline: Container(
              height: 0,
            ),
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
            items: options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            dropdownColor: isDarkMode ? const Color(0xFF1C2331) : Colors.white,
          ),
          onTap: () {},
        ),
        Divider(
          height: 1,
          indent: 70,
          endIndent: 20,
          color: isDarkMode ? Colors.white12 : Colors.black12,
        ),
      ],
    );
  }

  // Advanced model ID setting
  Widget _buildAdvancedModelIdSetting(String title, String modelId, IconData icon, Color iconColor) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  modelId,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          isThreeLine: true,
        ),
        Divider(
          height: 1,
          indent: 70,
          endIndent: 20,
          color: isDarkMode ? Colors.white12 : Colors.black12,
        ),
      ],
    );
  }

  // Edit profile dialog
  void _showProfileEditDialog() {
    final nameController = TextEditingController(text: userName);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);
  
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: userRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: ['Client', 'Legal Professional', 'Administrator']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    if (value != null) userRole = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                userName = nameController.text;
                email = emailController.text;
                phone = phoneController.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00CCFF),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.montserrat(),
            ),
          ),
        ],
      ),
    );
  }

  // Delete data confirmation dialog
  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete All Data',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'This action will permanently delete all your data including case history, saved documents, and conversations. This action cannot be undone.',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement delete functionality here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'All data has been deleted',
                    style: GoogleFonts.montserrat(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.montserrat(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
