import 'package:flutter/material.dart';

class AppColors {
  // Colores Primarios
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF64B5F6);

  // Colores Secundarios
  static const Color accent = Color(0xFF00BCD4);
  static const Color accentLight = Color(0xFF4DD0E1);

  // Colores Neutros
  static const Color darkBg = Color(0xFF0F1419);
  static const Color darkBgSecondary = Color(0xFF1A1F29);
  static const Color lightText = Color(0xFFE0E0E0);
  static const Color mediumText = Color(0xFFB0B0B0);
  static const Color darkText = Color(0xFF757575);

  // Colores de Estados
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Colores para Datos Climáticos
  static const Color tempHot = Color(0xFFFF5722);
  static const Color tempCold = Color(0xFF00BCD4);
  static const Color tempNormal = Color(0xFF4CAF50);

  static const Color humidityHigh = Color(0xFF2196F3);
  static const Color humidityNormal = Color(0xFF66BB6A);
  static const Color humidityLow = Color(0xFFFF9800);

  static const Color pressureHigh = Color(0xFF5C6BC0);
  static const Color pressureNormal = Color(0xFF4CAF50);
  static const Color pressureLow = Color(0xFFEF5350);

  static const Color windStrong = Color(0xFFE91E63);
  static const Color windModerate = Color(0xFF00BCD4);
  static const Color windWeak = Color(0xFF4CAF50);

  // Gradientes
  static LinearGradient temperatureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
  );

  static LinearGradient humidityGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
  );

  static LinearGradient windGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
  );

  static LinearGradient pressureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
  );

  static LinearGradient uvGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
  );

  static LinearGradient aqiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
  );
}
