import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light([ColorScheme? scheme]) {
    return ThemeData(
      colorScheme: scheme ?? ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    );
  }

  static ThemeData dark([ColorScheme? scheme]) {
    return ThemeData(
      colorScheme:
          scheme ??
          ColorScheme.fromSeed(
            seedColor: Colors.blueGrey,
            brightness: Brightness.dark,
          ),
      useMaterial3: true,
    );
  }
}
