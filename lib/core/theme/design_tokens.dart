import 'package:flutter/material.dart';

/// Tokens from design.md — Supportive Health Harmony
abstract final class AppColors {
  static const background = Color(0xFFF9F9F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF3F3F3);
  static const surfaceContainer = Color(0xFFEEEEEE);

  static const onSurface = Color(0xFF1A1C1C);
  static const onSurfaceVariant = Color(0xFF3D4947);
  static const outline = Color(0xFF6D7A77);
  static const outlineVariant = Color(0xFFBCC9C6);

  static const primary = Color(0xFF00685D);
  static const primaryContainer = Color(0xFF008376);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryFixedDim = Color(0xFF6FD8C8);

  static const secondary = Color(0xFFA33D23);
  static const secondaryBright = Color(0xFFE76F51);
  static const secondaryContainer = Color(0xFFFF8162);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryFixed = Color(0xFFFFDAD2);

  static const tertiary = Color(0xFF595A71);
  static const tertiaryFixed = Color(0xFFE0E0FC);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const warning = Color(0xFFE63946);
}

abstract final class AppSpacing {
  static const unit = 8.0;
  static const gutter = 16.0;
  static const stackGap = 16.0;
  static const containerPadding = 24.0;
  static const sectionGap = 32.0;
  static const touchTargetMin = 48.0;
  static const buttonHeight = 56.0;
}

abstract final class AppRadius {
  static const sm = 4.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 9999.0;
}

abstract final class AppElevation {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF2B2D42).withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
          color: const Color(0xFF2B2D42).withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
