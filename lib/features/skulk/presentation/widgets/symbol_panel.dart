import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/answer_text_utils.dart';

/// Marks where the cursor goes after a template is inserted.
const _cursor = '@@';

const _emojis = [
  '😀',
  '😁',
  '😂',
  '🤣',
  '😊',
  '😇',
  '🙂',
  '😉',
  '😍',
  '🥰',
  '😎',
  '🤓',
  '🧐',
  '🤔',
  '🤨',
  '😐',
  '😑',
  '😶',
  '🙄',
  '😏',
  '😮',
  '😯',
  '😲',
  '😳',
  '🥺',
  '😢',
  '😭',
  '😤',
  '😡',
  '🤯',
  '😱',
  '😴',
  '🤗',
  '🤭',
  '🫡',
  '🥳',
  '👍',
  '👎',
  '👌',
  '✌️',
  '🤞',
  '👏',
  '🙌',
  '🙏',
  '💪',
  '👀',
  '🫶',
  '🤝',
  '✅',
  '❌',
  '⚠️',
  '❗',
  '❓',
  '💯',
  '🔥',
  '✨',
  '⭐',
  '🌟',
  '💡',
  '🎯',
  '📌',
  '📍',
  '📝',
  '📚',
  '📖',
  '📒',
  '✏️',
  '🖊️',
  '📐',
  '📏',
  '🧮',
  '🧪',
  '🔬',
  '🔭',
  '💻',
  '⌨️',
  '🖥️',
  '📱',
  '🧠',
  '⏰',
  '⏳',
  '📅',
  '🎓',
  '🏆',
  '❤️',
  '💙',
  '💚',
  '💛',
  '💜',
  '🖤',
  '👉',
  '👈',
  '👆',
  '👇',
  '➡️',
  '⬅️',
];

const _math = [
  '+',
  '−',
  '×',
  '÷',
  '±',
  '∓',
  '=',
  '≠',
  '≈',
  '≡',
  '≅',
  '∝',
  '<',
  '>',
  '≤',
  '≥',
  '≪',
  '≫',
  '∞',
  '√',
  '∛',
  '∜',
  '∑',
  '∏',
  '∫',
  '∬',
  '∭',
  '∮',
  '∂',
  '∇',
  '∆',
  '′',
  '″',
  '°',
  '%',
  '‰',
  '·',
  '∘',
  '⌊',
  '⌋',
  '⌈',
  '⌉',
  '|',
  '‖',
  '∠',
  '⊥',
  '∥',
  '△',
  '⊕',
  '⊗',
  '⊙',
  'ℏ',
  'ℯ',
  'π',
  '∴',
  '∵',
  '∎',
  '…',
  '⋯',
  '⋮',
];

const _greek = [
  'α',
  'β',
  'γ',
  'δ',
  'ε',
  'ζ',
  'η',
  'θ',
  'ι',
  'κ',
  'λ',
  'μ',
  'ν',
  'ξ',
  'ο',
  'π',
  'ρ',
  'σ',
  'τ',
  'υ',
  'φ',
  'χ',
  'ψ',
  'ω',
  'Α',
  'Β',
  'Γ',
  'Δ',
  'Ε',
  'Ζ',
  'Η',
  'Θ',
  'Ι',
  'Κ',
  'Λ',
  'Μ',
  'Ν',
  'Ξ',
  'Ο',
  'Π',
  'Ρ',
  'Σ',
  'Τ',
  'Υ',
  'Φ',
  'Χ',
  'Ψ',
  'Ω',
  'ϑ',
  'ϕ',
  'ϵ',
  'ϖ',
  'ϱ',
  'ς',
];

const _powers = [
  '²',
  '³',
  '⁰',
  '¹',
  '⁴',
  '⁵',
  '⁶',
  '⁷',
  '⁸',
  '⁹',
  '⁺',
  '⁻',
  '⁼',
  '⁽',
  '⁾',
  'ⁿ',
  'ⁱ',
  'ˣ',
  '₀',
  '₁',
  '₂',
  '₃',
  '₄',
  '₅',
  '₆',
  '₇',
  '₈',
  '₉',
  '₊',
  '₋',
  '₌',
  '₍',
  '₎',
  'ₐ',
  'ₑ',
  'ₓ',
  'ₙ',
  'ᵢ',
  'ⱼ',
  'ₖ',
  '½',
  '⅓',
  '⅔',
  '¼',
  '¾',
  '⅕',
  '⅛',
  '⁻¹',
];

