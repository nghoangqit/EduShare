import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color primarySoft = Color(0xFFE6FFFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF4F7F8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGray = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color red = Color(0xFFEF4444);
  static const Color blue = Color(0xFF3B82F6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color purple = Color(0xFF8B5CF6);
}

class AppTheme {
  static const Duration fastMotion = Duration(milliseconds: 180);
  static const Duration normalMotion = Duration(milliseconds: 280);
  static const Curve motionCurve = Curves.easeOutCubic;

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      surface: AppColors.surface,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.bg,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w900,
          height: 1.12,
        ),
        titleLarge: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: TextStyle(color: AppColors.textDark, height: 1.4),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textDark,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class AppStrings {
  static const String appName = 'EduShare';
  static const String tagline = 'Tim sach va dung cu hoc tap';
}

class AdminConfig {
  static const List<String> adminEmails = ['admin@edushare.vn'];

  static const String bankName = 'MB Bank';
  static const String bankBin = '970422';
  static const String bankAccountNumber = '0388431406';
  static const String bankAccountHolder = 'Tran Ngoc Hoang';
  static const double walletTopupCreditRate = 0.90;
  static const double walletTopupFeeRate = 0.10;
  static const double sellerPayoutRate = 0.95;
  static const double platformFeeRate = 0.05;
  static const String payosClientId = String.fromEnvironment('PAYOS_CLIENT_ID');
  static const String payosApiKey = String.fromEnvironment('PAYOS_API_KEY');
  static const String payosChecksumKey = String.fromEnvironment(
    'PAYOS_CHECKSUM_KEY',
  );
  static const String payosPartnerCode = String.fromEnvironment(
    'PAYOS_PARTNER_CODE',
  );
  static const String payosReturnUrl = String.fromEnvironment(
    'PAYOS_RETURN_URL',
    defaultValue: 'https://edushare.vn/payos/return',
  );
  static const String payosCancelUrl = String.fromEnvironment(
    'PAYOS_CANCEL_URL',
    defaultValue: 'https://edushare.vn/payos/cancel',
  );

  static bool isAdminEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return adminEmails.contains(normalized);
  }
}
