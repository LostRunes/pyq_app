import 'package:flutter_test/flutter_test.dart';
import 'package:focus_fox/features/utilities/presentation/screens/matrix_app/utils/gauss_elimination_solver.dart';
import 'package:focus_fox/features/utilities/presentation/screens/matrix_app/utils/gauss_jordan_solver.dart';
import 'package:focus_fox/features/utilities/presentation/screens/matrix_app/utils/eigen_solver.dart';

void main() {
  group('Matrix Solvers', () {
    test('Gauss Elimination solver computes correctly', () {
      List<List<double>> input = [
        [2, 1, -1, 8],
        [-3, -1, 2, -11],
        [-2, 1, 2, -3]
      ];
      
      var solver = GaussEliminationSolver(input);
      var steps = solver.solve();
      
      expect(steps, isNotEmpty);
      var finalMatrix = steps.last.matrix;
      
      // Upper triangular check for first column
      expect(finalMatrix[1][0], closeTo(0, 0.001));
      expect(finalMatrix[2][0], closeTo(0, 0.001));
    });

    test('Gauss-Jordan solver computes correctly', () {
      List<List<double>> input = [
        [2, -1, 0],
        [-1, 2, -1],
        [0, -1, 2]
      ];
      
      var solver = GaussJordanSolver(input);
      var steps = solver.solve();
      
      expect(steps, isNotEmpty);
      var finalMatrix = steps.last.matrix;
      
      // Should be identity matrix
      expect(finalMatrix[0][0], closeTo(1, 0.001));
      expect(finalMatrix[1][1], closeTo(1, 0.001));
      expect(finalMatrix[2][2], closeTo(1, 0.001));
      expect(finalMatrix[1][0], closeTo(0, 0.001));
    });

    test('Eigen solver computes correctly', () {
      List<List<double>> input = [
        [4, -2],
        [1, 1]
      ];
      
      var solver = EigenSolver(input);
      var result = solver.solve();
      
      expect(result.eigenvalues, isNotEmpty);
      expect(result.eigenvalues.contains(2.0) || result.eigenvalues.contains(3.0), isTrue); // Eigenvalues are 3 and 2
    });
  });
}