const _setsLogic = [
  '∈',
  '∉',
  '∋',
  '⊂',
  '⊃',
  '⊆',
  '⊇',
  '⊄',
  '∪',
  '∩',
  '∅',
  '∖',
  'ℕ',
  'ℤ',
  'ℚ',
  'ℝ',
  'ℂ',
  '∀',
  '∃',
  '∄',
  '¬',
  '∧',
  '∨',
  '⊻',
  '→',
  '←',
  '↔',
  '⇒',
  '⇐',
  '⇔',
  '↑',
  '↓',
  '↦',
  '⊢',
  '⊨',
  '⊤',
  '⊥',
  '≜',
  '≔',
  '⟨',
  '⟩',
  '∣',
  '∤',
  '⊊',
  '⊋',
  '△',
  '×',
  'ℵ',
];

class _EqTemplate {
  const _EqTemplate(this.label, this.preview, this.insert);
  final String label;
  final String preview; // LaTeX shown on the button
  final String insert; // LaTeX inserted; '@@' marks the cursor
}

const _templates = [
  _EqTemplate('Fraction', r'\frac{a}{b}', r'\frac{@@}{}'),
  _EqTemplate('Power', r'x^{n}', r'{@@}^{}'),
  _EqTemplate('Subscript', r'x_{i}', r'{@@}_{}'),
  _EqTemplate('Square root', r'\sqrt{x}', r'\sqrt{@@}'),
  _EqTemplate('n-th root', r'\sqrt[n]{x}', r'\sqrt[@@]{}'),
  _EqTemplate('Integral', r'\int_{a}^{b} f(x)\,dx', r'\int_{@@}^{} \,dx'),
  _EqTemplate('Sum', r'\sum_{i=1}^{n} a_i', r'\sum_{i=1}^{@@} '),
  _EqTemplate('Product', r'\prod_{i=1}^{n} a_i', r'\prod_{i=1}^{@@} '),
  _EqTemplate('Limit', r'\lim_{x \to 0}', r'\lim_{x \to @@} '),
  _EqTemplate('Derivative', r'\frac{dy}{dx}', r'\frac{d@@}{dx}'),
  _EqTemplate(
    'Partial',
    r'\frac{\partial f}{\partial x}',
    r'\frac{\partial @@}{\partial }',
  ),
  _EqTemplate('Log base', r'\log_{b} x', r'\log_{@@} '),
  _EqTemplate(
    'Matrix 2×2',
    r'\begin{bmatrix} a & b \\ c & d \end{bmatrix}',
    r'\begin{bmatrix} @@ &  \\  &  \end{bmatrix}',
  ),
  _EqTemplate(
    'Determinant',
    r'\begin{vmatrix} a & b \\ c & d \end{vmatrix}',
    r'\begin{vmatrix} @@ &  \\  &  \end{vmatrix}',
  ),
  _EqTemplate('Vector', r'\vec{v}', r'\vec{@@}'),
  _EqTemplate('Bar', r'\overline{AB}', r'\overline{@@}'),
  _EqTemplate('Binomial', r'\binom{n}{r}', r'\binom{@@}{}'),
  _EqTemplate('Absolute', r'\left| x \right|', r'\left| @@ \right|'),
  _EqTemplate('Brackets', r'\left( \frac{a}{b} \right)', r'\left( @@ \right)'),
  _EqTemplate(
    'Cases',
    r'f(x)=\begin{cases} 1 & x>0 \\ 0 & x\le 0 \end{cases}',
    r'\begin{cases} @@ &  \\  &  \end{cases}',
  ),
];

/// Inserts a template (with an optional '@@' cursor marker) at the cursor.
void _insertTemplate(TextEditingController c, String template) {
  final i = template.indexOf(_cursor);
  if (i < 0) {
    insertAtCursor(c, template);
    return;
  }
  final text = template.replaceFirst(_cursor, '');
  insertAtCursor(c, text, cursorBack: text.length - i);
}

/// WhatsApp-style panel shown in place of the keyboard: emoji, maths
/// symbols, Greek letters, powers/subscripts, sets & logic, and equations.
class SymbolPanel extends StatelessWidget {
  const SymbolPanel({super.key, required this.controller, this.height = 280});

