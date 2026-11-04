class MatrixStep {
  final List<List<double>> matrix;
  final String operation;
  final String? description;

  MatrixStep(this.matrix, this.operation, {this.description});
}

class GaussEliminationSolver {
  final List<List<double>> inputMatrix;
  final List<MatrixStep> steps = [];

  GaussEliminationSolver(this.inputMatrix);

  List<MatrixStep> solve() {
    List<List<double>> matrix = _deepCopy(inputMatrix);
    int n = matrix.length;
    if (n == 0) return steps;
    int m = matrix[0].length;

    steps.add(MatrixStep(
      _deepCopy(matrix),
      "Initial Matrix",
      description: "Starting augmented/coefficient matrix ($n × $m).",
    ));

    int lead = 0;
    for (int r = 0; r < n; r++) {
      if (lead >= m) break;
      int i = r;
      while (i < n && matrix[i][lead].abs() < 1e-9) {
        i++;
      }

      if (i == n) {
        lead++;
        r--;
        continue;
      }

      if (i != r) {
        var temp = matrix[r];
        matrix[r] = matrix[i];
        matrix[i] = temp;
        steps.add(MatrixStep(
          _deepCopy(matrix),
          "Swap R${r + 1} ↔ R${i + 1}",
          description: "Swapped row ${r + 1} with row ${i + 1} to position a non-zero pivot at column ${lead + 1}.",
        ));
      }

      double pivot = matrix[r][lead];
      for (int k = r + 1; k < n; k++) {
        if (matrix[k][lead].abs() > 1e-9) {
          double factor = matrix[k][lead] / pivot;
          for (int c = lead; c < m; c++) {
            matrix[k][c] -= factor * matrix[r][c];
            if (matrix[k][c].abs() < 1e-9) matrix[k][c] = 0.0;
          }
          steps.add(MatrixStep(
            _deepCopy(matrix),
            "R${k + 1} → R${k + 1} - (${factor.toStringAsFixed(2)}) × R${r + 1}",
            description: "Eliminated coefficient in row ${k + 1}, column ${lead + 1}.",
          ));
        }
      }
      lead++;
    }

    return steps;
  }

  /// Solves for unknowns if the matrix represents an augmented system (m == n + 1)
  List<double>? solveVariables() {
    int n = inputMatrix.length;
    if (n == 0) return null;
    int m = inputMatrix[0].length;
    if (m != n + 1) return null;

    if (steps.isEmpty) solve();
    if (steps.isEmpty) return null;

    List<List<double>> finalMatrix = _deepCopy(steps.last.matrix);
    List<double> solution = List.filled(n, 0.0);

    for (int i = n - 1; i >= 0; i--) {
      double sum = finalMatrix[i][m - 1];
      for (int j = i + 1; j < n; j++) {
        sum -= finalMatrix[i][j] * solution[j];
      }
      double diag = finalMatrix[i][i];
      if (diag.abs() < 1e-9) {
        if (sum.abs() < 1e-9) {
          solution[i] = 0.0; // Free variable
        } else {
          return null; // Inconsistent system
        }
      } else {
        double val = sum / diag;
        if ((val - val.roundToDouble()).abs() < 1e-7) {
          val = val.roundToDouble();
        }
        solution[i] = val;
      }
    }
    return solution;
  }

  List<List<double>> _deepCopy(List<List<double>> original) {
    return original.map((row) => List<double>.from(row)).toList();
  }
}
