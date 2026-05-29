import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../models/question_full.dart';
import '../models/topic_with_questions.dart';

class PdfService {
  static final PdfColor primaryColor = PdfColor.fromHex('#D37D3E'); // App primary
  static final PdfColor bgColor = PdfColor.fromHex('#FFFBF5'); // Soft off-white
  static final PdfColor secondaryColor = PdfColor.fromHex('#8BA682');

  Future<Uint8List> generateTopicPdf(String topicName, List<QuestionFull> questions) async {
    final pdf = pw.Document();

    // Parallelize pre-loading images for all questions
    await Future.wait(questions.map((q) async {
      q.loadedImages = await Future.wait(q.imageUrls.map((url) async {
        try {
          final response = await http.get(Uri.parse(url));
          return response.statusCode == 200 ? response.bodyBytes : Uint8List(0);
        } catch (e) {
          return Uint8List(0);
        }
      }));
    }));

    // Load NotoSans and Math fallback
    final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final mathFontData = await rootBundle.load("assets/fonts/NotoSansMath-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final mathTtf = pw.Font.ttf(mathFontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttf,
          fontFallback: [mathTtf],
        ),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text(
            'PYQ MVP • $topicName',
            style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
          ),
        ),
        build: (context) => [
          // Title Section
          pw.Text(
            topicName,
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: primaryColor, thickness: 2),
          pw.SizedBox(height: 30),

          // Questions
          ...questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header: Q Number & Difficulty
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'QUESTION ${i + 1}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          q.difficulty.toUpperCase(),
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  
                  // Question Text
                  pw.Text(
                    q.text,
                    style: const pw.TextStyle(fontSize: 13, height: 1.4),
                  ),
                  pw.SizedBox(height: 12),

                  // Metadata (PYQ Sources)
                  if (q.pyqMeta.isNotEmpty)
                    pw.Wrap(
                      spacing: 10,
                      children: q.pyqMeta.map((m) => pw.Text(
                        '• ${m.examType} (${m.year}) - ${m.questionNumber}',
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                      )).toList(),
                    ),
                  
                  pw.SizedBox(height: 12),

                  // Images
                  ...(q.loadedImages ?? []).map((bytes) {
                    if (bytes.isEmpty) return pw.SizedBox.shrink();
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 10),
                      child: pw.Center(
                        child: pw.Container(
                          constraints: const pw.BoxConstraints(maxHeight: 300),
                          child: pw.Image(pw.MemoryImage(bytes)),
                        ),
                      ),
                    );
                  }),

                  pw.SizedBox(height: 20),
                  pw.Divider(color: PdfColors.grey200),
                ],
              ),
            );
          }),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateSubjectPdf(String subjectName, List<TopicWithQuestions> data) async {
    final pdf = pw.Document();

    // Parallelize pre-loading images for all topics and questions
    final List<Future> preloadFutures = [];
    for (var topic in data) {
      for (var q in topic.questions) {
        preloadFutures.add(() async {
          q.loadedImages = await Future.wait(q.imageUrls.map((url) async {
            try {
              final response = await http.get(Uri.parse(url));
              return response.statusCode == 200 ? response.bodyBytes : Uint8List(0);
            } catch (e) {
              return Uint8List(0);
            }
          }));
        }());
      }
    }
    await Future.wait(preloadFutures);

    final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final mathFontData = await rootBundle.load("assets/fonts/NotoSansMath-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final mathTtf = pw.Font.ttf(mathFontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttf,
          fontFallback: [mathTtf],
        ),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text(
            'PYQ MVP • $subjectName',
            style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
          ),
        ),
        build: (context) => [
          // Subject Title
          pw.Text(
            subjectName,
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: primaryColor, thickness: 2),
          pw.SizedBox(height: 30),

          // Loop Topics
          ...data.map((topic) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Topic Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex("#F3E5D8"),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    topic.topicName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.brown800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Questions for this topic
                ...topic.questions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final q = entry.value;

                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 24),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'QUESTION ${i + 1}',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                            pw.Text(
                              q.difficulty.toUpperCase(),
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          q.text,
                          style: const pw.TextStyle(fontSize: 12, height: 1.4),
                        ),
                        pw.SizedBox(height: 10),

                        // Metadata
                        if (q.pyqMeta.isNotEmpty)
                          pw.Wrap(
                            spacing: 8,
                            children: q.pyqMeta.map((m) => pw.Text(
                              '• ${m.examType} (${m.year}) - ${m.questionNumber}',
                              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                            )).toList(),
                          ),

                        // Images
                        ...(q.loadedImages ?? []).map((bytes) {
                          if (bytes.isEmpty) return pw.SizedBox.shrink();
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 10),
                            child: pw.Center(
                              child: pw.Container(
                                constraints: const pw.BoxConstraints(maxHeight: 250),
                                child: pw.Image(pw.MemoryImage(bytes)),
                              ),
                            ),
                          );
                        }),
                        pw.SizedBox(height: 15),
                        pw.Divider(color: PdfColors.grey100),
                      ],
                    ),
                  );
                }),
                pw.SizedBox(height: 30),
              ],
            );
          }),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> downloadPdf(Uint8List bytes, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: fileName,
    );
  }
}
