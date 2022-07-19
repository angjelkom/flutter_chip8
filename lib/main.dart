import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chip8/managers/theme8.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'chip8/cpu.dart';
import 'models/theme8.dart';
import 'chip8/renderer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    await windowManager.ensureInitialized();
  }

  runApp(const ProviderScope(
    child: MaterialApp(
      title: 'Chip8 Emulator',
      home: Chip8Emulator(),
    ),
  ));
}

class Chip8Emulator extends ConsumerStatefulWidget {
  const Chip8Emulator({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _Chip8EmulatorState();
}

class _Chip8EmulatorState extends ConsumerState<Chip8Emulator>
    with SingleTickerProviderStateMixin, WindowListener {
  final FocusNode _focusNode = FocusNode();
  late final Ticker _ticker;
  @override
  void initState() {
    //cycle the cpu every frame.
    _ticker = createTicker((elapsed) {
      ref.read(cpuProvider).cycle();
    });
    _ticker.start();

    windowManager.addListener(this);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var cpu = ref.watch(cpuProvider);
    var theme = ref.watch(themeProvider);
    var scale =
        (MediaQuery.of(context).size.width / cpu.renderer.cols).floorToDouble();
    return RawKeyboardListener(
      autofocus: true,
      focusNode: _focusNode,
      onKey: (event) {
        ref.read(cpuProvider).keyboard.onKey(event);
      },
      child: Scaffold(
        backgroundColor: theme.primary,
        appBar: AppBar(
          title: const Text('Chip8 Emulator'),
          actions: [
            PopupMenuButton(
                onSelected: ((Theme8 value) =>
                    ref.read(themeProvider.notifier).select = value),
                itemBuilder: (_) => ref
                    .read(themeProvider.notifier)
                    .themes
                    .map(
                      (e) => PopupMenuItem(
                        value: e,
                        child: Text(e.name),
                      ),
                    )
                    .toList())
          ],
        ),
        body: cpu.romLoaded
            ? SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: CustomPaint(
                        painter:
                            Chip8Painter(renderer: cpu.renderer, theme: theme),
                        size: Size(scale * cpu.renderer.cols,
                            scale * cpu.renderer.rows),
                      ),
                    ),
                    Flexible(
                      // height: 100.0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                            shrinkWrap: true,
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 150,
                                    childAspectRatio: 3 / 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10),
                            itemCount: cpu.keyboard.keyMap.length,
                            itemBuilder: (BuildContext ctx, index) {
                              var key =
                                  cpu.keyboard.keyMap.keys.elementAt(index);
                              return GestureDetector(
                                onTapDown: (details) => ref
                                    .read(cpuProvider)
                                    .keyboard
                                    .onLetter(key, true),
                                onTapUp: (details) => ref
                                    .read(cpuProvider)
                                    .keyboard
                                    .onLetter(key, false),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: theme.primary,
                                      border: Border.all(
                                          color: theme.accent, width: 2.0),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Text(
                                    key.toUpperCase(),
                                    style: TextStyle(
                                        color: theme.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 32.0),
                                  ),
                                ),
                              );
                            }),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Text(
                  'LOAD YOUR ROM',
                  style: TextStyle(
                      color: theme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 32.0),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async {
            FilePickerResult? result =
                await FilePicker.platform.pickFiles(withData: true);

            if (result != null) {
              cpu.loadRom(result.files.single.bytes);
            } else {
              // User canceled the picker
            }
          },
        ),
      ),
    );
  }

  @override
  void onWindowFocus() {
    ref.read(cpuProvider.notifier).pause(false);
    super.onWindowFocus();
  }

  @override
  void onWindowBlur() {
    ref.read(cpuProvider.notifier).pause(true);
    super.onWindowBlur();
  }

  @override
  void dispose() {
    _ticker.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }
}

class Chip8Painter extends CustomPainter {
  Chip8Painter({required this.renderer, required this.theme});

  final Renderer renderer;
  final Theme8 theme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(theme.primary, BlendMode.color);

    var paint = Paint()
      ..style = PaintingStyle.fill
      ..color = theme.accent;
    var scale = (size.width / renderer.cols).floorToDouble();
    var shift = ((size.width - (renderer.cols * scale)) / 2).floorToDouble();

    // Loop through our display array
    for (int i = 0; i < renderer.display.length; i++) {
      // Grabs the x position of the pixel based off of `i`
      double x = ((i % renderer.cols) * scale) + shift;

      // Grabs the y position of the pixel based off of `i`
      double y = ((i / renderer.cols).floor() * scale) + shift;

      // If the value at this.display[i] == 1, then draw a pixel.
      if (renderer.display[i] == 1) {
        // Set the pixel color to black

        // Place a pixel at position (x, y) with a width and height of scale
        canvas.drawRect(
            Rect.fromLTWH(
              x,
              y,
              scale,
              scale,
            ),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
