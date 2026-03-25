import 'package:flutter/material.dart';

/// Palette de couleurs pour les thèmes clair et sombre
abstract class AppColors {
  // ===== LIGHT THEME =====
  static const lightPrimaryColor = Color(0xFF2B56F5);
  static const lightErrorColor = Color(0xFFE53935);
  static const lightWarningColor = Color(0xFFFFA500);
  static const lightSuccessColor = Color(0xFF34A853);
  static const lightInfoColor = Color(0xFF2196F3);

  static const lightScaffoldBackground = Color(0xFFF5F7FA);
  static const lightCardBackground = Colors.white;
  static const lightSurfaceColor = Color(0xFFF1F3F5);

  static const lightTextPrimary = Color(0xFF1F2937);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightTextHint = Color(0xFF9CA3AF);
  static const lightDividerColor = Color(0xFFE5E7EB);
  static const lightBorderColor = Color(0xFFE5E7EB);

  // Gradient colors Light
  static const lightGradientStart = Color(0xFF2B56F5);
  static const lightGradientEnd = Color(0xFF1E40AF);

  // Role colors - Light
  static const lightStudentBg = Color(0xFFE8F0FE);
  static const lightStudentFg = Color(0xFF2B56F5);

  static const lightTeacherBg = Color(0xFFF4ECFF);
  static const lightTeacherFg = Color(0xFF8C45F7);

  static const lightParentBg = Color(0xFFE9F7EE);
  static const lightParentFg = Color(0xFF34A853);

  static const lightAdminBg = Color(0xFFFFF3E0);
  static const lightAdminFg = Color(0xFFFB8C00);

  // ===== DARK THEME =====
  static const darkPrimaryColor = Color(0xFF5B7FFF);
  static const darkErrorColor = Color(0xFFEF5350);
  static const darkWarningColor = Color(0xFFFFB74D);
  static const darkSuccessColor = Color(0xFF66BB6A);
  static const darkInfoColor = Color(0xFF64B5F6);

  static const darkScaffoldBackground = Color(0xFF0D1117);
  static const darkCardBackground = Color(0xFF161B22);
  static const darkSurfaceColor = Color(0xFF21262D);

  static const darkTextPrimary = Color(0xFFF3F4F6);
  static const darkTextSecondary = Color(0xFFD1D5DB);
  static const darkTextHint = Color(0xFF9CA3AF);
  static const darkDividerColor = Color(0xFF374151);
  static const darkBorderColor = Color(0xFF4B5563);

  // Gradient colors Dark
  static const darkGradientStart = Color(0xFF5B7FFF);
  static const darkGradientEnd = Color(0xFF1E40AF);

  // Role colors - Dark
  static const darkStudentBg = Color(0xFF1E3A8A);
  static const darkStudentFg = Color(0xFF93C5FD);

  static const darkTeacherBg = Color(0xFF4C1D95);
  static const darkTeacherFg = Color(0xFFD8B4FE);

  static const darkParentBg = Color(0xFF064E3B);
  static const darkParentFg = Color(0xFFA7F3D0);

  static const darkAdminBg = Color(0xFF7C2D12);
  static const darkAdminFg = Color(0xFFFED7AA);
}
