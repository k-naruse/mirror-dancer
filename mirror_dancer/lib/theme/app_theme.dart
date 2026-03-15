import 'package:flutter/cupertino.dart';

class AppColors {
  static const bg = Color(0xFF0F0F0F);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceHover = Color(0xFF242424);
  static const border = Color(0xFF2A2A2A);
  static const text = Color(0xFFE8E8E8);
  static const textSub = Color(0xFF777777);
  static const textDim = Color(0xFF555555);
  static const accent = Color(0xFF4ECDC4);
  static const accentDim = Color(0x184ECDC4);
  static const red = Color(0xFFFF6B6B);
  static const orange = Color(0xFFF0A050);
  static const refBg = Color(0xFF0C1929);
  static const myBg = Color(0xFF0C2919);
  static const refAccent = Color(0xFF5B9BD5);
  static const myAccent = Color(0xFF6BCF7F);
  static const tabBg = Color(0xFF141414);
  static const tabBorder = Color(0xFF222222);
}

CupertinoThemeData cupertinoTheme() {
  return const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.accent,
    scaffoldBackgroundColor: AppColors.bg,
    barBackgroundColor: AppColors.surface,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(
        color: AppColors.text,
        fontSize: 16,
        decoration: TextDecoration.none,
      ),
      navTitleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
      ),
      navLargeTitleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 34,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      actionTextStyle: TextStyle(
        color: AppColors.accent,
        fontSize: 17,
        decoration: TextDecoration.none,
      ),
    ),
  );
}
