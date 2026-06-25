import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

class DrawnLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  DrawnLine({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });
}

class WhiteboardScreen extends StatefulWidget {
  const WhiteboardScreen({super.key});

  /// Opens the whiteboard as a full-screen dialog. Returns the drawn [File] or null.
  static Future<File?> show(BuildContext context) {
    return showGeneralDialog<File?>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Whiteboard',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, secAnim, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        );
      },
      pageBuilder: (ctx, anim, secAnim) => const WhiteboardScreen(),
    );
  }

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  final List<DrawnLine> _lines = [];
  DrawnLine? _currentLine;

  Color _selectedColor = Colors.black;
  double _selectedWidth = 5.0;
  bool _isDarkCanvas = false;
  bool _isEraserMode = false;

  final List<Color> _lightColors = [
    Colors.black,
    Colors.blue[700]!,
    Colors.red[600]!,
    Colors.green[600]!,
    Colors.orange[600]!,
    Colors.purple[600]!,
  ];

  final List<Color> _darkColors = [
    Colors.white,
    Colors.blue[300]!,
    Colors.red[300]!,
    Colors.green[300]!,
    Colors.orange[300]!,
    Colors.purple[300]!,
  ];

  @override
  void initState() {
    super.initState();
    // Default canvas color matches theme brightness
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isDarkCanvas = Theme.of(context).brightness == Brightness.dark;
        _selectedColor = _isDarkCanvas ? Colors.white : Colors.black;
      });
    });
  }

  void _undo() {
    if (_lines.isNotEmpty) {
      setState(() {
        _lines.removeLast();
      });
    }
  }

  void _clear() {
    setState(() {
      _lines.clear();
      _currentLine = null;
    });
  }

  Future<void> _saveCanvas() async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw something first! 🎨')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final boundaryWidth = MediaQuery.of(context).size.width;
      // Subtract appbar and toolbar heights approx
      final boundaryHeight = MediaQuery.of(context).size.height - 240;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, boundaryWidth, boundaryHeight),
      );

      // Draw background color
      final bgPaint = Paint()
        ..color = _isDarkCanvas ? const Color(0xFF1E1A24) : Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, boundaryWidth, boundaryHeight),
        bgPaint,
      );

      // Draw grid pattern (subtle engineering paper grid)
      final gridPaint = Paint()
        ..color = _isDarkCanvas
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.04)
        ..strokeWidth = 1.0;

      const gridSize = 25.0;
      for (double i = 0; i < boundaryWidth; i += gridSize) {
        canvas.drawLine(Offset(i, 0), Offset(i, boundaryHeight), gridPaint);
      }
      for (double i = 0; i < boundaryHeight; i += gridSize) {
        canvas.drawLine(Offset(0, i), Offset(boundaryWidth, i), gridPaint);
      }

      // Draw lines on a layer to allow BlendMode.clear for eraser
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, boundaryWidth, boundaryHeight),
        Paint(),
      );

      for (final line in _lines) {
        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = line.strokeWidth
          ..style = PaintingStyle.stroke;

        if (line.isEraser) {
          paint.blendMode = BlendMode.clear;
        } else {
          paint.color = line.color;
        }

        for (int i = 0; i < line.points.length - 1; i++) {
          canvas.drawLine(line.points[i], line.points[i + 1], paint);
        }
      }

      canvas.restore();

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        boundaryWidth.toInt(),
        boundaryHeight.toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to generate PNG bytes');

      final buffer = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/whiteboard_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(buffer);

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        Navigator.pop(context, file); // Return drawn image file
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save drawing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _isDarkCanvas ? _darkColors : _lightColors;
    final boardBg = _isDarkCanvas ? const Color(0xFF1E1A24) : Colors.white;

    return Scaffold(
      backgroundColor: _isDarkCanvas ? const Color(0xFF120E18) : Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Slim top header (avoids AppBar + dialog overlay issue)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: _isDarkCanvas ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Whiteboard',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _isDarkCanvas ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isDarkCanvas ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      color: _isDarkCanvas ? Colors.white : Colors.black87,
                    ),
                    tooltip: 'Toggle board color',
                    onPressed: () {
                      setState(() {
                        _isDarkCanvas = !_isDarkCanvas;
                        if (!_isEraserMode) {
                          _selectedColor = _isDarkCanvas ? Colors.white : Colors.black;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            // Drawing Canvas Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                decoration: BoxDecoration(
                  color: boardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isDarkCanvas ? const Color(0xFF382A45) : Colors.grey[350]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _currentLine = DrawnLine(
                          points: [details.localPosition],
                          color: _selectedColor,
                          strokeWidth: _selectedWidth,
                          isEraser: _isEraserMode,
                        );
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        if (_currentLine != null) {
                          _currentLine!.points.add(details.localPosition);
                        }
                      });
                    },
                    onPanEnd: (details) {
                      setState(() {
                        if (_currentLine != null) {
                          _lines.add(_currentLine!);
                          _currentLine = null;
                        }
                      });
                    },
                    child: CustomPaint(
                      painter: WhiteboardPainter(
                        lines: _lines,
                        currentLine: _currentLine,
                        isDark: _isDarkCanvas,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),

            // Tools toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tool toggle row + action buttons
                  Row(
                    children: [
                      // Draw / Erase toggle
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              // Brush Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isEraserMode = false;
                                      _selectedColor = _isDarkCanvas ? Colors.white : Colors.black;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: !_isEraserMode
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.brush_rounded,
                                          size: 18,
                                          color: !_isEraserMode
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Draw',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: !_isEraserMode
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Eraser Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isEraserMode = true;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _isEraserMode
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.auto_fix_normal_rounded,
                                          size: 18,
                                          color: _isEraserMode
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Erase',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _isEraserMode
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Undo
                      IconButton(
                        icon: const Icon(Icons.undo_rounded),
                        tooltip: 'Undo',
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        ),
                        onPressed: _undo,
                      ),
                      const SizedBox(width: 8),
                      // Erase All
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded),
                        tooltip: 'Erase All',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red[700],
                        ),
                        onPressed: _clear,
                      ),
                      const SizedBox(width: 8),
                      // Save & attach
                      IntrinsicWidth(
                        child: ElevatedButton(
                          onPressed: _saveCanvas,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(
                            'Save',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Color selection row (Only show in Draw mode)
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: !_isEraserMode
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    secondChild: const SizedBox.shrink(),
                    firstChild: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Brush Color',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: colors.map((color) {
                                final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedColor = color;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 5),
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: color.withOpacity(0.4),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),

                  // Stroke width selection row
                  Row(
                    children: [
                      Text(
                        _isEraserMode ? 'Eraser Size' : 'Brush Size',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Slider.adaptive(
                          value: _selectedWidth,
                          min: 1.0,
                          max: 30.0,
                          activeColor: theme.colorScheme.primary,
                          onChanged: (val) {
                            setState(() {
                              _selectedWidth = val;
                            });
                          },
                        ),
                      ),
                      Text(
                        '${_selectedWidth.toInt()}px',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WhiteboardPainter extends CustomPainter {
  final List<DrawnLine> lines;
  final DrawnLine? currentLine;
  final bool isDark;

  WhiteboardPainter({
    required this.lines,
    required this.currentLine,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle grid background
    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.04)
          : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1.0;

    const gridSize = 25.0;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 2. Draw lines on a layer to allow BlendMode.clear to erase cleanly
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (final line in lines) {
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = line.strokeWidth
        ..style = PaintingStyle.stroke;

      if (line.isEraser) {
        paint.blendMode = BlendMode.clear;
      } else {
        paint.color = line.color;
      }

      for (int i = 0; i < line.points.length - 1; i++) {
        canvas.drawLine(line.points[i], line.points[i + 1], paint);
      }
    }

    if (currentLine != null && currentLine!.points.isNotEmpty) {
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = currentLine!.strokeWidth
        ..style = PaintingStyle.stroke;

      if (currentLine!.isEraser) {
        paint.blendMode = BlendMode.clear;
      } else {
        paint.color = currentLine!.color;
      }

      for (int i = 0; i < currentLine!.points.length - 1; i++) {
        canvas.drawLine(currentLine!.points[i], currentLine!.points[i + 1], paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
