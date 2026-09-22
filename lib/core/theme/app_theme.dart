import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  AppColors._();

  static const Color seed = Color(0xFF1E88E5);
  static const Color submit = Color(0xFFD32F2F);
  static const Color onSubmit = Colors.white;
  static const Color courseDefault = Color(0xFF6366F1);
  static const Color late = Color(0xFFF59E0B);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        fontFamily: 'PlusJakartaSans',
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seed),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.seed,
          foregroundColor: Colors.white,
          scrolledUnderElevation: 3,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: AppColors.seed,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.seed,
          foregroundColor: Colors.white,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.seed,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: AppColors.seed,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white, size: 22);
            }
            return null;
          }),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.seed;
              }
              return null;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return null;
            }),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.seed, width: 2),
          ),
          floatingLabelStyle: TextStyle(color: AppColors.seed),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.submit,
            foregroundColor: AppColors.onSubmit,
          ),
        ),
      );
}
