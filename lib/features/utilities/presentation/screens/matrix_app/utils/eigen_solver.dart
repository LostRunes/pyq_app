import 'dart:math';

class EigenStep {
  final String title;
  final String operation;
  final String description;
  final List<List<double>>? matrix;

  EigenStep({
    required this.title,
    required this.operation,
    required this.description,
    this.matrix,
  });
}

class EigenResult {
  final List<double> eigenvalues;
  final List<List<double>> eigenvectors;
  final List<EigenStep> steps;

  EigenResult(this.eigenvalues, this.eigenvectors, this.steps);
}

class EigenSolver {
  final List<List<double>> matrix;

  EigenSolver(this.matrix);

  EigenResult solve({int maxIterations = 150, double tolerance = 1e-9}) {
    int n = matrix.length;
    if (n == 0) return EigenResult([], [], []);

    List<EigenStep> steps = [];
    List<double> eigenvalues = [];
    List<List<double>> eigenvectors = [];

    // Step 0: Initial matrix display
    steps.add(EigenStep(
      title: "Initial Matrix A",
      operation: "Input Matrix",
      description: "We want to find eigenvalues and eigenvectors for matrix A of size $n × $n.",
      matrix: _deepCopy(matrix),
    ));

    if (n == 2) {
      _solve2x2(steps, eigenvalues);
    } else if (n == 3) {
      _solve3x3(steps, eigenvalues);
    } else {
      _solveLarge(steps, eigenvalues, maxIterations, tolerance);
    }

    // For each eigenvalue, find the eigenvector using step-by-step row reduction
    for (int i = 0; i < eigenvalues.length; i++) {
      double lambda = eigenvalues[i];
      if (lambda.isNaN || lambda.isInfinite) {
        eigenvectors.add(List.filled(n, double.nan));
        continue;
      }
      var vector = _findEigenvectorStepByStep(steps, lambda, i + 1);
      eigenvectors.add(vector);
    }

    return EigenResult(eigenvalues, eigenvectors, steps);
  }

  void _solve2x2(List<EigenStep> steps, List<double> eigenvalues) {
    double a = matrix[0][0];
    double b = matrix[0][1];
    double c = matrix[1][0];
    double d = matrix[1][1];

    steps.add(EigenStep(
      title: "Step 1: Characteristic Matrix",
      operation: "Form A - λI",
      description: "Substitute values into the characteristic matrix:\n"
          "| a - λ   b |\n"
          "|   c   d - λ |\n\n"
          "This yields:\n"
          "| ${a.toStringAsFixed(2)} - λ   ${b.toStringAsFixed(2)} |\n"
          "| ${c.toStringAsFixed(2)}   ${d.toStringAsFixed(2)} - λ |",
    ));

    double trace = a + d;
    double det = a * d - b * c;

    steps.add(EigenStep(
      title: "Step 2: Characteristic Equation",
      operation: "det(A - λI) = 0",
      description: "Compute the determinant of the characteristic matrix:\n"
          "det(A - λI) = (a - λ)(d - λ) - bc = 0\n"
          "det(A - λI) = λ² - (a + d)λ + (ad - bc) = 0\n\n"
          "Substitute trace = a + d = ${trace.toStringAsFixed(2)} and determinant = ad - bc = ${det.toStringAsFixed(2)}:\n"
          "λ² - (${trace.toStringAsFixed(2)})λ + (${det.toStringAsFixed(2)}) = 0",
    ));

    double discriminant = trace * trace - 4 * det;

    steps.add(EigenStep(
      title: "Step 3: Solve Characteristic Equation",
      operation: "Quadratic Formula",
      description: "Solve λ² - ${trace.toStringAsFixed(2)}λ + ${det.toStringAsFixed(2)} = 0 using the quadratic formula:\n"
          "λ = [ -b ± √(b² - 4ac) ] / 2a\n"
          "λ = [ ${trace.toStringAsFixed(2)} ± √(${trace.toStringAsFixed(2)}² - 4(1)(${det.toStringAsFixed(2)})) ] / 2\n"
          "λ = [ ${trace.toStringAsFixed(2)} ± √(${discriminant.toStringAsFixed(4)}) ] / 2",
    ));

    if (discriminant < 0) {
      double realPart = trace / 2.0;
      double imagPart = sqrt(-discriminant) / 2.0;
      steps.add(EigenStep(
        title: "Step 4: Eigenvalues Found (Complex)",
        operation: "Complex Roots",
        description: "Discriminant is negative, yielding complex conjugate eigenvalues:\n"
            "λ₁ = ${realPart.toStringAsFixed(4)} + ${imagPart.toStringAsFixed(4)}i\n"
            "λ₂ = ${realPart.toStringAsFixed(4)} - ${imagPart.toStringAsFixed(4)}i\n\n"
            "Note: Complex eigenvalues are not fully supported for real eigenvector calculations.",
      ));
      eigenvalues.add(double.nan);
      eigenvalues.add(double.nan);
    } else {
      double l1 = (trace + sqrt(discriminant)) / 2.0;
      double l2 = (trace - sqrt(discriminant)) / 2.0;

      // Clean up floating point errors (e.g. 2.0000000001 -> 2.0)
      if ((l1 - l1.roundToDouble()).abs() < 1e-9) l1 = l1.roundToDouble();
      if ((l2 - l2.roundToDouble()).abs() < 1e-9) l2 = l2.roundToDouble();

      eigenvalues.add(l1);
      eigenvalues.add(l2);

      steps.add(EigenStep(
        title: "Step 4: Eigenvalues Found",
        operation: "Real Roots",
        description: "Solving the quadratic equation gives two real eigenvalues:\n"
            "λ₁ = ${l1.toStringAsFixed(4)}\n"
            "λ₂ = ${l2.toStringAsFixed(4)}",
      ));
    }
  }

