import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../utils/answer_text_utils.dart';

/// Renders an answer body: Markdown (bold, headings, lists, code, tables)
/// plus LaTeX equations written as `$...$` (inline) or `$$...$$` (display).
///
/// Answers pasted from ChatGPT are handled too: invisible characters are
/// removed and `\( \)` / `\[ \]` are converted to dollar delimiters.
class RichAnswerText extends StatelessWidget {
  const RichAnswerText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = normalizeMathDelimiters(cleanAnswerText(text));
    final codeBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F3F5);

    final sheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: style,
      a: style.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      strong: const TextStyle(fontWeight: FontWeight.w700),
      em: const TextStyle(fontStyle: FontStyle.italic),
      h1: style.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
      h2: style.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
      h3: style.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700),
      h4: style.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
      h5: style.copyWith(fontWeight: FontWeight.w700),
      h6: style.copyWith(fontWeight: FontWeight.w700),
      listBullet: style,
      tableHead: style.copyWith(fontWeight: FontWeight.w700),
      tableBody: style,
      tableBorder: TableBorder.all(
        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        width: 0.6,
      ),
      code: GoogleFonts.robotoMono(
        fontSize: (style.fontSize ?? 14) - 1,
        color: style.color,
        backgroundColor: codeBg,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(8),
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
      ),
    );

    return MarkdownBody(
      data: data,
      styleSheet: sheet,
      softLineBreak: true,
      inlineSyntaxes: [_MathSyntax(), _DigitTimesSyntax()],
      builders: {'math': _MathBuilder()},
      onTapLink: (text, href, title) {
        final uri = href == null ? null : Uri.tryParse(href);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}

/// Matches `$$...$$` (display) and `$...$` (inline). For inline math the
/// opening `$` must not be followed by a space and the closing `$` must not
/// be preceded by a space or followed by a digit, so prices such as
/// "$5 and $10" stay as plain text.
class _MathSyntax extends md.InlineSyntax {
  _MathSyntax()
    : super(
        r'\$\$([\s\S]+?)\$\$|\$(?!\s)((?:\\.|[^$\\\n])+?)(?<!\s)\$(?!\d)',
        startCharacter: 0x24, // $
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final display = match.group(1) != null;
    final tex = (match.group(1) ?? match.group(2) ?? '').trim();
    final el = md.Element.text('math', tex);
    el.attributes['display'] = display ? '1' : '0';
    parser.addNode(el);
    return true;
  }
}

/// Keeps `2*3*4` as plain multiplication instead of italicising the `3`.
class _DigitTimesSyntax extends md.InlineSyntax {
  _DigitTimesSyntax() : super(r'(\d)\*(?=\d)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Text('${match.group(1)}*'));
    return true;
  }
}

class _MathBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final tex = element.textContent;
    final display = element.attributes['display'] == '1';
    final base = parentStyle ?? DefaultTextStyle.of(context).style;
    final mathStyle = base.copyWith(
      fontSize: (base.fontSize ?? 14) * (display ? 1.15 : 1.05),
    );

    Widget math = Math.tex(
      tex,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: mathStyle,
      onErrorFallback: (_) =>
          Text(display ? '\$\$$tex\$\$' : '\$$tex\$', style: base),
    );
    // Wide equations scroll sideways instead of overflowing the card.
    math = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: display
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: math,
            )
          : math,
    );

    // Returned as Text.rich so flutter_markdown merges it into the
    // surrounding sentence instead of breaking the line.
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(alignment: PlaceholderAlignment.middle, child: math),
        ],
      ),
    );
  }
}