  final TextEditingController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    Widget grid(List<String> items, {double fontSize = 20}) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 46,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => insertAtCursor(controller, items[i]),
          child: Center(
            child: Text(
              items[i],
              style: TextStyle(
                fontSize: fontSize,
                color: isDark ? Colors.grey[100] : Colors.grey[900],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F5F7),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[850]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: DefaultTabController(
        length: 6,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: primary,
                    dividerColor: Colors.transparent,
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(icon: Icon(Icons.emoji_emotions_outlined, size: 20)),
                      Tab(text: '∑  Math'),
                      Tab(text: 'αβ  Greek'),
                      Tab(text: 'x²  xₙ'),
                      Tab(text: '∈  Sets/Logic'),
                      Tab(text: 'ƒ  Equation'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Backspace',
                  icon: const Icon(Icons.backspace_outlined, size: 20),
                  onPressed: () => backspaceAtCursor(controller),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  grid(_emojis, fontSize: 24),
                  grid(_math),
                  grid(_greek),
                  grid(_powers),
                  grid(_setsLogic),
                  _EquationTab(controller: controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquationTab extends StatelessWidget {
  const _EquationTab({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final tileColor = isDark ? const Color(0xFF262626) : Colors.white;
    final textColor = isDark ? Colors.grey[100]! : Colors.grey[900]!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => showEquationEditor(context, controller),
                icon: const Icon(Icons.functions, size: 18),
                label: Text(
                  'Equation editor',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _insertTemplate(controller, '\$$_cursor\$'),
              child: Text('\$ x \$', style: GoogleFonts.outfit()),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: () =>
                  _insertTemplate(controller, '\n\$\$$_cursor\$\$\n'),
              child: Text('\$\$ x \$\$', style: GoogleFonts.outfit()),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Write equations between \$ \$ (in a line) or \$\$ \$\$ (on their '
            'own line). Tap a template to insert it inside an equation.',
            style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.grey),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 120,
            mainAxisExtent: 60,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: _templates.length,
          itemBuilder: (_, i) {
            final t = _templates[i];
            return Material(
              color: tileColor,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _insertTemplate(
                  controller,
                  _wrapIfNeeded(controller, t.insert),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FittedBox(
                          child: Math.tex(
                            t.preview,
                            textStyle: TextStyle(
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        t.label,
                        style: GoogleFonts.outfit(fontSize: 10, color: primary),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Wraps [tex] in `$...$` unless the cursor is already inside an equation.
String _wrapIfNeeded(TextEditingController c, String tex) {
  final sel = c.selection;
  final pos = sel.isValid ? sel.start : c.text.length;
  final dollarsBefore = '\$'.allMatches(c.text.substring(0, pos)).length;
  final insideMath = dollarsBefore.isOdd;
  return insideMath ? tex : '\$$tex\$';
}

/// Dialog for writing an equation in LaTeX with a live preview.
Future<void> showEquationEditor(
  BuildContext context,
  TextEditingController target,
) {
  final texController = TextEditingController();
  var display = false;

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final textColor = isDark ? Colors.grey[100]! : Colors.grey[900]!;
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final tex = texController.text.trim();
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            title: Text(
              'Equation',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: tex.isEmpty
                          ? Text(
                              'Preview appears here',
                              style: GoogleFonts.outfit(color: Colors.grey),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Math.tex(
                                tex,
                                mathStyle: display
                                    ? MathStyle.display
                                    : MathStyle.text,
                                textStyle: TextStyle(
                                  fontSize: 18,
                                  color: textColor,
                                ),
                                onErrorFallback: (_) => Text(
                                  'Keep typing…',
                                  style: GoogleFonts.outfit(color: Colors.grey),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: texController,
                      autofocus: true,
                      minLines: 2,
                      maxLines: 5,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (_) => setLocal(() {}),
                      style: GoogleFonts.robotoMono(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: r'e.g. x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}',
                        hintStyle: GoogleFonts.robotoMono(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in _templates)
                          ActionChip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              t.label,
                              style: GoogleFonts.outfit(fontSize: 11),
                            ),
                            onPressed: () {
                              _insertTemplate(texController, t.insert);
                              setLocal(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: display,
                      onChanged: (v) => setLocal(() => display = v),
                      title: Text(
                        'Show on its own line',
                        style: GoogleFonts.outfit(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ),
              FilledButton(
                onPressed: tex.isEmpty
                    ? null
                    : () {
                        insertAtCursor(
                          target,
                          display ? '\n\$\$$tex\$\$\n' : '\$$tex\$ ',
                        );
                        Navigator.pop(ctx);
                      },
                child: Text(
                  'Insert',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
