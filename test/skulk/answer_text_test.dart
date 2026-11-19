import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_fox/features/skulk/presentation/widgets/rich_answer_text.dart';
import 'package:focus_fox/features/skulk/utils/answer_text_utils.dart';

void main() {
  test('cleans invisible characters and odd spaces', () {
    final zwsp = String.fromCharCode(0x200B);
    final nbsp = String.fromCharCode(0x00A0);
    expect(cleanAnswerText('a${zwsp}b${nbsp}c\r\nd'), 'ab c\nd');
  });

  test('converts GPT LaTeX delimiters', () {
    expect(normalizeMathDelimiters(r'x \(a^2\) and \[b\]'), r'x $a^2$ and $$b$$');
  });

  test('insertAtCursor and backspace', () {
    final c = TextEditingController(text: 'ab');
    c.selection = const TextSelection.collapsed(offset: 1);
    insertAtCursor(c, 'XYZ', cursorBack: 1);
    expect(c.text, 'aXYZb');
    expect(c.selection.baseOffset, 3);
    backspaceAtCursor(c);
    expect(c.text, 'aXZb');
  });

  testWidgets('renders markdown with inline and display math', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RichAnswerText(
          r'**Answer:** the root is $\frac{-b}{2a}$ costing $5 and $10.'
          '\n'
          r'Area: \[ \pi r^2 \]'
          '\n2*3*4 = 24',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(find.byType(Math), findsNWidgets(2));
    expect(t.takeException(), isNull);
  });
}
