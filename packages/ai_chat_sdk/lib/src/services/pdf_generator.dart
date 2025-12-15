import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Service for generating PDF reports from AI messages
class PdfGenerator {
  /// Generate a PDF report with optional chart image
  static Future<Uint8List> generateReportPdf({
    required String reportText,
    Uint8List? chartImage,
    String title = 'AI Report',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Title
          pw.Header(
            level: 0,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Chart image (if present) - constrained to fit within page
          if (chartImage != null) ...[
            pw.Center(
              child: pw.ConstrainedBox(
                constraints: const pw.BoxConstraints(
                  maxWidth: 450,
                  maxHeight: 350, // Limit height to prevent overflow
                ),
                child: pw.Image(
                  pw.MemoryImage(chartImage),
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 15),
          ],

          // Report text - parsed with basic markdown formatting
          ..._parseMarkdownToWidgets(reportText),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  /// Parse basic markdown patterns into PDF widgets
  static List<pw.Widget> _parseMarkdownToWidgets(String text) {
    final lines = text.split('\n');
    final widgets = <pw.Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        // Empty line - add spacing
        widgets.add(pw.SizedBox(height: 8));
      } else if (trimmed.startsWith('### ')) {
        // H3 header
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
          child: pw.Text(
            trimmed.substring(4),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ));
      } else if (trimmed.startsWith('## ')) {
        // H2 header
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
          child: pw.Text(
            trimmed.substring(3),
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ));
      } else if (trimmed.startsWith('# ')) {
        // H1 header
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
          child: pw.Text(
            trimmed.substring(2),
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
        ));
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        // Bullet point
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('• ', style: const pw.TextStyle(fontSize: 12)),
              pw.Expanded(
                child: pw.Text(
                  trimmed.substring(2),
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ));
      } else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        // Numbered list item
        final match = RegExp(r'^(\d+\.)\s(.*)').firstMatch(trimmed);
        if (match != null) {
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 24,
                  child: pw.Text(
                    match.group(1)!,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    match.group(2)!,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ));
        }
      } else {
        // Regular paragraph text
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(
            trimmed,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ));
      }
    }

    return widgets;
  }
}
