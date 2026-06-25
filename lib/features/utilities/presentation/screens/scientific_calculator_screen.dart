import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:math_expressions/math_expressions.dart';

class ScientificCalculatorScreen extends StatefulWidget {
  const ScientificCalculatorScreen({super.key});

  @override
  State<ScientificCalculatorScreen> createState() =>
      _ScientificCalculatorScreenState();
}

class _ScientificCalculatorScreenState
    extends State<ScientificCalculatorScreen> {
  String _expression = '';
  String _result = '0';
  bool _isShiftActive = false;
  bool _isAlphaActive = false;
  bool _showCursor = true;
  Timer? _cursorTimer;

  // History for Ans key
  String _lastAnswer = '0';

  @override
  void initState() {
    super.initState();
    // Start cursor blinking
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _onKeyPress(String key, {String? shiftVal, String? alphaVal}) {
    setState(() {
      String activeValue = key;
      if (_isShiftActive && shiftVal != null) {
        activeValue = shiftVal;
        _isShiftActive = false;
      } else if (_isAlphaActive && alphaVal != null) {
        activeValue = alphaVal;
        _isAlphaActive = false;
      } else {
        _isShiftActive = false;
        _isAlphaActive = false;
      }

      if (activeValue == 'AC') {
        _expression = '';
        _result = '0';
      } else if (activeValue == 'DEL') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (activeValue == '=') {
        _evaluateExpression();
      } else if (activeValue == 'SHIFT') {
        _isShiftActive = !_isShiftActive;
        _isAlphaActive = false;
      } else if (activeValue == 'ALPHA') {
        _isAlphaActive = !_isAlphaActive;
        _isShiftActive = false;
      } else if (activeValue == 'Ans') {
        _expression += 'Ans';
      } else if (activeValue == 'x^y') {
        _expression += '^';
      } else if (activeValue == 'x^2') {
        _expression += '^2';
      } else if (activeValue == 'x^-1') {
        _expression += '^-1';
      } else if (activeValue == 'sin') {
        _expression += 'sin(';
      } else if (activeValue == 'cos') {
        _expression += 'cos(';
      } else if (activeValue == 'tan') {
        _expression += 'tan(';
      } else if (activeValue == 'sin^-1') {
        _expression += 'asin(';
      } else if (activeValue == 'cos^-1') {
        _expression += 'acos(';
      } else if (activeValue == 'tan^-1') {
        _expression += 'atan(';
      } else if (activeValue == 'ln') {
        _expression += 'ln(';
      } else if (activeValue == 'log') {
        _expression += 'log(';
      } else if (activeValue == 'pi') {
        _expression += 'π';
      } else if (activeValue == 'e') {
        _expression += 'e';
      } else if (activeValue == 'sqrt') {
        _expression += '√(';
      } else if (activeValue == '3sqrt') {
        _expression += '³√(';
      } else {
        _expression += activeValue;
      }
    });
  }

  void _evaluateExpression() {
    if (_expression.isEmpty) return;

    try {
      String formattedExp = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '3.1415926535897932')
          .replaceAll('e', '2.7182818284590452')
          .replaceAll('Ans', _lastAnswer);

      // Handle implied multiplication like 2(3) -> 2*(3)
      formattedExp = formattedExp.replaceAllMapped(
          RegExp(r'(\d+|\)|π|e)\s*\('), (match) => '${match.group(1)}*(');

      // Handle square roots
      formattedExp = formattedExp.replaceAllMapped(
          RegExp(r'√\(([^)]+)\)'), (match) => 'sqrt(${match.group(1)})');

      Parser p = Parser();
      Expression exp = p.parse(formattedExp);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      setState(() {
        if (eval.isNaN) {
          _result = 'Error';
        } else {
          // Format output
          if (eval % 1 == 0) {
            _result = eval.toInt().toString();
          } else {
            _result = eval.toStringAsFixed(8);
            // remove trailing zeros
            while (_result.endsWith('0')) {
              _result = _result.substring(0, _result.length - 1);
            }
            if (_result.endsWith('.')) {
              _result = _result.substring(0, _result.length - 1);
            }
          }
          _lastAnswer = _result;
        }
      });
    } catch (e) {
      setState(() {
        _result = 'Syntax Error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scientific Calculator',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display Area
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              height: size.height * 0.22,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E4DC), // Minty gray screen
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Statuses Indicator bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NORM  MATH  DECI',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0x902F3A34),
                        ),
                      ),
                      Row(
                        children: [
                          if (_isShiftActive)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAB308),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'S',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          if (_isAlphaActive)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA855F7),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'A',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Text(
                            'DEG',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2F3A34),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Input expression
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Row(
                          children: [
                            Text(
                              _expression,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                color: const Color(0xFF1E2822),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_showCursor)
                              Container(
                                width: 2,
                                height: 26,
                                color: Colors.redAccent,
                              )
                            else
                              const SizedBox(width: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Result Display
                  Container(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _result,
                      style: GoogleFonts.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F1A13),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top functional bar above keypads
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.menu_rounded, color: Colors.white60, size: 22),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF6366F1), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.diamond_outlined, color: Colors.cyanAccent, size: 12),
                            const SizedBox(width: 3),
                            Text(
                              'PRO',
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Σ', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 16)),
                      const SizedBox(width: 12),
                      const Icon(Icons.settings_rounded, color: Colors.white60, size: 20),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Keypad Grid area
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF121214), // Very dark keyboard bg
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mode / Shift / Arrows Row
                    _buildButtonRow([
                      _buildKey('SHIFT', color: const Color(0xFFD97706), textColor: Colors.black),
                      _buildKey('ALPHA', color: const Color(0xFF7C3AED), textColor: Colors.white),
                      _buildKey('◀', action: () => setState(() {})),
                      _buildKey('▶', action: () => setState(() {})),
                      _buildKey('MODE', color: const Color(0xFF374151)),
                      _buildKey('2nd', color: const Color(0xFF374151)),
                    ]),

                    // Function Row 1
                    _buildButtonRow([
                      _buildKey('CALC', shift: 'SOLVE', alpha: '='),
                      _buildKey('∫dx', shift: 'd/dx', alpha: ':'),
                      _buildKey('▲'),
                      _buildKey('▼'),
                      _buildKey('x⁻¹', shift: 'x!', alpha: 'Σ', raw: 'x^-1'),
                      _buildKey('logₓy', alpha: '∏', raw: 'log'),
                    ]),

                    // Function Row 2
                    _buildButtonRow([
                      _buildKey('x/y', shift: 'x/z', raw: '/'),
                      _buildKey('√x', shift: '3√x', raw: 'sqrt'),
                      _buildKey('x²', raw: 'x^2'),
                      _buildKey('xʸ', raw: 'x^y'),
                      _buildKey('log', raw: 'log'),
                      _buildKey('ln', raw: 'ln'),
                    ]),

                    // Function Row 3
                    _buildButtonRow([
                      _buildKey('(-)', raw: '-'),
                      _buildKey('o\'\'\'', raw: '°'),
                      _buildKey('hyp'),
                      _buildKey('sin', shift: 'sin⁻¹'),
                      _buildKey('cos', shift: 'cos⁻¹'),
                      _buildKey('tan', shift: 'tan⁻¹'),
                    ]),

                    // Function Row 4
                    _buildButtonRow([
                      _buildKey('RCL', shift: 'STO'),
                      _buildKey('ENG', shift: 'CLRv'),
                      _buildKey('(', alpha: 'i'),
                      _buildKey(')', shift: 'cot', alpha: '%'),
                      _buildKey('S⇔D', shift: 'cot⁻¹'),
                      _buildKey('M+', shift: 'M-', alpha: 'm'),
                    ]),

                    // Number Row 1
                    _buildButtonRow([
                      _buildKey('7', shift: 'CONST', color: const Color(0xFF2A2A2E)),
                      _buildKey('8', shift: 'CONV', color: const Color(0xFF2A2A2E)),
                      _buildKey('9', alpha: 'SI', color: const Color(0xFF2A2A2E)),
                      _buildKey('DEL', shift: 'CLR', color: const Color(0xFFD97706)),
                      _buildKey('AC', shift: 'ALL', color: const Color(0xFFD97706)),
                    ]),

                    // Number Row 2
                    _buildButtonRow([
                      _buildKey('4', shift: 'MATRIX', color: const Color(0xFF2A2A2E)),
                      _buildKey('5', shift: 'VECTOR', color: const Color(0xFF2A2A2E)),
                      _buildKey('6', shift: 'FUNC', color: const Color(0xFF2A2A2E)),
                      _buildKey('×', raw: '×', color: const Color(0xFF3F3F46)),
                      _buildKey('÷', raw: '÷', color: const Color(0xFF3F3F46)),
                    ]),

                    // Number Row 3
                    _buildButtonRow([
                      _buildKey('1', shift: 'STAT', color: const Color(0xFF2A2A2E)),
                      _buildKey('2', shift: 'CMPLX', color: const Color(0xFF2A2A2E)),
                      _buildKey('3', shift: 'DISTR', color: const Color(0xFF2A2A2E)),
                      _buildKey('+', raw: '+', color: const Color(0xFF3F3F46)),
                      _buildKey('-', raw: '-', color: const Color(0xFF3F3F46)),
                    ]),

                    // Number Row 4
                    _buildButtonRow([
                      _buildKey('0', shift: 'COPY', color: const Color(0xFF2A2A2E)),
                      _buildKey('.', shift: 'PASTE', color: const Color(0xFF2A2A2E)),
                      _buildKey('Exp', shift: 'Ran#', color: const Color(0xFF2E2E33)),
                      _buildKey('Ans', shift: 'RanInt', color: const Color(0xFF2E2E33)),
                      _buildKey('=', shift: 'History', color: const Color(0xFF3F3F46)),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<Widget> children) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.map((w) => Expanded(child: Padding(padding: const EdgeInsets.all(2.5), child: w))).toList(),
      ),
    );
  }

  Widget _buildKey(
    String mainText, {
    String? shift,
    String? alpha,
    String? raw,
    Color color = const Color(0xFF3F3F46), // Default button gray
    Color textColor = Colors.white,
    VoidCallback? action,
  }) {
    return GestureDetector(
      onTap: () {
        if (action != null) {
          action();
        } else {
          _onKeyPress(raw ?? mainText, shiftVal: shift, alphaVal: alpha);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Secondary labels (Shift/Alpha)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    shift ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFBBF24), // Amber/Yellow
                    ),
                  ),
                  Text(
                    alpha ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC084FC), // Lavender/Purple
                    ),
                  ),
                ],
              ),
            ),
            // Main text
            Expanded(
              child: Center(
                child: Text(
                  mainText,
                  style: GoogleFonts.outfit(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