  void _solve3x3(List<EigenStep> steps, List<double> eigenvalues) {
    double a11 = matrix[0][0];
    double a12 = matrix[0][1];
    double a13 = matrix[0][2];
    double a21 = matrix[1][0];
    double a22 = matrix[1][1];
    double a23 = matrix[1][2];
    double a31 = matrix[2][0];
    double a32 = matrix[2][1];
    double a33 = matrix[2][2];

    steps.add(EigenStep(
      title: "Step 1: Characteristic Equation Form",
      operation: "det(A - λI) = 0",
      description: "For a 3x3 matrix, the characteristic equation is:\n"
          "λ³ - I₁λ² + I₂λ - I₃ = 0\n"
          "where:\n"
          "  I₁ = Trace of A\n"
          "  I₂ = Sum of principal minors of A\n"
          "  I₃ = Determinant of A",
    ));

    // Calculate i1 (Trace)
    double i1 = a11 + a22 + a33;
    
    // Calculate i2 (Sum of principal minors)
    double m11 = a22 * a33 - a23 * a32;
    double m22 = a11 * a33 - a13 * a31;
    double m33 = a11 * a22 - a12 * a21;
    double i2 = m11 + m22 + m33;

    // Calculate i3 (Determinant)
    double i3 = a11 * (a22 * a33 - a23 * a32) -
        a12 * (a21 * a33 - a23 * a31) +
        a13 * (a21 * a32 - a22 * a31);

    steps.add(EigenStep(
      title: "Step 2: Compute Invariants (I₁, I₂, I₃)",
      operation: "Compute coefficients",
      description: "1. Trace (I₁):\n"
          "   I₁ = ${a11.toStringAsFixed(2)} + ${a22.toStringAsFixed(2)} + ${a33.toStringAsFixed(2)} = ${i1.toStringAsFixed(4)}\n\n"
          "2. Sum of Principal Minors (I₂):\n"
          "   M₁₁ = ${a22.toStringAsFixed(2)}×${a33.toStringAsFixed(2)} - ${a23.toStringAsFixed(2)}×${a32.toStringAsFixed(2)} = ${m11.toStringAsFixed(4)}\n"
          "   M₂₂ = ${a11.toStringAsFixed(2)}×${a33.toStringAsFixed(2)} - ${a13.toStringAsFixed(2)}×${a31.toStringAsFixed(2)} = ${m22.toStringAsFixed(4)}\n"
          "   M₃₃ = ${a11.toStringAsFixed(2)}×${a22.toStringAsFixed(2)} - ${a12.toStringAsFixed(2)}×${a21.toStringAsFixed(2)} = ${m33.toStringAsFixed(4)}\n"
          "   I₂ = M₁₁ + M₂₂ + M₃₃ = ${i2.toStringAsFixed(4)}\n\n"
          "3. Determinant (I₃):\n"
          "   I₃ = det(A) = ${i3.toStringAsFixed(4)}",
    ));

    steps.add(EigenStep(
      title: "Step 3: Characteristic Polynomial",
      operation: "Form Cubic Equation",
      description: "Substitute I₁, I₂, and I₃ into the characteristic equation:\n"
          "λ³ - (${i1.toStringAsFixed(4)})λ² + (${i2.toStringAsFixed(4)})λ - (${i3.toStringAsFixed(4)}) = 0",
    ));

    // Solve cubic equation analytically using trigonometric method
    // cubic form: x^3 + px^2 + qx + r = 0
    double p = -i1;
    double q = i2;
    double r = -i3;

    List<double> roots = _solveCubic(p, q, r);

    if (roots.isEmpty) {
      steps.add(EigenStep(
        title: "Step 4: Solve Cubic Equation",
        operation: "No Real Roots Found",
        description: "Solving the cubic equation did not yield real roots. Complex eigenvalues are not fully supported.",
      ));
      eigenvalues.addAll([double.nan, double.nan, double.nan]);
    } else if (roots.length == 1) {
      double l = roots[0];
      if ((l - l.roundToDouble()).abs() < 1e-9) l = l.roundToDouble();
      eigenvalues.addAll([l, double.nan, double.nan]);
      steps.add(EigenStep(
        title: "Step 4: Solve Cubic Equation",
        operation: "One Real Root Found",
        description: "Solving the cubic equation yields one real root (and a complex conjugate pair):\n"
            "λ₁ = ${l.toStringAsFixed(4)}",
      ));
    } else {
      for (int i = 0; i < roots.length; i++) {
        double l = roots[i];
        if ((l - l.roundToDouble()).abs() < 1e-9) l = l.roundToDouble();
        roots[i] = l;
      }
      // sort eigenvalues descending
      roots.sort((a, b) => b.compareTo(a));
      eigenvalues.addAll(roots);

      steps.add(EigenStep(
        title: "Step 4: Solve Cubic Equation",
        operation: "Three Real Roots Found",
        description: "Solving the cubic equation yields three real roots:\n"
            "λ₁ = ${roots[0].toStringAsFixed(4)}\n"
            "λ₂ = ${roots[1].toStringAsFixed(4)}\n"
            "λ₃ = ${roots[2].toStringAsFixed(4)}",
      ));
    }
  }

