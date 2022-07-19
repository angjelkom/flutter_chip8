import 'dart:collection';

class Renderer {
  final int cols = 64;
  final int rows = 32;
  late SplayTreeMap<int, int> display = SplayTreeMap.from(
    List.filled(cols * rows, 0).asMap(),
  );

  bool setPixel(x, y) {
    if (x > cols) {
      x -= cols;
    } else if (x < 0) {
      x += cols;
    }

    if (y > rows) {
      y -= rows;
    } else if (y < 0) {
      y += rows;
    }

    int pixelLoc = x + (y * cols);
    display[pixelLoc] = (display[pixelLoc] ?? 0) ^ 1;

    return display[pixelLoc] != 1;
  }

  clear() {
    display = SplayTreeMap.from(
      List.filled(cols * rows, 0).asMap(),
    );
  }
}
