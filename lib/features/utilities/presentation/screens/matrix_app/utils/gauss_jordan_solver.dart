class GaussJordanStep {
  final List<List<double>> matrix;
  final List<List<double>> identity;
  final String operation;
  final String? description;

  GaussJordanStep(this.matrix, this.identity, this.operation, {this.description});
}

class GaussJordanSolver {
  final List<List<double>> inputMatrix;
  final List<GaussJordanStep> steps = [];
  bool isSingular = false;

  GaussJordanSolver(this.inputMatrix);

  List<GaussJordanStep> solve() {
    int n = inputMatrix.length;
    if (n == 0) return steps;
    List<List<double>> matrix = _deepCopy(inputMatrix);
    List<List<double>> identity = _identityMatrix(n);

    steps.add(GaussJordanStep(
      _deepCopy(matrix),
      _deepCopy(identity),
      "Augmented Matrix [A | I]",
      description: "Appended $n × $n Identity matrix to the right of Matrix A.",
    ));

    for (int i = 0; i < n; i++) {
      // Find pivot row
      int maxRow = i;
      double maxVal = matrix[i][i].abs();
      for (int k = i + 1; k < n; k++) {
        if (matrix[k][i].abs() > maxVal) {
          maxVal = matrix[k][i].abs();
          maxRow = k;
        }
      }

      if (maxVal < 1e-9) {
        isSingular = true;
        steps.add(GaussJordanStep(
          _deepCopy(matrix),
          _deepCopy(identity),
          "Singular Matrix Detected",
          description: "No non-zero pivot found in column ${i + 1}. The determinant is 0, so the inverse does not exist.",
        ));
        return steps;
      }

      if (maxRow != i) {
        var tempM = matrix[i];
        matrix[i] = matrix[maxRow];
        matrix[maxRow] = tempM;

        var tempI = identity[i];
        identity[i] = identity[maxRow];
        identity[maxRow] = tempI;

        steps.add(GaussJordanStep(
          _deepCopy(matrix),
          _deepCopy(identity),
          "Swap R${i + 1} ↔ R${maxRow + 1}",
          description: "Swapped row ${i + 1} with row ${maxRow + 1} to bring the largest pivot to the diagonal.",
        ));
      }

      // Normalize pivot to 1
      double pivot = matrix[i][i];
      if ((pivot - 1.0).abs() > 1e-9) {
        for (int j = 0; j < n; j++) {
          matrix[i][j] /= pivot;
          identity[i][j] /= pivot;
          if (matrix[i][j].abs() < 1e-9) matrix[i][j] = 0.0;
          if (identity[i][j].abs() < 1e-9) identity[i][j] = 0.0;
        }
        steps.add(GaussJordanStep(
          _deepCopy(matrix),
          _deepCopy(identity),
          "R${i + 1} → R${i + 1} ÷ ${pivot.toStringAsFixed(2)}",
          description: "Divided row ${i + 1} by ${pivot.toStringAsFixed(2)} to set diagonal pivot to 1.",
        ));
      }

      // Eliminate all other entries in current column
      for (int k = 0; k < n; k++) {
        if (k != i && matrix[k][i].abs() > 1e-9) {
          double factor = matrix[k][i];
          for (int j = 0; j < n; j++) {
            matrix[k][j] -= factor * matrix[i][j];
            identity[k][j] -= factor * identity[i][j];
            if (matrix[k][j].abs() < 1e-9) matrix[k][j] = 0.0;
            if (identity[k][j].abs() < 1e-9) identity[k][j] = 0.0;
          }
          steps.add(GaussJordanStep(
            _deepCopy(matrix),
            _deepCopy(identity),
            "R${k + 1} → R${k + 1} - (${factor.toStringAsFixed(2)}) × R${i + 1}",
            description: "Eliminated entry at row ${k + 1}, column ${i + 1}.",
          ));
        }
      }
    }

    return steps;
  }

  List<List<double>>? getInverse() {
    if (isSingular) return null;
    if (steps.isEmpty) solve();
    if (isSingular || steps.isEmpty) return null;
    return steps.last.identity;
  }

  List<List<double>> _deepCopy(List<List<double>> original) {
    return original.map((row) => List<double>.from(row)).toList();
  }

  List<List<double>> _identityMatrix(int n) {
    return List.generate(n, (i) => List.generate(n, (j) => i == j ? 1.0 : 0.0));
  }
}