  void _solveLarge(List<EigenStep> steps, List<double> eigenvalues, int maxIterations, double tolerance) {
    int n = matrix.length;
    steps.add(EigenStep(
      title: "Step 1: Large Matrix Solver",
      operation: "QR Decomposition Iteration",
      description: "For matrices of size 4x4 or larger, an analytical characteristic polynomial is too complex. "
          "Instead, we use QR iteration to numerically find all eigenvalues to a high precision.",
    ));

    List<List<double>> A = _deepCopy(matrix);
    int iterationsCount = 0;
    for (int iter = 0; iter < maxIterations; iter++) {
      var qr = _qrDecomposition(A);
      var Q = qr['Q']!;
      var R = qr['R']!;
      A = _multiply(R, Q);
      iterationsCount++;
      if (_isConverged(A, tolerance)) break;
    }

    for (int i = 0; i < n; i++) {
      double l = A[i][i];
      if ((l - l.roundToDouble()).abs() < 1e-9) l = l.roundToDouble();
      eigenvalues.add(l);
    }
    // Sort descending
    eigenvalues.sort((a, b) => b.compareTo(a));

    steps.add(EigenStep(
      title: "Step 2: QR Convergence Result",
      operation: "Eigenvalues Solved",
      description: "The QR iteration converged in $iterationsCount iterations. The approximate eigenvalues are:\n"
          "${eigenvalues.asMap().entries.map((e) => "λ${e.key + 1} = ${e.value.toStringAsFixed(4)}").join("\n")}",
    ));
  }

