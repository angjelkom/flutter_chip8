import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'keyboard.dart';
import 'renderer.dart';

class CPU with ChangeNotifier {
  final Renderer renderer = Renderer();
  final Keyboard keyboard = Keyboard();
  Uint8List memory = Uint8List(4096);

  Uint8List v = Uint8List(16);

  int i = 0;

  int delayTimer = 0;

  int pc = 0x200;

  final List stack = [];

  bool paused = true;
  bool romLoaded = false;

  final int speed = 10;

  // Array of hex values for each sprite. Each sprite is 5 bytes.
  // The technical reference provides us with each one of these values.
  final sprites = [
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80 // F
  ];

  loadSpritesIntoMemory() {
    // According to the technical reference, sprites are stored in the interpreter section of memory starting at hex 0x000
    for (int i = 0; i < sprites.length; i++) {
      memory[i] = sprites[i];
    }
  }

  loadProgramIntoMemory(program) {
    for (int loc = 0; loc < program.length; loc++) {
      memory[0x200 + loc] = program[loc];
    }
    romLoaded = true;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      paused = false;
    }
  }

  loadRom(program) {
    romLoaded = false;
    memory = Uint8List(4096);
    v = Uint8List(16);
    delayTimer = 0;
    i = 0;
    pc = 0x200;
    stack.clear();
    renderer.clear();
    loadSpritesIntoMemory();
    loadProgramIntoMemory(program);
  }

  cycle() {
    for (int i = 0; i < speed; i++) {
      if (!paused && romLoaded) {
        int opcode = (memory[pc] << 8 | memory[pc + 1]);
        executeInstruction(opcode);
      }
    }

    if (!paused && romLoaded) {
      updateTimers();
    }

    notifyListeners();
  }

  executeInstruction(int opcode) {
    pc += 2;

    int x = (opcode & 0x0F00) >> 8;

    int y = (opcode & 0x00F0) >> 4;

    switch (opcode & 0xF000) {
      case 0x0000:
        switch (opcode) {
          case 0x00E0:
            renderer.clear();
            break;
          case 0x00EE:
            pc = stack.removeLast();
            break;
        }

        break;
      case 0x1000:
        pc = (opcode & 0xFFF);
        break;
      case 0x2000:
        stack.add(pc);
        pc = (opcode & 0xFFF);
        break;
      case 0x3000:
        if (v[x] == (opcode & 0xFF)) {
          pc += 2;
        }
        break;
      case 0x4000:
        if (v[x] != (opcode & 0xFF)) {
          pc += 2;
        }
        break;
      case 0x5000:
        if (v[x] == v[y]) {
          pc += 2;
        }
        break;
      case 0x6000:
        v[x] = (opcode & 0xFF);
        break;
      case 0x7000:
        v[x] += (opcode & 0xFF);
        break;
      case 0x8000:
        switch (opcode & 0xF) {
          case 0x0:
            v[x] = v[y];
            break;
          case 0x1:
            v[x] |= v[y];
            break;
          case 0x2:
            v[x] &= v[y];
            break;
          case 0x3:
            v[x] ^= v[y];
            break;
          case 0x4:
            int sum = (v[x] += v[y]);

            v[0xF] = 0;

            if (sum > 0xFF) {
              v[0xF] = 1;
            }

            v[x] = sum;
            break;
          case 0x5:
            v[0xF] = 0;
            if (v[x] > v[y]) {
              v[0xF] = 1;
            }

            v[x] -= v[y];
            break;
          case 0x6:
            v[0xF] = (v[x] & 0x1);
            v[x] >>= 1;
            break;
          case 0x7:
            v[0xF] = 0;

            if (v[y] > v[x]) {
              v[0xF] = 1;
            }

            v[x] = v[y] - v[x];
            break;
          case 0xE:
            v[0xF] = (v[x] & 0x80);
            v[x] <<= 1;
            break;
        }

        break;
      case 0x9000:
        if (v[x] != v[y]) {
          pc += 2;
        }
        break;
      case 0xA000:
        i = (opcode & 0xFFF);
        break;
      case 0xB000:
        pc = (opcode & 0xFFF) + v[0];
        break;
      case 0xC000:
        int rand = Random().nextInt(0xFF);
        v[x] = rand & (opcode & 0xFF);
        break;
      case 0xD000:
        int width = 8;
        int height = (opcode & 0xF);

        v[0xF] = 0;

        for (int row = 0; row < height; row++) {
          int sprite = memory[i + row];

          for (int col = 0; col < width; col++) {
            // If the bit (sprite) is not 0, render/erase the pixel
            if ((sprite & 0x80) > 0) {
              // If setPixel returns 1, which means a pixel was erased, set VF to 1
              if (renderer.setPixel(v[x] + col, v[y] + row)) {
                v[0xF] = 1;
              }
            }

            // Shift the sprite left 1. This will move the next next col/bit of the sprite into the first position.
            // Ex. 10010000 << 1 will become 0010000
            sprite <<= 1;
          }
        }
        break;
      case 0xE000:
        switch (opcode & 0xFF) {
          case 0x9E:
            if (keyboard.isKeyPressed(v[x])) {
              pc += 2;
            }
            break;
          case 0xA1:
            if (!keyboard.isKeyPressed(v[x])) {
              pc += 2;
            }
            break;
        }

        break;
      case 0xF000:
        switch (opcode & 0xFF) {
          case 0x07:
            v[x] = delayTimer;
            break;
          case 0x0A:
            paused = true;
            keyboard.onNextKeyPress = (key) {
              v[x] = key;
              paused = false;
            };
            break;
          case 0x15:
            delayTimer = v[x];
            break;
          case 0x18:
            //sound
            break;
          case 0x1E:
            i += v[x];
            break;
          case 0x29:
            i = v[x] * 5;
            break;
          case 0x33:
            // Get the hundreds digit and place it in I.
            memory[i] = v[x] ~/ 100;

            // Get tens digit and place it in I+1. Gets a value between 0 and 99,
            // then divides by 10 to give us a value between 0 and 9.
            memory[i + 1] = (v[x] % 100) ~/ 10;

            // Get the value of the ones (last) digit and place it in I+2.
            memory[i + 2] = (v[x] % 10);
            break;
          case 0x55:
            for (int registerIndex = 0; registerIndex <= x; registerIndex++) {
              memory[i + registerIndex] = v[registerIndex];
            }
            break;
          case 0x65:
            for (int registerIndex = 0; registerIndex <= x; registerIndex++) {
              v[registerIndex] = memory[i + registerIndex];
            }
            break;
        }

        break;

      default:
        throw 'Unknown opcode $opcode';
    }
  }

  updateTimers() {
    if (delayTimer > 0) {
      delayTimer -= 1;
    }
  }

  pause(pause) {
    paused = pause;
    notifyListeners();
  }
}

final cpuProvider = ChangeNotifierProvider<CPU>((ref) {
  return CPU();
});
