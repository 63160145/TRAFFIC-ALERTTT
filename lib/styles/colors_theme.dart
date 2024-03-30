import 'package:flutter/material.dart';

class ColorGradient {
  static LinearGradient getGradient() {
    return const LinearGradient(
      colors: [Color(0xFF52B8CF), Color(0xFFABE9CD)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }
}