  List<double> _findEigenvectorStepByStep(List<EigenStep> steps, double lambda, int idx) {
    int n = matrix.length;
    
    // Create B = A - lambda*I
    List<List<double>> B = List.generate(n, (i) =>
        List.generate(n, (j) => matrix[i][j] - (i == j ? lambda : 0)));

    steps.add(EigenStep(
      title: "Eigenvector for λ$idx = ${lambda.toStringAsFixed(4)}",
      operation: "Form A - λI",
      description: "Substitute λ$idx = ${lambda.toStringAsFixed(4)} into the characteristic matrix:\n"
          "We want to solve the homogeneous system (A - λ$idx I)v = 0.",
      matrix: _deepCopy(B),
    ));

    // Reduce to RREF
    List<List<double>> rref = _deepCopy(B);
    List<int> pivotCols = [];
    int r = 0;

    for (int c = 0; c < n; c++) {
      int pivotRow = r;
      double maxVal = r < n ? rref[r][c].abs() : 0;
      for (int i = r + 1; i < n; i++) {
        if (rref[i][c].abs() > maxVal) {
          maxVal = rref[i][c].abs();
          pivotRow = i;
        }
      }

      if (r >= n || maxVal < 1e-6) {
        // No pivot in this column, it corresponds to a free variable
        continue;
      }

      if (pivotRow != r) {
        var temp = rref[r];
        rref[r] = rref[pivotRow];
        rref[pivotRow] = temp;
        steps.add(EigenStep(
          title: "Eigenvector for λ$idx: Row Swap",
          operation: "Swap R${r + 1} ↔ R${pivotRow + 1}",
          description: "Swap Row ${r + 1} and Row ${pivotRow + 1} to position a larger pivot on the diagonal.",
          matrix: _deepCopy(rref),
        ));
      }

      double pivot = rref[r][c];
      for (int j = c; j < n; j++) {
        rref[r][j] /= pivot;
      }
      steps.add(EigenStep(
        title: "Eigenvector for λ$idx: Pivot Normalization",
        operation: "R${r + 1} → R${r + 1} ÷ ${pivot.toStringAsFixed(2)}",
        description: "Normalize the pivot element in column ${c + 1} to 1.0.",
        matrix: _deepCopy(rref),
      ));

      for (int i = 0; i < n; i++) {
        if (i != r && rref[i][c].abs() > 1e-6) {
          double factor = rref[i][c];
          for (int j = c; j < n; j++) {
            rref[i][j] -= factor * rref[r][j];
          }
          steps.add(EigenStep(
            title: "Eigenvector for λ$idx: Row Elimination",
            operation: "R${i + 1} → R${i + 1} - ${factor.toStringAsFixed(2)} × R${r + 1}",
            description: "Eliminate element in row ${i + 1}, column ${c + 1}.",
            matrix: _deepCopy(rref),
          ));
        }
      }
      pivotCols.add(c);
      r++;
    }

    // Solve the RREF system
    List<double> x = List.filled(n, 0);
    int freeCol = -1;

    for (int c = 0; c < n; c++) {
      if (!pivotCols.contains(c)) {
        freeCol = c;
        break;
      }
    }

    if (freeCol != -1) {
      x[freeCol] = 1.0;
      for (int i = 0; i < pivotCols.length; i++) {
        int pCol = pivotCols[i];
        x[pCol] = -rref[i][freeCol];
      }
      steps.add(EigenStep(
        title: "Eigenvector for λ$idx: Solve Free Variable",
        operation: "Set free variable x${freeCol + 1} = 1.0",
        description: "The column ${freeCol + 1} has no pivot, indicating a free variable. "
            "Setting x${freeCol + 1} = 1.0 and back-substituting to solve for other variables.",
      ));
    } else {
      // Numerical fallback if no free column detected
      x[n - 1] = 1.0;
      for (int i = 0; i < n - 1; i++) {
        x[i] = -rref[i][n - 1];
      }
      steps.add(EigenStep(
        title: "Eigenvector for λ$idx: Numerical Fallback",
        operation: "Set x$n = 1.0",
        description: "Due to numerical precision, a clean free variable column was not isolated. "
            "Assuming x$n = 1.0 to find a non-zero eigenvector direction.",
      ));
    }

    // Simplify/Unnormalize Vector (Find nice integers)
    var simplifiedVec = _simplifyVector(x);

    steps.add(EigenStep(
      title: "Eigenvector for λ$idx: Simplification",
      operation: "Simplify Vector Ratio",
      description: "Scale the raw eigenvector to the simplest integer/fraction form for standard exam presentation:\n"
          "Raw: [${x.map((v) => v.toStringAsFixed(4)).join(', ')}]ᵀ\n"
          "Simplified: [${simplifiedVec.map((v) => v.toStringAsFixed(0)).join(', ')}]ᵀ",
    ));

    return simplifiedVec;
  }

