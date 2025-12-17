import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/rent_tracker/providers/house_provider.dart';

import 'features/home/screens/main_layout.dart';

void main() {
  runApp(const HouseRentApp());
}

class HouseRentApp extends StatelessWidget {
  const HouseRentApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Smart Home Palette
    // Primary: Dark Navy Blue (#0A1E3C) - for headers, primary buttons
    // Secondary: Soft Blue/Cyan (#3A86FF) - for accents, active states
    // Background: Light Gray (#F5F7FA) - for scaffold
    // Surface: White (#FFFFFF) - for cards
    // Text: Dark Blue Grey (#2C3E50)

    const primaryColor = Color(0xFF0A1E3C);
    const accentColor = Color(0xFF3A86FF);
    const backgroundColor = Color(0xFFF5F7FA);
    const surfaceColor = Colors.white;
    const textColor = Color(0xFF2C3E50);

    final baseTheme = ThemeData(
      useMaterial3: true,
      fontFamily:
          'Roboto', // Defaulting to Roboto, can be changed if custom font added
      brightness: Brightness.light,
    );

    return ChangeNotifierProvider(
      create: (_) => HouseProvider(),
      child: MaterialApp(
        title: 'Rent Tracker',
        debugShowCheckedModeBanner: false,
        theme: baseTheme.copyWith(
          scaffoldBackgroundColor: backgroundColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryColor,
            primary: primaryColor,
            secondary: accentColor,
            surface: surfaceColor,
            background: backgroundColor,
            onBackground: textColor,
            onSurface: textColor,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: backgroundColor,
            foregroundColor: primaryColor,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              color: primaryColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: primaryColor),
          ),
          cardTheme: CardThemeData(
            color: surfaceColor,
            elevation: 2,
            shadowColor: const Color(0x1A000000), // Soft shadow
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: surfaceColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: accentColor, width: 2),
            ),
            hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
          ),
          textTheme: baseTheme.textTheme
              .apply(
                bodyColor: textColor,
                displayColor: textColor,
              )
              .copyWith(
                titleLarge: const TextStyle(
                    color: primaryColor, fontWeight: FontWeight.bold),
                titleMedium: const TextStyle(
                    color: textColor, fontWeight: FontWeight.w600),
              ),
          iconTheme: const IconThemeData(color: primaryColor),
        ),
        home: const MainLayout(),
      ),
    );
  }
}
