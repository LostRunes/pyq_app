import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_fox/features/utilities/presentation/screens/matrix_app/matrix_app_screen.dart';

void main() {
  testWidgets('MatrixAppScreen renders with header, tabs, and solve button', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: MatrixAppScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and banner
    expect(find.text('Matrix Solver'), findsOneWidget);
    expect(find.text('Linear Algebra Solver'), findsOneWidget);

    // Verify mode tabs
    expect(find.text('Gauss'), findsOneWidget);
    expect(find.text('Inverse'), findsOneWidget);
    expect(find.text('Eigen'), findsOneWidget);

    // Verify action button
    expect(find.text('Solve Step-by-Step'), findsOneWidget);

    // Tap solve button to solve default sample matrix
    await tester.tap(find.text('Solve Step-by-Step'));
    await tester.pumpAndSettle();

    // Verify row echelon results appear
    expect(find.text('Row Echelon Form'), findsOneWidget);
    expect(find.text('Solved System Variables:'), findsOneWidget);
  });

  testWidgets('MatrixAppScreen switches tabs properly to Inverse and Eigen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: MatrixAppScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Inverse mode
    await tester.tap(find.text('Inverse'));
    await tester.pumpAndSettle();

    expect(find.text('Size (N×N)'), findsOneWidget);
    await tester.tap(find.text('Solve Step-by-Step'));
    await tester.pumpAndSettle();
    expect(find.text('Inverse Matrix [A⁻¹]'), findsOneWidget);

    // Switch to Eigen mode
    await tester.tap(find.text('Eigen'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Solve Step-by-Step'));
    await tester.pumpAndSettle();
    expect(find.text('Eigenvalues & Eigenvectors'), findsOneWidget);
  });

  testWidgets('MatrixAppScreen renders cleanly on narrow screen (360px logical width) without overflow', (tester) async {
    tester.view.physicalSize = const Size(720, 1600); // 360 x 800 logical
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: MatrixAppScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rows'), findsOneWidget);
    expect(find.text('Columns'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