  List<double> _simplifyVector(List<double> vec) {
    int n = vec.length;
    if (vec.every((x) => x.abs() < 1e-6)) return vec;

    double minVal = double.infinity;
    for (var val in vec) {
      if (val.abs() > 1e-6 && val.abs() < minVal) {
        minVal = val.abs();
      }
    }

    List<double> normalized = vec.map((x) => x / minVal).toList();

    for (int k = 1; k <= 20; k++) {
      bool allIntegers = true;
      List<double> candidate = [];
      for (int i = 0; i < n; i++) {
        double scaled = normalized[i] * k;
        double rounded = scaled.roundToDouble();
        if ((scaled - rounded).abs() > 1e-2) {
          allIntegers = false;
          break;
        }
        candidate.add(rounded);
      }
      if (allIntegers) {
        double gcdVal = _gcdOfList(candidate.map((x) => x.abs().round()).toList()).toDouble();
        if (gcdVal > 0) {
          candidate = candidate.map((x) => x / gcdVal).toList();
        }
        double firstNonZero = candidate.firstWhere((x) => x.abs() > 1e-6, orElse: () => 0.0);
        if (firstNonZero < 0) {
          candidate = candidate.map((x) => -x).toList();
        }
        return candidate;
      }
    }

    double firstNonZero = vec.firstWhere((x) => x.abs() > 1e-6, orElse: () => 0.0);
    if (firstNonZero != 0) {
      var result = vec.map((x) => x / firstNonZero).toList();
      return result.map((x) => (x * 10000).round() / 10000.0).toList();
    }
    return vec;
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      var t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  int _gcdOfList(List<int> numbers) {
    if (numbers.isEmpty) return 1;
    int result = numbers[0];
    for (int i = 1; i < numbers.length; i++) {
      result = _gcd(result, numbers[i]);
    }
    return result;
  }

  List<double> _solveCubic(double p, double q, double r) {
    double a = (3.0 * q - p * p) / 3.0;
    double b = (2.0 * p * p * p - 9.0 * p * q + 27.0 * r) / 27.0;

    double discriminant = (b * b) / 4.0 + (a * a * a) / 27.0;

    List<double> roots = [];

    if (discriminant <= 1e-9) {
      if (a.abs() < 1e-9) {
        double y = -_cbrt(b);
        roots.add(y - p / 3.0);
        roots.add(y - p / 3.0);
        roots.add(y - p / 3.0);
      } else {
        double cosTheta = -b / (2.0 * sqrt(-a * a * a / 27.0));
        cosTheta = cosTheta.clamp(-1.0, 1.0);
        double theta = acos(cosTheta);
        double factor = 2.0 * sqrt(-a / 3.0);
        for (int k = 0; k < 3; k++) {
          double y = factor * cos((theta + 2.0 * k * pi) / 3.0);
          roots.add(y - p / 3.0);
        }
      }
    } else {
      double u = -b / 2.0;
      double sqrtD = sqrt(discriminant);
      double r1 = u + sqrtD;
      double r2 = u - sqrtD;
      double y = _cbrt(r1) + _cbrt(r2);
      roots.add(y - p / 3.0);
    }

    roots.sort();
    return roots;
  }

  double _cbrt(double x) {
    if (x < 0) {
      return -pow(-x, 1.0 / 3.0).toDouble();
    } else {
      return pow(x, 1.0 / 3.0).toDouble();
    }
  }

  bool _isConverged(List<List<double>> A, double tol) {
    int n = A.length;
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (i != j && A[i][j].abs() > tol) return false;
      }
    }
    return true;
  }

  Map<String, List<List<double>>> _qrDecomposition(List<List<double>> A) {
    int n = A.length;
    List<List<double>> Q = _identity(n);
    List<List<double>> R = _deepCopy(A);

    for (int k = 0; k < n - 1; k++) {
      double norm = 0;
      for (int i = k; i < n; i++) {
        norm += R[i][k] * R[i][k];
      }
      norm = sqrt(norm);
      if (norm == 0) continue;
      if (R[k][k] < 0) norm = -norm;

      List<double> v = List.filled(n, 0);
      for (int i = 0; i < n; i++) {
        if (i < k) {
          v[i] = 0;
        } else if (i == k) {
          v[i] = R[i][k] + norm;
        } else {
          v[i] = R[i][k];
        }
      }

      double vnorm = sqrt(v.map((x) => x * x).reduce((a, b) => a + b));
      if (vnorm > 1e-12) {
        for (int i = 0; i < n; i++) {
          v[i] /= vnorm;
        }
      }

      List<List<double>> H = _identity(n);
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          H[i][j] -= 2 * v[i] * v[j];
        }
      }

      R = _multiply(H, R);
      Q = _multiply(Q, H);
    }

    return {'Q': Q, 'R': R};
  }

  List<List<double>> _deepCopy(List<List<double>> m) =>
      m.map((row) => List<double>.from(row)).toList();

  List<List<double>> _identity(int n) =>
      List.generate(n, (i) => List.generate(n, (j) => i == j ? 1.0 : 0.0));

  List<List<double>> _multiply(List<List<double>> A, List<List<double>> B) {
    int n = A.length;
    int m = B[0].length;
    int p = B.length;
    List<List<double>> C = List.generate(n, (_) => List.filled(m, 0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < m; j++) {
        for (int k = 0; k < p; k++) {
          C[i][j] += A[i][k] * B[k][j];
        }
      }
    }
    return C;
  }
}
