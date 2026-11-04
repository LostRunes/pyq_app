// ─────────────────────────────────────────────────────────────────────────────
//  scientific_calculator_screen.dart
//  Casio fx-991ES PLUS 2nd Edition  —  Full-screen Flutter replica
//  Single self-contained file | Riverpod Notifier | math_expressions
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
// Aliased to avoid conflict with Flutter's Stack widget
import 'package:math_expressions/math_expressions.dart' as mx;

// ═══════════════════════════════════════════════════════════════════════════════
//  PALETTE
// ═══════════════════════════════════════════════════════════════════════════════
const _kScaffold = Color(0xFF16171C);
const _kKeypad = Color(0xFF0C0C10);
const _kLcdBg = Color(0xFFADC59E);
const _kLcdBdr = Color(0xFF647E58);
const _kNum = Color(0xFF282830);
const _kSci = Color(0xFF1C1C24);
const _kOp = Color(0xFF2C2C3A);
const _kGreen = Color(0xFF196320);
const _kShTxt = Color(0xFFFFBD00); // amber — SHIFT labels
const _kAlTxt = Color(0xFFDD4D74); // red-pink — ALPHA labels========

// ═══════════════════════════════════════════════════════════════════════════════
//  ENUM
// ═══════════════════════════════════════════════════════════════════════════════
enum AngleMode { deg, rad, grad }

// ═══════════════════════════════════════════════════════════════════════════════
//  CALCULATOR MODE  (matches real Casio fx-991ES PLUS MODE menu)
// ═══════════════════════════════════════════════════════════════════════════════
enum CalculatorMode {
  comp, // 1 — Standard computation
  cmplx, // 2 — Complex numbers
  stat, // 3 — Statistics & regression
  baseN, // 4 — Base-N (DEC/BIN/OCT/HEX)
  eqn, // 5 — Equation solver
  matrix, // 6 — Matrix calculations
  table, // 7 — Generate numeric table
  vector, // 8 — Vector calculations
}

extension CalculatorModeX on CalculatorMode {
  String get displayName => switch (this) {
    CalculatorMode.comp => 'COMP',
    CalculatorMode.cmplx => 'CMPLX',
    CalculatorMode.stat => 'STAT',
    CalculatorMode.baseN => 'BASE-N',
    CalculatorMode.eqn => 'EQN',
    CalculatorMode.matrix => 'MATRIX',
    CalculatorMode.table => 'TABLE',
    CalculatorMode.vector => 'VECTOR',
  };
  int get menuNumber => index + 1;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  IMMUTABLE STATE
// ═══════════════════════════════════════════════════════════════════════════════
class CalculatorState {
  final String expression;
  final String result;
  final bool isShiftActive;
  final bool isAlphaActive;
  final bool isHypActive;
  final AngleMode angleMode;
  final String lastAnswer;
  final List<String> history;
  final bool showCursor;
  final bool justEvaluated;
  // ── Mode system ──────────────────────────────────────────────────────────────
  final CalculatorMode calcMode;
  final bool showModeMenu; // true → LCD shows MODE selection overlay
  final String modeMessage; // transient message after mode switch

  const CalculatorState({
    this.expression = '',
    this.result = '0',
    this.isShiftActive = false,
    this.isAlphaActive = false,
    this.isHypActive = false,
    this.angleMode = AngleMode.deg,
    this.lastAnswer = '0',
    this.history = const [],
    this.showCursor = true,
    this.justEvaluated = false,
    this.calcMode = CalculatorMode.comp,
    this.showModeMenu = false,
    this.modeMessage = '',
  });

  CalculatorState copyWith({
    String? expression,
    String? result,
    bool? isShiftActive,
    bool? isAlphaActive,
    bool? isHypActive,
    AngleMode? angleMode,
    String? lastAnswer,
    List<String>? history,
    bool? showCursor,
    bool? justEvaluated,
    CalculatorMode? calcMode,
    bool? showModeMenu,
    String? modeMessage,
  }) => CalculatorState(
    expression: expression ?? this.expression,
    result: result ?? this.result,
    isShiftActive: isShiftActive ?? this.isShiftActive,
    isAlphaActive: isAlphaActive ?? this.isAlphaActive,
    isHypActive: isHypActive ?? this.isHypActive,
    angleMode: angleMode ?? this.angleMode,
    lastAnswer: lastAnswer ?? this.lastAnswer,
    history: history ?? this.history,
    showCursor: showCursor ?? this.showCursor,
    justEvaluated: justEvaluated ?? this.justEvaluated,
    calcMode: calcMode ?? this.calcMode,
    showModeMenu: showModeMenu ?? this.showModeMenu,
    modeMessage: modeMessage ?? this.modeMessage,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  NOTIFIER  — all business logic (Riverpod 3.x Notifier)
// ═══════════════════════════════════════════════════════════════════════════════
class CalculatorNotifier extends Notifier<CalculatorState> {
  Timer? _cursorTimer;

  @override
  CalculatorState build() {
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 520), (_) {
      state = state.copyWith(showCursor: !state.showCursor);
    });
    ref.onDispose(() => _cursorTimer?.cancel());
    return const CalculatorState();
  }

