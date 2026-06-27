import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

enum WhiteboardTool {
  draw,
  erase,
  panZoom,
}

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
  
  WhiteboardTool _activeTool = WhiteboardTool.draw;
  bool get _isEraserMode => _activeTool == WhiteboardTool.erase;

  late TransformationController _transformationController;

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
    _transformationController = TransformationController();
    // Default canvas color matches theme brightness
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      final viewWidth = size.width - 32;
      final viewHeight = size.height - 240;
      
      final initialTranslation = Offset(
        (viewWidth - 3000) / 2,
        (viewHeight - 3000) / 2,
      );
      
      _transformationController.value = Matrix4.identity()
        ..translate(initialTranslation.dx, initialTranslation.dy);

      setState(() {
        _isDarkCanvas = Theme.of(context).brightness == Brightness.dark;
        _selectedColor = _isDarkCanvas ? Colors.white : Colors.black;
      });
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
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
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      for (final line in _lines) {
        for (final pt in line.points) {
          if (pt.dx < minX) minX = pt.dx;
          if (pt.dy < minY) minY = pt.dy;
          if (pt.dx > maxX) maxX = pt.dx;
          if (pt.dy > maxY) maxY = pt.dy;
        }
      }

      if (minX == double.infinity) {
        minX = 1250;
        minY = 1250;
        maxX = 1750;
        maxY = 1750;
      } else {
        minX = (minX - 50).clamp(0.0, 3000.0);
        minY = (minY - 50).clamp(0.0, 3000.0);
        maxX = (maxX + 50).clamp(0.0, 3000.0);
        maxY = (maxY + 50).clamp(0.0, 3000.0);
      }

      final drawWidth = maxX - minX;
      final drawHeight = maxY - minY;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, drawWidth, drawHeight),
      );

      // Draw background color
      final bgPaint = Paint()
        ..color = _isDarkCanvas ? const Color(0xFF1E1A24) : Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, drawWidth, drawHeight),
        bgPaint,
      );

      // Draw grid pattern (subtle engineering paper grid)
      final gridPaint = Paint()
        ..color = _isDarkCanvas
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.04)
        ..strokeWidth = 1.0;

      const gridSize = 25.0;
      final startX = (minX / gridSize).floor() * gridSize;
      final startY = (minY / gridSize).floor() * gridSize;

      for (double i = startX; i <= maxX; i += gridSize) {
        canvas.drawLine(Offset(i - minX, 0), Offset(i - minX, drawHeight), gridPaint);
      }
      for (double i = startY; i <= maxY; i += gridSize) {
        canvas.drawLine(Offset(0, i - minY), Offset(drawWidth, i - minY), gridPaint);
      }

      // Draw lines on a layer to allow BlendMode.clear for eraser
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, drawWidth, drawHeight),
        Paint(),
      );

      canvas.translate(-minX, -minY);

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
      canvas.restore();

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        drawWidth.toInt(),
        drawHeight.toInt(),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          InteractiveViewer(
                            transformationController: _transformationController,
                            constrained: false,
                            scaleEnabled: _activeTool == WhiteboardTool.panZoom,
                            panEnabled: _activeTool == WhiteboardTool.panZoom,
                            minScale: 0.2,
                            maxScale: 4.0,
                            child: SizedBox(
                              width: 3000,
                              height: 3000,
                              child: GestureDetector(
                                onPanStart: _activeTool == WhiteboardTool.panZoom
                                    ? null
                                    : (details) {
                                        setState(() {
                                          _currentLine = DrawnLine(
                                            points: [details.localPosition],
                                            color: _selectedColor,
                                            strokeWidth: _selectedWidth,
                                            isEraser: _isEraserMode,
                                          );
                                        });
                                      },
                                onPanUpdate: _activeTool == WhiteboardTool.panZoom
                                    ? null
                                    : (details) {
                                        setState(() {
                                          if (_currentLine != null) {
                                            _currentLine!.points.add(details.localPosition);
                                          }
                                        });
                                      },
                                onPanEnd: _activeTool == WhiteboardTool.panZoom
                                    ? null
                                    : (details) {
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
                                  size: const Size(3000, 3000),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: FloatingActionButton.small(
                              heroTag: 'recenter_whiteboard',
                              backgroundColor: theme.colorScheme.primaryContainer,
                              foregroundColor: theme.colorScheme.onPrimaryContainer,
                              onPressed: () {
                                final initialTranslation = Offset(
                                  (constraints.maxWidth - 3000) / 2,
                                  (constraints.maxHeight - 3000) / 2,
                                );
                                _transformationController.value = Matrix4.identity()
                                  ..translate(initialTranslation.dx, initialTranslation.dy);
                              },
                              child: const Icon(Icons.center_focus_strong_rounded, size: 20),
                              tooltip: 'Recenter View',
                            ),
                          ),
                        ],
                      );
                    },
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
                      // Draw / Erase / Move toggle
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
                                      _activeTool = WhiteboardTool.draw;
                                      _selectedColor = _isDarkCanvas ? Colors.white : Colors.black;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _activeTool == WhiteboardTool.draw
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.brush_rounded,
                                            size: 16,
                                            color: _activeTool == WhiteboardTool.draw
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Draw',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _activeTool == WhiteboardTool.draw
                                                  ? theme.colorScheme.onPrimary
                                                  : theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              // Eraser Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _activeTool = WhiteboardTool.erase;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _activeTool == WhiteboardTool.erase
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.auto_fix_normal_rounded,
                                            size: 16,
                                            color: _activeTool == WhiteboardTool.erase
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Erase',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _activeTool == WhiteboardTool.erase
                                                  ? theme.colorScheme.onPrimary
                                                  : theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              // Move Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _activeTool = WhiteboardTool.panZoom;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _activeTool == WhiteboardTool.panZoom
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.back_hand_rounded,
                                            size: 16,
                                            color: _activeTool == WhiteboardTool.panZoom
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Move',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _activeTool == WhiteboardTool.panZoom
                                                  ? theme.colorScheme.onPrimary
                                                  : theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
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
                    crossFadeState: _activeTool == WhiteboardTool.draw
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
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _activeTool != WhiteboardTool.panZoom
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    secondChild: const SizedBox.shrink(),
                    firstChild: Row(
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
