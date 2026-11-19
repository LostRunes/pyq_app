import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Helpers for text that users type or paste into Skulk answers.
///
/// Text copied from ChatGPT, PDFs and web pages often carries invisible
/// Unicode characters (zero-width spaces, BOMs, bidi marks, soft hyphens,
/// non-breaking spaces) and LaTeX written with `\( \)` / `\[ \]` delimiters.
/// These show up as stray boxes, odd spacing or raw backslashes, so they are
/// cleaned here before the text is stored and before it is rendered.

// Characters that are removed outright. ZWJ (U+200D) and ZWNJ (U+200C) are
// kept on purpose: emoji sequences and Indic scripts depend on them.
final RegExp _invisibleChars = RegExp(
  '[\u200B\u2060\uFEFF\u00AD\u180E\u202A-\u202E\u2066-\u2069\u200E\u200F]',
);

// Space-like characters that are turned into a plain space.
final RegExp _oddSpaces = RegExp('[\u00A0\u2007\u202F\u2000-\u200A\u3000]');

/// Removes invisible characters and normalises spaces and line breaks.
String cleanAnswerText(String input) {
  return input
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp('[\u2028\u2029]'), '\n')
      .replaceAll(_invisibleChars, '')
      .replaceAll(_oddSpaces, ' ');
}

/// Converts `\( ... \)` to `$ ... $` and `\[ ... \]` to `$$ ... $$`,
/// the delimiters the answer renderer understands.
String normalizeMathDelimiters(String input) {
  return input
      .replaceAllMapped(
        RegExp(r'\\\[([\s\S]+?)\\\]'),
        (m) => '\$\$${m.group(1)!.trim()}\$\$',
      )
      .replaceAllMapped(
        RegExp(r'\\\(([\s\S]+?)\\\)'),
        (m) => '\$${m.group(1)!.trim()}\$',
      );
}

/// Input formatter that applies [cleanAnswerText] as the user types or
/// pastes, keeping the cursor where it was.
class AnswerTextFormatter extends TextInputFormatter {
  const AnswerTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = cleanAnswerText(newValue.text);
    if (cleaned == newValue.text) return newValue;

    int mapOffset(int offset) {
      if (offset < 0) return offset;
      final safe = offset.clamp(0, newValue.text.length);
      return cleanAnswerText(newValue.text.substring(0, safe)).length;
    }

    return TextEditingValue(
      text: cleaned,
      selection: TextSelection(
        baseOffset: mapOffset(newValue.selection.baseOffset),
        extentOffset: mapOffset(newValue.selection.extentOffset),
      ),
    );
  }
}

/// Deletes the selection, or the character (whole emoji/grapheme) before the
/// cursor.
void backspaceAtCursor(TextEditingController controller) {
  final value = controller.value;
  final sel = value.selection;
  final text = value.text;
  if (text.isEmpty) return;
  final start = sel.isValid ? sel.start : text.length;
  final end = sel.isValid ? sel.end : text.length;
  if (start != end) {
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
    );
    return;
  }
  if (start == 0) return;
  final before = text.substring(0, start).characters.skipLast(1).toString();
  controller.value = TextEditingValue(
    text: before + text.substring(start),
    selection: TextSelection.collapsed(offset: before.length),
  );
}

/// Inserts [text] at the controller's cursor (replacing any selection).
/// If [cursorBack] is given, the cursor ends that many characters before the
/// end of the inserted text, e.g. inside the braces of `\frac{}{}`.
void insertAtCursor(
  TextEditingController controller,
  String text, {
  int cursorBack = 0,
}) {
  final value = controller.value;
  final sel = value.selection;
  final start = sel.isValid ? sel.start : value.text.length;
  final end = sel.isValid ? sel.end : value.text.length;
  final newText = value.text.replaceRange(start, end, text);
  final caret = (start + text.length - cursorBack).clamp(0, newText.length);
  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: caret),
  );
}
