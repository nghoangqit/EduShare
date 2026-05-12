import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGray = Color(0xFF64748B);
  static const Color red = Color(0xFFEF4444);
  static const Color blue = Color(0xFF3B82F6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color purple = Color(0xFF8B5CF6);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto',
  );
}

class AppStrings {
  static const String appName = 'EduShare';
  static const String tagline = 'Tim sach va dung cu hoc tap';
}

class AdminConfig {
  static const List<String> adminEmails = ['admin@edushare.vn'];

  static const String bankName = 'Viettinbank';
  static const String bankBin = '970415';
  static const String bankAccountNumber = '0388431406';
  static const String bankAccountHolder = 'Tran Ngoc Hoang';
  static const double walletTopupCreditRate = 0.90;
  static const double walletTopupFeeRate = 0.10;
  static const double sellerPayoutRate = 0.95;
  static const double platformFeeRate = 0.05;

  static bool isAdminEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return adminEmails.contains(normalized);
  }
}