  // ── Public ──────────────────────────────────────────────────────────────────
  void cycleAngleMode() => state = state.copyWith(
    angleMode: AngleMode.values[(state.angleMode.index + 1) % 3],
  );

  void onKey(String key) {
    if (key == 'SHIFT') {
      state = state.copyWith(
        isShiftActive: !state.isShiftActive,
        isAlphaActive: false,
      );
      return;
    }
    if (key == 'ALPHA') {
      state = state.copyWith(
        isAlphaActive: !state.isAlphaActive,
        isShiftActive: false,
      );
      return;
    }
    if (key == 'HYP') {
      state = state.copyWith(
        isHypActive: !state.isHypActive,
        isShiftActive: false,
        isAlphaActive: false,
      );
      return;
    }

    String eff = key;
    if (state.isShiftActive && _shiftMap.containsKey(key)) {
      eff = _shiftMap[key]!;
    } else if (state.isAlphaActive && _alphaMap.containsKey(key)) {
      eff = _alphaMap[key]!;
    } else if (state.isHypActive && _hypMap.containsKey(key)) {
      eff = _hypMap[key]!;
    }

    state = state.copyWith(
      isShiftActive: false,
      isAlphaActive: false,
      isHypActive: false,
    );

    if (eff == 'AC') {
      // AC in mode menu dismisses it; otherwise clears expression
      if (state.showModeMenu) {
        state = state.copyWith(showModeMenu: false, modeMessage: '');
      } else {
        state = state.copyWith(
          expression: '',
          result: '0',
          justEvaluated: false,
        );
      }
    } else if (eff == 'DEL') {
      if (state.showModeMenu) {
        state = state.copyWith(showModeMenu: false, modeMessage: '');
      } else {
        _backspace();
      }
    } else if (eff == '=') {
      if (!state.showModeMenu) _evaluate();
    } else if (eff == 'MODE') {
      // Open / close the MODE selection menu
      state = state.copyWith(
        showModeMenu: !state.showModeMenu,
        modeMessage: '',
        isShiftActive: false,
        isAlphaActive: false,
      );
    } else if (state.showModeMenu) {
      // While menu is open, digit 1-8 selects a mode
      _selectMode(eff);
    } else if (const {
      'UP',
      'DOWN',
      'LEFT',
      'RIGHT',
      'ON',
      'CALC',
      'RCL',
      'ENG',
    }.contains(eff)) {
      // no-op
    } else {
      _append(eff);
    }
  }

