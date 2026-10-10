import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_fox/shared/presentation/widgets/entrance_animations.dart';
import 'package:focus_fox/theme/app_theme.dart';

import 'utils/eigen_solver.dart';
import 'utils/gauss_elimination_solver.dart';
import 'utils/gauss_jordan_solver.dart';

class MatrixAppScreen extends StatefulWidget {
  const MatrixAppScreen({super.key});

  @override
  State<MatrixAppScreen> createState() => _MatrixAppScreenState();
}

class _MatrixAppScreenState extends State<MatrixAppScreen> {
  // Mode: 0 = Gauss Elimination, 1 = Matrix Inverse, 2 = Eigenvalues
  int _currentMode = 0;

  // Matrix Dimensions
  int _rows = 3;
  int _cols = 4; // Default to 3x4 augmented system for Gauss

  // Controllers for input cells
  List<List<TextEditingController>> _controllers = [];

  // Solutions
  List<MatrixStep>? _gaussSteps;
  List<double>? _gaussVariables;

  List<GaussJordanStep>? _inverseSteps;
  List<List<double>>? _inverseResult;
  bool _isInverseSingular = false;

  EigenResult? _eigenResult;

  @override
  void initState() {
    super.initState();
    _initMatrix(3, 4);
    _loadSampleData();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var row in _controllers) {
      for (var c in row) {
        c.dispose();
      }
    }
    _controllers.clear();
  }

  void _initMatrix(int rows, int cols) {
    _disposeControllers();
    _rows = rows;
    _cols = cols;
    _controllers = List.generate(
      rows,
      (_) => List.generate(cols, (_) => TextEditingController(text: '0')),
    );
    _clearResults();
  }

  void _clearResults() {
    setState(() {
      _gaussSteps = null;
      _gaussVariables = null;
      _inverseSteps = null;
      _inverseResult = null;
      _isInverseSingular = false;
      _eigenResult = null;
    });
  }

  void _onModeChanged(int newMode) {
    if (_currentMode == newMode) return;
    setState(() {
      _currentMode = newMode;
      if (newMode == 0) {
        // Gauss Elimination defaults to 3x4 system
        _initMatrix(3, 4);
      } else if (newMode == 1) {
        // Inverse defaults to 3x3 square matrix
        _initMatrix(3, 3);
      } else {
        // Eigen defaults to 2x2 or 3x3
        _initMatrix(2, 2);
      }
      _loadSampleData();
    });
  }

  void _loadSampleData() {
    _clearResults();
    if (_currentMode == 0) {
      if (_rows == 3 && _cols == 4) {
        // 2x + y - z = 8
        // -3x - y + 2z = -11
        // -2x + y + 2z = -3
        final sample = [
          [2.0, 1.0, -1.0, 8.0],
          [-3.0, -1.0, 2.0, -11.0],
          [-2.0, 1.0, 2.0, -3.0],
        ];
        _populateFromList(sample);
      } else if (_rows == 2 && _cols == 3) {
        final sample = [
          [1.0, 2.0, 5.0],
          [3.0, -1.0, 1.0],
        ];
        _populateFromList(sample);
      } else {
        _fillIdentityLike();
      }
    } else if (_currentMode == 1) {
      if (_rows == 2 && _cols == 2) {
        final sample = [
          [4.0, 7.0],
          [2.0, 6.0],
        ];
        _populateFromList(sample);
      } else if (_rows == 3 && _cols == 3) {
        final sample = [
          [1.0, 2.0, 3.0],
          [0.0, 1.0, 4.0],
          [5.0, 6.0, 0.0],
        ];
        _populateFromList(sample);
      } else {
        _fillIdentityLike();
      }
    } else {
      if (_rows == 2 && _cols == 2) {
        final sample = [
          [4.0, -2.0],
          [1.0, 1.0],
        ];
        _populateFromList(sample);
      } else if (_rows == 3 && _cols == 3) {
        final sample = [
          [2.0, 0.0, 0.0],
          [0.0, 3.0, 4.0],
          [0.0, 4.0, 9.0],
        ];
        _populateFromList(sample);
      } else {
        _fillIdentityLike();
      }
    }
  }

  void _fillIdentityLike() {
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        _controllers[r][c].text = (r == c ? '1' : '0');
      }
    }
  }

  void _clearAllCells() {
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        _controllers[r][c].text = '0';
      }
    }
    _clearResults();
  }

  void _populateFromList(List<List<double>> list) {
    for (int r = 0; r < _rows && r < list.length; r++) {
      for (int c = 0; c < _cols && c < list[r].length; c++) {
        final val = list[r][c];
        _controllers[r][c].text =
            val == val.roundToDouble() ? val.toInt().toString() : val.toString();
      }
    }
  }

  List<List<double>> _getMatrixValues() {
    return _controllers.map((row) {
      return row.map((ctrl) {
        final t = ctrl.text.trim();
        return double.tryParse(t) ?? 0.0;
      }).toList();
    }).toList();
  }

  void _solve() {
    FocusScope.of(context).unfocus();
    final matrix = _getMatrixValues();

    if (_currentMode == 0) {
      // Gauss Elimination
      final solver = GaussEliminationSolver(matrix);
      final steps = solver.solve();
      final vars = solver.solveVariables();
      setState(() {
        _gaussSteps = steps;
        _gaussVariables = vars;
      });
    } else if (_currentMode == 1) {
      // Matrix Inverse
      final solver = GaussJordanSolver(matrix);
      final steps = solver.solve();
      final inv = solver.getInverse();
      setState(() {
        _inverseSteps = steps;
        _inverseResult = inv;
        _isInverseSingular = solver.isSingular;
      });
    } else {
      // Eigenvalues & Eigenvectors
      final solver = EigenSolver(matrix);
      final res = solver.solve();
      setState(() {
        _eigenResult = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryColor;
    final cardBg = isDark
        ? const Color(0xFF251E4E).withOpacity(0.55)
        : Colors.white.withOpacity(0.85);
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : primaryColor.withOpacity(0.2);
    final textColor = isDark ? Colors.white : const Color(0xFF3D2F27);
    final subTextColor = isDark ? const Color(0xFFB8AEDB) : const Color(0xFF7A6456);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0C20) : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Matrix Solver',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              color: isDark ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            onPressed: () => _showHelpDialog(context, isDark),
            tooltip: 'About Solvers',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/darktheme_bg.png'),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              _buildHeaderBanner(isDark, primaryColor, cardBg, cardBorder, textColor, subTextColor),
              const SizedBox(height: 18),

              // Segmented Tab Selector (Gauss, Inverse, Eigen)
              _buildModeSelector(isDark, primaryColor, cardBg, cardBorder),
              const SizedBox(height: 20),

              // Dimension Selector & Preset Chips
              _buildDimensionAndPresetCard(isDark, primaryColor, cardBg, cardBorder, textColor),
              const SizedBox(height: 20),

              // Matrix Visual Input Grid (with brackets [ ])
              _buildMatrixInputCard(isDark, primaryColor, cardBg, cardBorder, textColor),
              const SizedBox(height: 20),

              // Action Buttons ("Solve Step-by-Step", "Sample", "Clear")
              _buildActionButtons(primaryColor, isDark),
              const SizedBox(height: 24),

              // Solution & Calculation Steps
              _buildResultsSection(isDark, primaryColor, cardBg, cardBorder, textColor, subTextColor),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Header Banner
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderBanner(
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color cardBorder,
    Color textColor,
    Color subTextColor,
  ) {
    return FadeInSlide(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.25) : primaryColor.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                isDark
                    ? 'assets/images/utilities/matrix_solver_dark.png'
                    : 'assets/images/utilities/matrix_solver_light.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Linear Algebra Solver',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Step-by-step row operations, echelon form, inverse, & eigenvalues.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subTextColor,
                      height: 1.3,
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

  // ─────────────────────────────────────────────────────────────────────────────
  // Segmented Mode Selector
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildModeSelector(
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color cardBorder,
  ) {
    final modes = [
      {'title': 'Gauss', 'sub': 'Elimination', 'icon': Icons.grid_view_rounded},
      {'title': 'Inverse', 'sub': 'Gauss-Jordan', 'icon': Icons.swap_horiz_rounded},
      {'title': 'Eigen', 'sub': 'λ & Vectors', 'icon': Icons.auto_awesome_rounded},
    ];

    return FadeInSlide(
      delay: const Duration(milliseconds: 100),
      duration: const Duration(milliseconds: 450),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder, width: 1.2),
        ),
        child: Row(
          children: List.generate(modes.length, (index) {
            final isSelected = _currentMode == index;
            final m = modes[index];
            return Expanded(
              child: GestureDetector(
                onTap: () => _onModeChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? primaryColor.withOpacity(0.22)
                            : primaryColor.withOpacity(0.16))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: primaryColor, width: 1.5)
                        : Border.all(color: Colors.transparent),
                    boxShadow: isSelected && !isDark
                        ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        m['icon'] as IconData,
                        size: 20,
                        color: isSelected
                            ? primaryColor
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m['title'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? (isDark ? Colors.white : primaryColor)
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      Text(
                        m['sub'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? primaryColor.withOpacity(0.85)
                              : (isDark ? Colors.white38 : Colors.black38),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Dimension and Preset Card
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildDimensionAndPresetCard(
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color cardBorder,
    Color textColor,
  ) {
    return FadeInSlide(
      delay: const Duration(milliseconds: 150),
      duration: const Duration(milliseconds: 450),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cardBorder, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Matrix Dimensions',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_rows × $_cols',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dimension Adjusters
            if (_currentMode == 0) ...[
              // Gauss allows independent Rows & Columns (augmented matrix)
              Row(
                children: [
                  Expanded(
                    child: _buildCounterRow('Rows', _rows, 2, 5, (val) {
                      setState(() => _initMatrix(val, _cols));
                    }, primaryColor, isDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCounterRow('Columns', _cols, 2, 6, (val) {
                      setState(() => _initMatrix(_rows, val));
                    }, primaryColor, isDark),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Preset chips for Gauss
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip('3×4 (System)', _rows == 3 && _cols == 4, () {
                      setState(() {
                        _initMatrix(3, 4);
                        _loadSampleData();
                      });
                    }, primaryColor, isDark),
                    const SizedBox(width: 8),
                    _buildPresetChip('2×3 (System)', _rows == 2 && _cols == 3, () {
                      setState(() {
                        _initMatrix(2, 3);
                        _loadSampleData();
                      });
                    }, primaryColor, isDark),
                    const SizedBox(width: 8),
                    _buildPresetChip('3×3 (Square)', _rows == 3 && _cols == 3, () {
                      setState(() {
                        _initMatrix(3, 3);
                        _loadSampleData();
                      });
                    }, primaryColor, isDark),
                    const SizedBox(width: 8),
                    _buildPresetChip('4×4 (Square)', _rows == 4 && _cols == 4, () {
                      setState(() {
                        _initMatrix(4, 4);
                        _loadSampleData();
                      });
                    }, primaryColor, isDark),
                  ],
                ),
              ),
            ] else if (_currentMode == 1) ...[
              // Inverse requires Square Matrix
              Row(
                children: [
                  Expanded(
                    child: _buildCounterRow('Size (N×N)', _rows, 2, 4, (val) {
                      setState(() => _initMatrix(val, val));
                    }, primaryColor, isDark),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip('2×2 Matrix', _rows == 2, () {
                      setState(() {
                        _initMatrix(2, 2);
                        _loadSampleData();
                      });
                    }, primaryColor, isDark),
                    const SizedBox(width: 8),
                    _buildPresetChip('3×3 Matrix', _rows == 3, () {
                      setState(() {
                        _initMatrix(3, 3);
                        _loadSampleData();
                      });
                    }, primaryColor, isDark),
                    const SizedBox(width: 8),
                    _buildPresetChip('4×4 Matrix', _rows == 4, () {
                      setState(() {
                        _initMatrix(4, 4);
                        _loadSampleData();
                      });
                    }, primaryColor, isDark),
                  ],
                ),
              ),
            ] else ...[
              // Eigenvalues requires Square Matrix (2x2 or 3x3)
              Row(
                children: [
                  Expanded(
                    child: _buildCounterRow('Size (N×N)', _rows, 2, 3, (val) {
                      setState(() => _initMatrix(val, val));
                    }, primaryColor, isDark),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip('2×2 (Analytic Quadratic)', _rows == 2, () {
                      setState(() {
                        _initMatrix(2, 2);
                        _loadSampleData();
                      });
                    }, primaryColor, isDark),
                    const SizedBox(width: 8),
                    _buildPresetChip('3×3 (Characteristic Invariants)', _rows == 3, () {
                      setState(() {
                        _initMatrix(3, 3);
                        _loadSampleData();
                      });
                    }, primaryColor, isDark),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
    Color primaryColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniIconButton(Icons.remove, value > min ? () => onChanged(value - 1) : null, isDark),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Text(
                  '$value',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              _buildMiniIconButton(Icons.add, value < max ? () => onChanged(value + 1) : null, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniIconButton(IconData icon, VoidCallback? onPressed, bool isDark) {
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: enabled
              ? (isDark ? Colors.white.withOpacity(0.1) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled
                ? (isDark ? Colors.white24 : Colors.black12)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled
              ? (isDark ? Colors.white : Colors.black87)
              : (isDark ? Colors.white24 : Colors.black26),
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color primaryColor,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.18)
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Matrix Visual Input Grid (with Brackets [ ])
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildMatrixInputCard(
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color cardBorder,
    Color textColor,
  ) {
    return FadeInSlide(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 450),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.2) : primaryColor.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _currentMode == 0 && _cols == _rows + 1
                        ? 'Augmented Matrix [A | B]'
                        : 'Input Matrix A',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tap cell to edit',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mathematical Bracket Frame
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Bracket [
                      _buildMatrixBracket(isLeft: true, primaryColor: primaryColor),
                      const SizedBox(width: 6),

                      // Matrix Grid
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_rows, (r) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(_cols, (c) {
                                final isAugmentedDivider =
                                    (_currentMode == 0 && _cols == _rows + 1 && c == _cols - 1);
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isAugmentedDivider)
                                      Container(
                                        width: 2,
                                        height: 38,
                                        margin: const EdgeInsets.symmetric(horizontal: 6),
                                        color: primaryColor.withOpacity(0.6),
                                      ),
                                    Container(
                                      width: 58,
                                      height: 46,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E193C)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white12
                                              : primaryColor.withOpacity(0.25),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: _controllers[r][c],
                                        keyboardType: const TextInputType.numberWithOptions(
                                          decimal: true,
                                          signed: true,
                                        ),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          isDense: true,
                                        ),
                                        onChanged: (_) {
                                          _clearResults();
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(width: 6),
                      // Right Bracket ]
                      _buildMatrixBracket(isLeft: false, primaryColor: primaryColor),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixBracket({required bool isLeft, required Color primaryColor}) {
    return Container(
      height: (_rows * 54.0).clamp(60.0, 300.0),
      width: 10,
      decoration: BoxDecoration(
        border: Border(
          left: isLeft ? BorderSide(color: primaryColor, width: 2.5) : BorderSide.none,
          right: !isLeft ? BorderSide(color: primaryColor, width: 2.5) : BorderSide.none,
          top: BorderSide(color: primaryColor, width: 2.5),
          bottom: BorderSide(color: primaryColor, width: 2.5),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Action Buttons
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildActionButtons(Color primaryColor, bool isDark) {
    return FadeInSlide(
      delay: const Duration(milliseconds: 250),
      duration: const Duration(milliseconds: 450),
      child: Column(
        children: [
          // Primary Solve Button
          ElevatedButton(
            onPressed: _solve,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: isDark ? const Color(0xFF171330) : Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              shadowColor: primaryColor.withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFF171330) : Colors.white,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Solve Step-by-Step',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Quick Actions (Load Sample & Clear)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadSampleData,
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('Load Sample'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor.withOpacity(0.35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearAllCells,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Clear All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.black54,
                    side: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Results and Steps Section
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildResultsSection(
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color cardBorder,
    Color textColor,
    Color subTextColor,
  ) {
    if (_currentMode == 0) {
      if (_gaussSteps == null) {
        return _buildEmptyState(
          'Enter coefficients above and tap "Solve Step-by-Step"',
          isDark,
          primaryColor,
        );
      }
      return _buildGaussResults(isDark, primaryColor, cardBg, cardBorder, textColor, subTextColor);
    } else if (_currentMode == 1) {
      if (_inverseSteps == null) {
        return _buildEmptyState(
          'Enter matrix values to compute inverse [A⁻¹] step-by-step',
          isDark,
          primaryColor,
        );
      }
      return _buildInverseResults(isDark, primaryColor, cardBg, cardBorder, textColor, subTextColor);
    } else {
      if (_eigenResult == null) {
        return _buildEmptyState(
          'Enter square matrix values to compute eigenvalues & eigenvectors',
          isDark,
          primaryColor,
        );
      }
      return _buildEigenResults(isDark, primaryColor, cardBg, cardBorder, textColor, subTextColor);
    }
  }

  Widget _buildEmptyState(String message, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.calculate_outlined,
            size: 40,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Gauss Elimination Results
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildGaussResults(
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color cardBorder,
    Color textColor,
    Color subTextColor,
  ) {
    final finalMatrix = _gaussSteps!.last.matrix;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Final Solution Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: primaryColor, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Row Echelon Form',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_gaussSteps!.length} Steps',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Final Matrix Table
              Center(
                child: _buildFormattedMatrix(finalMatrix, isDark, primaryColor),
              ),

              // Augmented System Solved Variables (x, y, z...)
              if (_gaussVariables != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Solved System Variables:',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: List.generate(_gaussVariables!.length, (i) {
                    final names = ['x', 'y', 'z', 'w', 'v'];
                    final varName = i < names.length ? names[i] : 'x${i + 1}';
                    final val = _gaussVariables![i];
                    final strVal =
                        val == val.roundToDouble() ? val.toInt().toString() : val.toStringAsFixed(3);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        '$varName = $strVal',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : primaryColor,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Steps Title
        Text(
          'Step-by-Step Row Reductions',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        // Steps List
        ...List.generate(_gaussSteps!.length, (index) {
          final step = _gaussSteps![index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step.operation,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (step.description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    step.description!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subTextColor,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Center(
                  child: _buildFormattedMatrix(step.matrix, isDark, primaryColor),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. Matrix Inverse Results
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildInverseResults(
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color cardBorder,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Inverse Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _isInverseSingular ? Colors.redAccent : primaryColor,
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isInverseSingular ? Colors.redAccent : primaryColor).withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _isInverseSingular ? 'Matrix is Singular' : 'Inverse Matrix [A⁻¹]',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _isInverseSingular ? Colors.redAccent : primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_isInverseSingular ? Colors.redAccent : primaryColor).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _isInverseSingular ? 'Non-Invertible' : 'Invertible (det ≠ 0)',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _isInverseSingular ? Colors.redAccent : primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isInverseSingular) ...[
                Text(
                  'The determinant of matrix A is zero (det(A) = 0). The row reduction produced a zero pivot on the diagonal, which means no inverse matrix exists.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ] else if (_inverseResult != null) ...[
                Center(
                  child: _buildFormattedMatrix(_inverseResult!, isDark, primaryColor),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Steps Title
        Text(
          'Gauss-Jordan Operations [A | I]',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        ...List.generate(_inverseSteps!.length, (index) {
          final step = _inverseSteps![index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step.operation,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (step.description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    step.description!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subTextColor,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Side-by-side Augmented Matrix [A | I]
                Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFormattedMatrix(step.matrix, isDark, primaryColor),
                        Container(
                          width: 2,
                          height: step.matrix.length * 28.0 + 16,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: primaryColor.withOpacity(0.4),
                        ),
                        _buildFormattedMatrix(step.identity, isDark, Colors.teal),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. Eigenvalues & Eigenvectors Results
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildEigenResults(
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color cardBorder,
    Color textColor,
    Color subTextColor,
  ) {
    final res = _eigenResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: primaryColor, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Eigenvalues & Eigenvectors',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 14),

              if (res.eigenvalues.isEmpty) ...[
                Text(
                  'No real eigenvalues found.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ] else ...[
                ...List.generate(res.eigenvalues.length, (i) {
                  final lambda = res.eigenvalues[i];
                  final lambdaStr = lambda.isNaN
                      ? 'Complex / NaN'
                      : (lambda == lambda.roundToDouble()
                          ? lambda.toInt().toString()
                          : lambda.toStringAsFixed(4));

                  List<double>? vec = i < res.eigenvectors.length ? res.eigenvectors[i] : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'λ${i + 1}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? const Color(0xFF171330) : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '=  $lambdaStr',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        if (vec != null && !vec.any((e) => e.isNaN)) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Eigenvector v${i + 1}:  ',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: subTextColor,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '[ ${vec.map((v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(3)).join(' , ')} ]ᵀ',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: primaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Steps Title
        Text(
          'Derivation & Algebraic Steps',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        ...List.generate(res.steps.length, (index) {
          final step = res.steps[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  step.description,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subTextColor,
                    height: 1.4,
                  ),
                ),
                if (step.matrix != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: _buildFormattedMatrix(step.matrix!, isDark, primaryColor),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Formatted Matrix Display Helper
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildFormattedMatrix(
    List<List<double>> matrix,
    bool isDark,
    Color primaryColor,
  ) {
    if (matrix.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16122C) : const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left Bracket
            Container(
              height: matrix.length * 30.0 + 8,
              width: 6,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: primaryColor, width: 2),
                  top: BorderSide(color: primaryColor, width: 2),
                  bottom: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Rows & Cols
            Column(
              mainAxisSize: MainAxisSize.min,
              children: matrix.map((row) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: row.map((cell) {
                      final valStr = cell.isNaN
                          ? 'NaN'
                          : (cell == cell.roundToDouble()
                              ? cell.toInt().toString()
                              : cell.toStringAsFixed(2));
                      return Container(
                        width: 52,
                        alignment: Alignment.center,
                        child: Text(
                          valStr,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF2A221C),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(width: 8),
            // Right Bracket
            Container(
              height: matrix.length * 30.0 + 8,
              width: 6,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: primaryColor, width: 2),
                  top: BorderSide(color: primaryColor, width: 2),
                  bottom: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Help Dialog
  // ─────────────────────────────────────────────────────────────────────────────
  void _showHelpDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.school_rounded, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 10),
              Text(
                'Matrix Solver Guide',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  '1. Gauss Elimination',
                  'Transforms a matrix into Row Echelon Form using elementary row operations (row swaps, scaling, and elimination). For augmented systems (e.g. 3×4), it solves for variables x, y, z through back substitution.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  '2. Matrix Inverse [A⁻¹]',
                  'Applies Gauss-Jordan elimination on [A | I] to transform the left side into Identity [I | A⁻¹]. If determinant is 0, the matrix is flagged as singular.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  '3. Eigenvalues & Eigenvectors',
                  'Computes characteristic polynomial det(A - λI) = 0 using trace and minors, derives eigenvalues λ, and performs row reduction on (A - λI)v = 0 to calculate eigenvectors.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Got It',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: GoogleFonts.outfit(fontSize: 12, height: 1.35, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
