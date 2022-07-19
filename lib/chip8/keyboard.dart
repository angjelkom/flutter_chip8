import 'package:flutter/services.dart';

class Keyboard {
  final Map<String, int> keyMap = {
    '1': 0x1, // 1
    '2': 0x2, // 2
    '3': 0x3, // 3
    '4': 0xc, // 4
    'q': 0x4, // Q
    'w': 0x5, // W
    'e': 0x6, // E
    'r': 0xD, // R
    'a': 0x7, // A
    's': 0x8, // S
    'd': 0x9, // D
    'f': 0xE, // F
    'z': 0xA, // Z
    'x': 0x0, // X
    'c': 0xB, // C
    'v': 0xF // V
  };

  final Map<int, bool> keysPressed = {};

  Function(int key)? onNextKeyPress;

  isKeyPressed(int keyCode) {
    return keysPressed[keyCode] != null && keysPressed[keyCode]!;
  }

  onKey(RawKeyEvent event) {
    onLetter(event.data.keyLabel, event is RawKeyDownEvent);
  }

  onLetter(String letter, bool isDown) {
    int? key = keyMap[letter];

    if (key != null) {
      if (isDown) {
        keysPressed[key] = true;

        // Make sure onNextKeyPress is initialized and the pressed key is actually mapped to a Chip-8 key
        if (onNextKeyPress != null) {
          onNextKeyPress!(key);
          onNextKeyPress = null;
        }
      } else {
        keysPressed[key] = false;
      }
    }
  }
}
