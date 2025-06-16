import 'package:flutter/material.dart';

ThemeData appTheme() {
  return ThemeData(
    primarySwatch: Colors.green,
    primaryColor: Colors.green,
    primaryColorLight: Colors.green[50],
    primaryColorDark: Colors.green[800],
    scaffoldBackgroundColor: Colors.white,
    dividerColor: Colors.tealAccent,
    canvasColor: Colors.white,
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: Colors.white60), // Style for hint text
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white60),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white60),
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      foregroundColor: Colors.white,
      backgroundColor: Colors.green,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[100],
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.green[900],
      labelStyle: TextStyle(color: Colors.green[900]),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: Colors.green[900]!),
      ),
    ),
  );
}
