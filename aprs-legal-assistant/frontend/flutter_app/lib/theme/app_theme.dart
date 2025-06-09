import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Gemini Light Theme Colors
  static const Color geminiPrimary = Color(0xFF1E88E5); // Updated to blue tone
  static const Color geminiPrimaryLight = Color(0xFFE3F2FD); // Soft light blue
  static const Color geminiBackground = Color(0xFFFFFFFF); // White
  static const Color geminiSurface = Color(0xFFF9F9F9); // Slightly softer surface
  static const Color geminiError = Color(0xFFB00020);
  static const Color geminiTextPrimary = Color(0xFF212121);
  static const Color geminiTextSecondary = Color(0xFF424242);
  static const Color geminiUserBubble = Color(0xFFE3F2FD); // Light blue bubble
  static const Color geminiAssistantBubble = Color(0xFFF5F5F5); // No change
  static const Color geminiBubbleText = Color(0xFF212121);
  static const Color geminiUserBubbleBorder = Color(0xFFBBDEFB); // Light border blue

  // HuggingFace Dark Theme Colors
  static const Color hfPrimary = Color(0xFF2196F3); // No change
  static const Color hfPrimaryLight = Color(0xFF42A5F5); // No change
  static const Color hfBackground = Color(0xFF121212); // No change
  static const Color hfSurface = Color(0xFF1E1E1E); // No change
  static const Color hfError = Color(0xFFCF6679); // No change
  static const Color hfTextPrimary = Color(0xFFFFFFFF); // No change
  static const Color hfTextSecondary = Color(0xFFE0E0E0); // No change
  static const Color hfUserBubble = Color(0xFF2196F3); // No change
  static const Color hfAssistantBubble = Color(0xFF2C2C2C); // No change
  static const Color hfBubbleText = Color(0xFFFFFFFF); // No change
  static const Color hfUserBubbleBorder = Color(0xFF1976D2); // No change
}


enum ThemeType { gemini, huggingFace }

class AppTheme {
  // Theme data getters
  static ThemeData get geminiTheme => _buildGeminiTheme();
  static ThemeData get huggingFaceTheme => _buildHuggingFaceTheme();

  // Color getters for chat bubbles
  static Color get userBubbleLight => AppColors.geminiUserBubble;
  static Color get userBubbleDark => AppColors.hfUserBubble;
  static Color get assistantBubbleLight => AppColors.geminiAssistantBubble;
  static Color get assistantBubbleDark => AppColors.hfAssistantBubble;
  static Color get userBubbleBorderLight => AppColors.geminiUserBubbleBorder;
  static Color get userBubbleBorderDark => AppColors.hfUserBubbleBorder;
  static Color get bubbleTextLight => AppColors.geminiBubbleText;
  static Color get bubbleTextDark => AppColors.hfBubbleText;

  // Provide static methods for theme compatibility
  static ThemeData lightTheme() => _buildGeminiTheme();
  static ThemeData darkTheme() => _buildHuggingFaceTheme();

  // Theme builders
  static ThemeData _buildGeminiTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.geminiPrimary,
        primaryContainer: AppColors.geminiPrimaryLight,
        secondary: AppColors.geminiPrimaryLight,
        background: AppColors.geminiBackground,
        surface: AppColors.geminiSurface,
        error: AppColors.geminiError,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onBackground: AppColors.geminiTextPrimary,
        onSurface: AppColors.geminiTextPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.geminiBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.geminiSurface,
        foregroundColor: AppColors.geminiTextPrimary,
        elevation: 1,
        shadowColor: Color(0xFFE0E0E0),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.geminiPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Color(0xFFE0E0E0),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.geminiPrimary,
          side: BorderSide(color: Color(0xFFE0E0E0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(AppColors.geminiPrimary),
        trackColor: MaterialStateProperty.all(AppColors.geminiPrimaryLight),
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        borderColor: Color(0xFFE0E0E0),
        selectedBorderColor: AppColors.geminiPrimary,
        selectedColor: AppColors.geminiTextPrimary,
        fillColor: AppColors.geminiPrimaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      textTheme: GoogleFonts.nunitoTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: TextStyle(color: AppColors.geminiTextPrimary),
          displayMedium: TextStyle(color: AppColors.geminiTextPrimary),
          bodyLarge: TextStyle(color: AppColors.geminiTextPrimary),
          bodyMedium: TextStyle(color: AppColors.geminiTextPrimary),
          titleLarge: TextStyle(color: AppColors.geminiTextPrimary),
          titleMedium: TextStyle(color: AppColors.geminiTextPrimary),
          titleSmall: TextStyle(color: AppColors.geminiTextSecondary),
          labelLarge: TextStyle(color: AppColors.geminiTextPrimary),
          bodySmall: TextStyle(color: AppColors.geminiTextSecondary),
          labelSmall: TextStyle(color: AppColors.geminiTextSecondary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.geminiPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          elevation: 2,
          shadowColor: Color(0xFFE0E0E0),
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.geminiSurface,
        elevation: 2,
        shadowColor: Color(0xFFE0E0E0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.geminiSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.geminiPrimary, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData _buildHuggingFaceTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.hfPrimary,
        primaryContainer: AppColors.hfPrimaryLight,
        secondary: AppColors.hfPrimaryLight,
        background: AppColors.hfBackground,
        surface: AppColors.hfSurface,
        error: AppColors.hfError,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onBackground: AppColors.hfTextPrimary,
        onSurface: AppColors.hfTextPrimary,
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: AppColors.hfBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.hfSurface,
        foregroundColor: AppColors.hfTextPrimary,
        elevation: 1,
        shadowColor: Color(0xFF2C2C2C),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.hfPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Color(0xFF2C2C2C),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.hfPrimary,
          side: BorderSide(color: Color(0xFF2C2C2C)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(AppColors.hfPrimary),
        trackColor: MaterialStateProperty.all(AppColors.hfPrimaryLight),
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        borderColor: Color(0xFF2C2C2C),
        selectedBorderColor: AppColors.hfPrimary,
        selectedColor: AppColors.hfTextPrimary,
        fillColor: AppColors.hfPrimaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      textTheme: GoogleFonts.nunitoTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: TextStyle(color: AppColors.hfTextPrimary),
          displayMedium: TextStyle(color: AppColors.hfTextPrimary),
          bodyLarge: TextStyle(color: AppColors.hfTextPrimary),
          bodyMedium: TextStyle(color: AppColors.hfTextPrimary),
          titleLarge: TextStyle(color: AppColors.hfTextPrimary),
          titleMedium: TextStyle(color: AppColors.hfTextPrimary),
          titleSmall: TextStyle(color: AppColors.hfTextSecondary),
          labelLarge: TextStyle(color: AppColors.hfTextPrimary),
          bodySmall: TextStyle(color: AppColors.hfTextSecondary),
          labelSmall: TextStyle(color: AppColors.hfTextSecondary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.hfPrimary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.hfSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.hfPrimary, width: 1.5),
        ),
      ),
    );
  }
}

ThemeData lightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: Colors.blueAccent,
    ),
    scaffoldBackgroundColor: Colors.white,
  );
}

ThemeData darkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blueGrey,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: Colors.blueAccent,
    ),
    scaffoldBackgroundColor: Colors.black,
  );
}