  // ── Mode selection ───────────────────────────────────────────────────────────
  void _selectMode(String key) {
    final n = int.tryParse(key);
    if (n == null || n < 1 || n > 8) {
      // Unknown key while menu open — just close menu
      state = state.copyWith(showModeMenu: false, modeMessage: '');
      return;
    }
    final chosen = CalculatorMode.values[n - 1];
    // After selecting, reset expression/result and show the new mode
    state = state.copyWith(
      calcMode: chosen,
      showModeMenu: false,
      expression: '',
      result: '0',
      justEvaluated: false,
      modeMessage: chosen.displayName,
    );
    // Clear the modeMessage after 1.5 s so the LCD returns to normal
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (state.modeMessage == chosen.displayName) {
        state = state.copyWith(modeMessage: '');
      }
    });
  }

  // ── Modifier maps ────────────────────────────────────────────────────────────
  static const Map<String, String> _shiftMap = {
    'sin(': 'asin(',
    'cos(': 'acos(',
    'tan(': 'atan(',
    'sqrt(': '³√(',
    'ln(': 'e^(',
    'log(': '10^(',
    '×': 'nPr(',
    '÷': 'nCr(',
    '+': 'Pol(',
    '-': 'Rec(',
    'DEL': 'AC',
    'M+': 'M-',
    '.': 'Ran#',
    '×10^(': 'RanInt(',
    '0': 'Rnd',
    '7': 'CONST',
    '8': 'CONV',
    'x^-1': 'x!',
  };

  static const Map<String, String> _alphaMap = {
    '(': 'i',
    ')': '%',
    'sin(': 'B',
    'cos(': 'C',
    'tan(': 'D',
    '-': 'A',
    '.': 'π',
    '×10^(': 'e',
    'M+': 'M',
  };

  static const Map<String, String> _hypMap = {
    'sin(': 'sinh(',
    'cos(': 'cosh(',
    'tan(': 'tanh(',
  };

  // ── Append ───────────────────────────────────────────────────────────────────
  void _append(String token) {
    String expr = state.expression;
    if (state.justEvaluated) {
      expr = _isOperator(token) ? 'Ans' : '';
    }
    if (expr.isNotEmpty) {
      final last = expr[expr.length - 1];
      final isVal = RegExp(r'[\d\.πe\)]').hasMatch(last);
      final opens = token == '(' || token.endsWith('(');
      if (isVal && opens) expr += '×';
    }
    state = state.copyWith(expression: expr + token, justEvaluated: false);
  }

  bool _isOperator(String t) => '+-×÷^%'.contains(t) || t == '×10^(';

  // ── Backspace ────────────────────────────────────────────────────────────────
  void _backspace() {
    final e = state.expression;
    if (e.isEmpty) return;
    const multi = [
      'asin(',
      'acos(',
      'atan(',
      'sinh(',
      'cosh(',
      'tanh(',
      'sin(',
      'cos(',
      'tan(',
      'sqrt(',
      '³√(',
      'log(',
      'ln(',
      '10^(',
      'e^(',
      '×10^(',
      'Ans',
      'nPr(',
      'nCr(',
      'Pol(',
      'Rec(',
    ];
    for (final t in multi) {
      if (e.endsWith(t)) {
        state = state.copyWith(expression: e.substring(0, e.length - t.length));
        return;
      }
    }
    state = state.copyWith(expression: e.substring(0, e.length - 1));
  }

  // ── Evaluate ─────────────────────────────────────────────────────────────────
  void _evaluate() {
    if (state.expression.isEmpty) return;
    try {
      String e = _preprocess(state.expression);
      e = e.replaceAllMapped(RegExp(r'(\d|\))\('), (m) => '${m.group(1)}*(');
      final raw = mx.GrammarParser()
          .parse(e)
          .evaluate(mx.EvaluationType.REAL, mx.ContextModel());
      final result = (raw as num).toDouble();

      if (result.isNaN) {
        state = state.copyWith(result: 'Math ERROR');
        return;
      }
      if (result.isInfinite) {
        state = state.copyWith(result: result > 0 ? '∞' : '-∞');
        return;
      }
      final fmt = _fmt(result);
      final hist = [
        '${state.expression} = $fmt',
        ...state.history,
      ].take(10).toList();
      state = state.copyWith(
        result: fmt,
        lastAnswer: fmt,
        history: hist,
        justEvaluated: true,
      );
    } catch (_) {
      state = state.copyWith(result: 'Syntax ERROR');
    }
  }

  // ── Pre-processor ────────────────────────────────────────────────────────────
  String _preprocess(String raw) {
    String e = raw
        .replaceAllMapped(
          RegExp(r'(\d|\))π'),
          (m) => '${m.group(1)}*${math.pi}',
        )
        .replaceAll('π', '${math.pi}')
        .replaceAll('Ans', '(${state.lastAnswer})')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('e^(', '${math.e}^(');

    e = e.replaceAllMapped(
      RegExp(r'(?<![a-zA-Z])e(?![a-zA-Z(])'),
      (_) => '(${math.e})',
    );

    e = e.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
      final n = int.tryParse(m.group(1)!) ?? -1;
      if (n < 0 || n > 20) return '(0/0)';
      int f = 1;
      for (int i = 2; i <= n; i++) f *= i;
      return f.toString();
    });

    for (int pass = 0; pass < 8; pass++) {
      final prev = e;

      e = e.replaceAllMapped(RegExp(r'³√\(([^()]+)\)'), (m) {
        try {
          final x = _ev(m.group(1)!);
          return _w(
            x < 0
                ? -(math.pow(-x, 1.0 / 3).toDouble())
                : math.pow(x, 1.0 / 3).toDouble(),
          );
        } catch (_) {
          return m.group(0)!;
        }
      });

      e = e.replaceAllMapped(RegExp(r'(?<![a-z])log\(([^()]+)\)'), (m) {
        try {
          return _w(math.log(_ev(m.group(1)!)) / math.ln10);
        } catch (_) {
          return m.group(0)!;
        }
      });

      e = e.replaceAllMapped(RegExp(r'ln\(([^()]+)\)'), (m) {
        try {
          return _w(math.log(_ev(m.group(1)!)));
        } catch (_) {
          return m.group(0)!;
        }
      });

      e = e.replaceAllMapped(RegExp(r'(sinh|cosh|tanh)\(([^()]+)\)'), (m) {
        try {
          final fn = m.group(1)!;
          final x = _ev(m.group(2)!);
          final v = switch (fn) {
            'sinh' => (math.exp(x) - math.exp(-x)) / 2,
            'cosh' => (math.exp(x) + math.exp(-x)) / 2,
            _ => (math.exp(x) - math.exp(-x)) / (math.exp(x) + math.exp(-x)),
          };
          return _w(v);
        } catch (_) {
          return m.group(0)!;
        }
      });

      e = e.replaceAllMapped(RegExp(r'(a?sin|a?cos|a?tan)\(([^()]+)\)'), (m) {
        try {
          return _w(_trig(m.group(1)!, _ev(m.group(2)!), state.angleMode));
        } catch (_) {
          return m.group(0)!;
        }
      });

      if (e == prev) break;
    }
    return e;
  }

  static double _ev(String s) {
    final raw = mx.GrammarParser()
        .parse(s)
        .evaluate(mx.EvaluationType.REAL, mx.ContextModel());
    return (raw as num).toDouble();
  }

  static String _w(double v) => v < 0 ? '($v)' : '$v';

  static double _trig(String fn, double x, AngleMode m) {
    final k = m == AngleMode.deg
        ? math.pi / 180
        : m == AngleMode.grad
        ? math.pi / 200
        : 1.0;
    return switch (fn) {
      'sin' => math.sin(x * k),
      'cos' => math.cos(x * k),
      'tan' => math.tan(x * k),
      'asin' => math.asin(x) / k,
      'acos' => math.acos(x) / k,
      'atan' => math.atan(x) / k,
      _ => x,
    };
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble() && v.abs() < 1e15)
      return v.toInt().toString();
    final abs = v.abs();
    if (abs >= 1e10 || (abs < 1e-4 && v != 0)) {
      return v
          .toStringAsExponential(7)
          .replaceAllMapped(
            RegExp(r'e([+-])0*(\d+)'),
            (m) => '×10${_sup(m.group(1)!)}${_sup(m.group(2)!)}',
          );
    }
    return v
        .toStringAsFixed(10)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  static String _sup(String s) {
    const m = {
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
      '+': '⁺',
      '-': '⁻',
    };
    return s.split('').map((c) => m[c] ?? c).join();
  }
}

