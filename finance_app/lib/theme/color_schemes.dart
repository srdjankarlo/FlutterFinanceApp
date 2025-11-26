import 'package:flutter/material.dart';

const coldColorScheme = ColorScheme.light(
  primary: Color(0xFF1E8F8A),
  secondary: Color(0xFF2AA6A1),
  surface: Color(0xFFEEF6F8),
  onPrimary: Colors.white,
  onSurface: Colors.black,
);

const warmColorScheme = ColorScheme.light(
  primary: Color(0xFFE87452),
  secondary: Color(0xFFE88B6C),
  surface: Color(0xFFF8EEE8),
  onPrimary: Colors.white,
  onSurface: Colors.black,
);

const maxContrastScheme = ColorScheme.light(
    primary: Colors.black,
    secondary: Colors.grey,
    onPrimary: Colors.white,
    onSurface: Colors.black
);

const appColorSchemes = {
  'Cold': coldColorScheme,
  'Warm': warmColorScheme,
  'Max Contrast': maxContrastScheme,
};