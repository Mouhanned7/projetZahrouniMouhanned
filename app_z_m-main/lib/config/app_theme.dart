import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primaryColor = Color(0xFF12B3A8);
  static const Color secondaryColor = Color(0xFFF59E0B);
  static const Color accentColor = Color(0xFFFF5D73);
  static const Color darkBg = Color(0xFF061120);
  static const Color darkSurface = Color(0xFF0D1E33);
  static const Color darkCard = Color(0xFF142A46);
  static const Color lightBg = Color(0xFFF3F7FB);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0E1726);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textOnDark = Color(0xFFE7EEF8);

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    const colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Color(0xFF2A1600),
      onSurface: textOnDark,
    );

    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
        bodyColor: textOnDark,
        displayColor: textOnDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface.withOpacity(0.76),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textOnDark,
        ),
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withOpacity(0.7)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface.withOpacity(0.7),
        labelStyle: TextStyle(color: textOnDark.withOpacity(0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentColor, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentColor, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: TextStyle(color: textOnDark.withOpacity(0.45)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withOpacity(0.12),
        selectedColor: primaryColor.withOpacity(0.28),
        secondarySelectedColor: primaryColor.withOpacity(0.28),
        side: BorderSide(color: primaryColor.withOpacity(0.38)),
        labelStyle: GoogleFonts.spaceGrotesk(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: darkSurface,
        selectedIconTheme: const IconThemeData(color: primaryColor),
        unselectedIconTheme: IconThemeData(color: textOnDark.withOpacity(0.55)),
        selectedLabelTextStyle: GoogleFonts.spaceGrotesk(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.spaceGrotesk(
          color: textOnDark.withOpacity(0.55),
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: primaryColor.withOpacity(0.18),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primaryColor);
          }
          return IconThemeData(color: textOnDark.withOpacity(0.55));
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GoogleFonts.spaceGrotesk(
              color: primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          }
          return GoogleFonts.spaceGrotesk(
            color: textOnDark.withOpacity(0.55),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      dividerColor: Colors.white.withOpacity(0.1),
    );
  }

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF12B3A8), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFB7185), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Box decoration for glassmorphism
  static BoxDecoration glassDecoration({double opacity = 0.08}) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(opacity + 0.04),
          Colors.white.withOpacity(opacity * 0.5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.white.withOpacity(opacity + 0.05),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 26,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }
}