// Provider
final calculatorProvider =
    NotifierProvider.autoDispose<CalculatorNotifier, CalculatorState>(
      CalculatorNotifier.new,
    );

// ═══════════════════════════════════════════════════════════════════════════════
//  D-PAD CUSTOM PAINTER
// ═══════════════════════════════════════════════════════════════════════════════
class _DPadPainter extends CustomPainter {
  const _DPadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.46;
    final aw = r * 0.35; // arm width

    // Outer shadow glow
    canvas.drawCircle(
      c,
      r + 2,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Outer disc
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF545468), const Color(0xFF181820)],
          stops: const [0.5, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Inner highlight ring
    canvas.drawCircle(
      c,
      r * 0.97,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.08),
    );

    // Cross arm shader
    final armShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [const Color(0xFF6E6E82), const Color(0xFF24243A)],
    ).createShader(Rect.fromCenter(center: c, width: r * 2, height: r * 2));
    final armPaint = Paint()..shader = armShader;

    // Horizontal arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: r * 2.05, height: aw),
        const Radius.circular(4),
      ),
      armPaint,
    );

    // Vertical arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: aw, height: r * 2.05),
        const Radius.circular(4),
      ),
      armPaint,
    );

    // Center disk
    canvas.drawCircle(
      c,
      aw * 0.52,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF909098), const Color(0xFF2A2A38)],
        ).createShader(Rect.fromCircle(center: c, radius: aw * 0.52)),
    );

    // Chevron arrows
    final ap = Paint()
      ..color = Colors.white.withValues(alpha: 0.62)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final d = r * 0.64; // tip distance
    final s = r * 0.11; // chevron half-size

    void chev(Offset tip, Offset l, Offset r2) => canvas.drawPath(
      Path()
        ..moveTo(l.dx, l.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(r2.dx, r2.dy),
      ap,
    );

    // Up
    chev(
      Offset(c.dx, c.dy - d),
      Offset(c.dx - s, c.dy - d + s),
      Offset(c.dx + s, c.dy - d + s),
    );
    // Down
    chev(
      Offset(c.dx, c.dy + d),
      Offset(c.dx - s, c.dy + d - s),
      Offset(c.dx + s, c.dy + d - s),
    );
    // Left
    chev(
      Offset(c.dx - d, c.dy),
      Offset(c.dx - d + s, c.dy - s),
      Offset(c.dx - d + s, c.dy + s),
    );
    // Right
    chev(
      Offset(c.dx + d, c.dy),
      Offset(c.dx + d - s, c.dy - s),
      Offset(c.dx + d - s, c.dy + s),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DIRECTIONAL PAD WIDGET
// ═══════════════════════════════════════════════════════════════════════════════
class _DPad extends StatelessWidget {
  final VoidCallback onUp, onDown, onLeft, onRight;

  const _DPad({
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, bc) {
      final sz = math.min(bc.maxWidth, bc.maxHeight) * 0.94;
      return Center(
        child: SizedBox.square(
          dimension: sz,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: const _DPadPainter()),
              ),
              _tap(Alignment.topCenter, 0.34, 0.30, onUp),
              _tap(Alignment.bottomCenter, 0.34, 0.30, onDown),
              _tap(Alignment.centerLeft, 0.30, 0.34, onLeft),
              _tap(Alignment.centerRight, 0.30, 0.34, onRight),
            ],
          ),
        ),
      );
    },
  );

  Widget _tap(Alignment a, double wf, double hf, VoidCallback fn) => Align(
    alignment: a,
    child: FractionallySizedBox(
      widthFactor: wf,
      heightFactor: hf,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          fn();
        },
        behavior: HitTestBehavior.opaque,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BUTTON WIDGET  (with press animation)
// ═══════════════════════════════════════════════════════════════════════════════
class _Btn extends StatefulWidget {
  final String label;
  final String? shiftLabel;
  final String? alphaLabel;
  final Color bg;
  final Color fg;
  final double fs;
  final VoidCallback onTap;

  const _Btn({
    required this.label,
    required this.onTap,
    this.shiftLabel,
    this.alphaLabel,
    this.bg = _kSci,
    this.fg = Colors.white,
    this.fs = 12.0,
  });

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 65),
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _ac.value;
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _ac.forward();
      },
      onTapUp: (_) {
        _ac.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _ac.reverse();
      },
      child: Transform.scale(
        scale: 1.0 - 0.07 * t,
        child: Container(
          margin: const EdgeInsets.all(1.8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(widget.bg, Colors.white, 0.18 - 0.06 * t)!,
                widget.bg,
                Color.lerp(widget.bg, Colors.black, 0.30 + 0.10 * t)!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.60 - 0.15 * t),
                blurRadius: 4,
                offset: Offset(0, 2.5 - 1.5 * t),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 0.5,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Micro labels row (SHIFT / ALPHA)
              Padding(
                padding: const EdgeInsets.fromLTRB(3, 1.5, 3, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.shiftLabel != null)
                      Flexible(
                        child: Text(
                          widget.shiftLabel!,
                          style: const TextStyle(
                            fontSize: 6.8,
                            fontWeight: FontWeight.w800,
                            color: _kShTxt,
                            height: 1,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (widget.alphaLabel != null)
                      Flexible(
                        child: Text(
                          widget.alphaLabel!,
                          style: const TextStyle(
                            fontSize: 6.8,
                            fontWeight: FontWeight.w800,
                            color: _kAlTxt,
                            height: 1,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                          textAlign: TextAlign.end,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
              // Main label
              Expanded(
                child: Center(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: widget.fs,
                      fontWeight: FontWeight.w700,
                      color: widget.fg,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 3),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  LCD DISPLAY
// ═══════════════════════════════════════════════════════════════════════════════
class _Lcd extends StatelessWidget {
  final CalculatorState state;
  final VoidCallback onModeTap;

  const _Lcd({required this.state, required this.onModeTap});

  // Mode menu rows — exactly matches the real Casio fx-991ES PLUS
  static const _modeRows = [
    [('1', 'COMP'), ('2', 'CMPLX')],
    [('3', 'STAT'), ('4', 'BASE-N')],
    [('5', 'EQN'), ('6', 'MATRIX')],
    [('7', 'TABLE'), ('8', 'VECTOR')],
  ];

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
    decoration: BoxDecoration(
      color: _kLcdBg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _kLcdBdr, width: 2.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.55),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        const BoxShadow(
          color: Color(0x1880A078),
          blurRadius: 6,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 8),
      child: state.showModeMenu ? _buildModeMenu() : _buildCalc(),
    ),
  );

  // ── MODE selection overlay — pixel-faithful Casio layout ─────────────────────
  Widget _buildModeMenu() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Header row
      Row(
        children: [
          Text(
            'MODE',
            style: GoogleFonts.robotoMono(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0A1A0A),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'SETUP',
            style: GoogleFonts.robotoMono(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1A2A18),
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          _tag(state.angleMode.name.toUpperCase(), bordered: true),
        ],
      ),
      const SizedBox(height: 3),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _modeRows
              .map(
                (row) => Row(
                  children: row.map((item) {
                    final num = item.$1;
                    final label = item.$2;
                    final modeIdx = int.parse(num) - 1;
                    final isActive = state.calcMode.index == modeIdx;
                    return Expanded(
                      child: Row(
                        children: [
                          // Number badge (inverted when selected)
                          Container(
                            width: 14,
                            height: 14,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF0A2A0A)
                                  : Colors.transparent,
                              border: Border.all(
                                color: const Color(0xFF192418),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              num,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                color: isActive
                                    ? _kLcdBg
                                    : const Color(0xFF0A2A0A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            label,
                            style: GoogleFonts.robotoMono(
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w900
                                  : FontWeight.w500,
                              color: const Color(0xFF0A2A0A),
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );

  // ── Normal calculator display ─────────────────────────────────────────────────
  Widget _buildCalc() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // ── Status bar ─────────────────────────────────────────────
      Row(
        children: [
          _tag(state.calcMode.displayName),
          const SizedBox(width: 4),
          _tag('MATH'),
          const Spacer(),
          if (state.isHypActive)
            _badge('HYP', const Color(0xFF2060A0), Colors.white),
          if (state.isShiftActive) ...[
            const SizedBox(width: 3),
            _badge('S', _kShTxt, Colors.black),
          ],
          if (state.isAlphaActive) ...[
            const SizedBox(width: 3),
            _badge('A', _kAlTxt, Colors.white),
          ],
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onModeTap,
            child: _tag(state.angleMode.name.toUpperCase(), bordered: true),
          ),
        ],
      ),
      const SizedBox(height: 4),

      // ── Mode switch confirmation message  ─────────────────────
      if (state.modeMessage.isNotEmpty)
        Expanded(
          child: Center(
            child: Text(
              state.modeMessage,
              style: GoogleFonts.robotoMono(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0A2A0A),
              ),
            ),
          ),
        )
      else ...[
        // ── Expression ─────────────────────────────────────────────
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.expression,
                    style: GoogleFonts.robotoMono(
                      fontSize: 20,
                      color: const Color(0xFF192418),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: state.showCursor ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 40),
                    child: Container(
                      width: 1.8,
                      height: 18,
                      color: const Color(0xFF192418),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Result ────────────────────────────────────────────────
        Text(
          state.result,
          style: GoogleFonts.robotoMono(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0C1A0C),
            height: 1.1,
          ),
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ],
  );

  static Widget _tag(String t, {bool bordered = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
    decoration: BoxDecoration(
      color: bordered
          ? Colors.transparent
          : const Color(0xFF192418).withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(2),
      border: bordered
          ? Border.all(color: const Color(0xFF192418), width: 0.8)
          : null,
    ),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 8.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFF192418),
        height: 1,
      ),
    ),
  );

  static Widget _badge(String t, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(2),
    ),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 8.5,
        fontWeight: FontWeight.w800,
        color: fg,
        height: 1,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CASIO HEADER  (back button + branding)
// ═══════════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    color: const Color(0xFF13131A),
    child: Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFFAAAAAC),
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CASIO',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            Text(
              'fx-991ES PLUS   NATURAL-V.P.A.M.',
              style: GoogleFonts.robotoMono(
                color: const Color(0xFF7A8898),
                fontSize: 7.5,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF383848), width: 0.8),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Text(
            '2nd edition',
            style: TextStyle(
              fontSize: 7.5,
              color: Color(0xFF686878),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Decorative solar strip
        Container(
          width: 36,
          height: 13,
          decoration: BoxDecoration(
            color: const Color(0xFF080810),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.white12, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              6,
              (i) => Container(
                width: 3.5,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07 + i * 0.04),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  D-PAD SECTION  (SHIFT/CALC + ALPHA/∫dx + D-Pad + MODE/x⁻¹ + ON/log□)
// ═══════════════════════════════════════════════════════════════════════════════
class _DPadSection extends StatelessWidget {
  final CalculatorState state;
  final void Function(String) onKey;

  const _DPadSection({required this.state, required this.onKey});

  @override
  Widget build(BuildContext context) {
    Widget twoStack(List<Widget> kids) => Expanded(
      child: Column(children: kids.map((w) => Expanded(child: w)).toList()),
    );

    Widget b(
      String lbl,
      String k, {
      String? sh,
      String? al,
      Color bg = _kSci,
      Color fg = Colors.white,
      double fs = 11.5,
    }) => _Btn(
      label: lbl,
      shiftLabel: sh,
      alphaLabel: al,
      bg: bg,
      fg: fg,
      fs: fs,
      onTap: () => onKey(k),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Col 1: SHIFT + CALC
        twoStack([
          _Btn(
            label: 'SHIFT',
            fs: 9.5,
            bg: state.isShiftActive
                ? const Color(0xFF5A3E00)
                : const Color(0xFF1A2E50),
            fg: _kShTxt,
            onTap: () => onKey('SHIFT'),
          ),
          b('CALC', 'CALC', sh: 'SOLVE', al: '='),
        ]),
        // Col 2: ALPHA + ∫dx
        twoStack([
          _Btn(
            label: 'ALPHA',
            fs: 9.5,
            bg: state.isAlphaActive
                ? const Color(0xFF4A0A20)
                : const Color(0xFF260C3A),
            fg: _kAlTxt,
            onTap: () => onKey('ALPHA'),
          ),
          b('∫dx', '∫dx', sh: 'd/dx', al: ':'),
        ]),
        // Center: D-Pad (width = 2 cols)
        Expanded(
          flex: 2,
          child: _DPad(
            onUp: () => onKey('UP'),
            onDown: () => onKey('DOWN'),
            onLeft: () => onKey('LEFT'),
            onRight: () => onKey('RIGHT'),
          ),
        ),
        // Col 5: MODE + x⁻¹
        twoStack([
          b('MODE', 'MODE', sh: 'SETUP', fs: 9.0),
          b('x⁻¹', 'x^-1', sh: 'x!'),
        ]),
        // Col 6: ON + log□
        twoStack([
          b('ON', 'ON', fs: 9.0),
          b('log□', 'log(', sh: '10ˣ', fs: 10.5),
        ]),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN  — assembles everything
// ═══════════════════════════════════════════════════════════════════════════════
class ScientificCalculatorScreen extends ConsumerWidget {
  const ScientificCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final st = ref.watch(calculatorProvider);
    final nt = ref.read(calculatorProvider.notifier);

    // ── Local button factory ────────────────────────────────────────────────
    Widget b(
      String label, {
      required String k,
      String? sh,
      String? al,
      Color bg = _kSci,
      Color fg = Colors.white,
      double fs = 12.0,
    }) => _Btn(
      label: label,
      shiftLabel: sh,
      alphaLabel: al,
      bg: bg,
      fg: fg,
      fs: fs,
      onTap: () => nt.onKey(k),
    );

    // Builds a row of equal-width buttons
    Widget keyRow(List<Widget> kids) => Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: kids.map((w) => Expanded(child: w)).toList(),
    );

    return Scaffold(
      backgroundColor: _kScaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── CASIO Header ──────────────────────────────────────────────
            _Header(onBack: () => Navigator.pop(context)),

            // ── LCD Display ───────────────────────────────────────────────
            SizedBox(
              height: 128,
              child: _Lcd(state: st, onModeTap: nt.cycleAngleMode),
            ),

            // ── Keyboard Area ─────────────────────────────────────────────
            Expanded(
              child: Container(
                color: _kKeypad,
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 5),
                child: Column(
                  children: [
                    // ── ROW 0: D-Pad section (double height = flex 22) ─────
                    Expanded(
                      flex: 22,
                      child: _DPadSection(state: st, onKey: nt.onKey),
                    ),

                    // ── ROW 1: a b/c | √x | x² | xʸ | log | ln ───────────
                    Expanded(
                      flex: 10,
                      child: keyRow([
                        b('a b/c', k: '/', sh: 'a/b'),
                        b('√x', k: 'sqrt(', sh: '³√('),
                        b('x²', k: '^2'),
                        b('xʸ', k: '^'),
                        b('log', k: 'log(', sh: '10^('),
                        b('ln', k: 'ln(', sh: 'e^('),
                      ]),
                    ),

                    // ── ROW 2: (-) | °''' | hyp | sin | cos | tan ─────────
                    Expanded(
                      flex: 10,
                      child: keyRow([
                        b('(-)', k: '-', al: 'A'),
                        b("°'''", k: '°'),
                        b(
                          'hyp',
                          k: 'HYP',
                          bg: st.isHypActive ? const Color(0xFF0E3A60) : _kSci,
                        ),
                        b('sin', k: 'sin(', sh: 'sin⁻¹', al: 'B'),
                        b('cos', k: 'cos(', sh: 'cos⁻¹', al: 'C'),
                        b('tan', k: 'tan(', sh: 'tan⁻¹', al: 'D'),
                      ]),
                    ),

                    // ── ROW 3: RCL | ENG | ( | ) | S⇔D | M+ ──────────────
                    Expanded(
                      flex: 10,
                      child: keyRow([
                        b('RCL', k: 'RCL', sh: 'STO'),
                        b('ENG', k: 'ENG'),
                        b('(', k: '(', al: 'i'),
                        b(')', k: ')', al: '%'),
                        b('S⇔D', k: 'S⇔D'),
                        b('M+', k: 'M+', sh: 'M-', al: 'M'),
                      ]),
                    ),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Container(
                        height: 0.8,
                        color: const Color(0xFF24243A),
                      ),
                    ),

                    // ── ROW 4: 7 | 8 | 9 | DEL | AC ──────────────────────
                    Expanded(
                      flex: 13,
                      child: keyRow([
                        b('7', k: '7', sh: 'CONST', bg: _kNum),
                        b('8', k: '8', sh: 'CONV', bg: _kNum),
                        b('9', k: '9', bg: _kNum),
                        b(
                          'DEL',
                          k: 'DEL',
                          sh: 'CLR',
                          bg: _kGreen,
                          fg: Colors.white,
                          fs: 13,
                        ),
                        b(
                          'AC',
                          k: 'AC',
                          sh: 'OFF',
                          bg: _kGreen,
                          fg: Colors.white,
                          fs: 13,
                        ),
                      ]),
                    ),

                    // ── ROW 5: 4 | 5 | 6 | × | ÷ ─────────────────────────
                    Expanded(
                      flex: 13,
                      child: keyRow([
                        b('4', k: '4', sh: 'MATRIX', bg: _kNum),
                        b('5', k: '5', sh: 'VECTOR', bg: _kNum),
                        b('6', k: '6', sh: 'BASE', bg: _kNum),
                        b('×', k: '×', sh: 'nPr', bg: _kOp, fs: 16),
                        b('÷', k: '÷', sh: 'nCr', bg: _kOp, fs: 16),
                      ]),
                    ),

                    // ── ROW 6: 1 | 2 | 3 | + | − ─────────────────────────
                    Expanded(
                      flex: 13,
                      child: keyRow([
                        b('1', k: '1', sh: 'STAT', bg: _kNum),
                        b('2', k: '2', sh: 'CMPLX', bg: _kNum),
                        b('3', k: '3', sh: 'BASE', bg: _kNum),
                        b('+', k: '+', sh: 'Pol', bg: _kOp, fs: 16),
                        b('−', k: '-', sh: 'Rec', bg: _kOp, fs: 16),
                      ]),
                    ),

                    // ── ROW 7: 0 | . | ×10ˣ | Ans | = ───────────────────
                    Expanded(
                      flex: 13,
                      child: keyRow([
                        b('0', k: '0', sh: 'Rnd', bg: _kNum),
                        b('.', k: '.', sh: 'Ran#', al: 'π', bg: _kNum),
                        b(
                          '×10ˣ',
                          k: '×10^(',
                          sh: 'Rnd#',
                          al: 'e',
                          bg: _kOp,
                          fs: 10.5,
                        ),
                        b('Ans', k: 'Ans', bg: _kOp),
                        b(
                          '=',
                          k: '=',
                          bg: const Color(0xFF0E3E78),
                          fg: Colors.white,
                          fs: 18,
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
