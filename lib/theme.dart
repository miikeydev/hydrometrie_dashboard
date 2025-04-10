import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[200],
    cardColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[200],
      iconTheme: const IconThemeData(color: Colors.black),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Colors.black),
      titleMedium: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.black54),
    ),
    shadowColor: Colors.black.withOpacity(0.1),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212), 
    cardColor: const Color(0xFF1E1E1E), 
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white70),
      bodySmall: TextStyle(color: Colors.white54),
    ),
    shadowColor: Colors.black.withOpacity(0.2),
  );

  // Couleurs communes aux deux thèmes qui ne changent pas
  static const Color debitMainColor = Color(0xFF1976D2); // Bleu plus foncé pour débit
  static const Color debitLightColor = Color(0xFF2196F3); // Bleu moyen pour débit

  static const Color hauteurMainColor = Color(0xFF64B5F6); // Bleu plus clair pour hauteur
  static const Color hauteurLightColor = Color(0xFFBBDEFB); // Bleu très clair pour hauteur
  
  // Méthode utilitaire pour obtenir des couleurs adaptées au thème actuel
  static Color getContainerBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E) // Container légèrement plus clair que le fond en mode sombre
        : Colors.white;
  }
  
  static Color getSecondaryContainerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C) // Un peu plus clair pour les éléments secondaires
        : Colors.grey[50]!;
  }
  
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
  
  static Color getIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
