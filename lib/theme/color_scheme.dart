import 'package:flutter/material.dart';

const Color primaryColor = Color.fromARGB(255, 125, 239, 129);
const Color secondaryColor = Color(0xFF03DAC6);
const Color backgroundColor = Color.fromARGB(255, 0, 0, 0);
const Color surfaceColor = Color(0xFFFFFFFF);
const Color errorColor = Color.fromARGB(255, 252, 249, 249);
const Color onPrimaryColor = Color.fromARGB(255, 179, 232, 242);
const Color onSecondaryColor = Color.fromARGB(255, 242, 244, 195);
const Color onBackgroundColor = Color(0xFF000000);
const Color onSurfaceColor = Color(0xFF000000);
const Color onErrorColor = Color.fromARGB(255, 223, 89, 89);

const ColorScheme appColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: primaryColor,
  onPrimary: onPrimaryColor,
  secondary: secondaryColor,
  onSecondary: onSecondaryColor,
  surface: surfaceColor,
  onSurface: onSurfaceColor,
  error: errorColor,
  onError: onErrorColor,
);
