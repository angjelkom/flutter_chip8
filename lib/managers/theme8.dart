import 'package:flutter/material.dart';
import 'package:flutter_chip8/models/theme8.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeManager extends StateNotifier<Theme8> {
  final List<Theme8> _themes = [
    Theme8(Colors.blueGrey, Colors.white70, 'Blue-White'),
    Theme8(Colors.white, Colors.black, 'White-Black'),
    Theme8(Colors.black, Colors.green, 'Black-Green'),
    Theme8(Colors.yellow, Colors.red, 'Yellow-Red')
  ];

  List<Theme8> get themes => _themes;

  ThemeManager() : super(Theme8(Colors.blueGrey, Colors.white70, 'Blue-White'));

  set inverted(invert) {
    state = state.copyWith(inverted: invert);
  }

  set select(Theme8 theme) {
    state = theme.copyWith();
  }
}

final themeProvider = StateNotifierProvider<ThemeManager, Theme8>((ref) {
  return ThemeManager();
});
