import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../database/schemas/meeting_models.dart';

class ExportHelper {
  /// Generates a PDF document for a meeting and shares it using the native share dialog
  static Future<void> shareMeetingPdf(MeetingModel meeting) async {
    final pdf = pw.Document();

    final dateStr = meeting.createdAt != null
        ? DateFormat('MMMM d, yyyy - h:mm a').format(meeting.createdAt!)
        : 'Unknown Date';
    final double min = meeting.durationSeconds / 60.0;
    final durationStr = min >= 1.0 ? '${min.toStringAsFixed(0)} mins' : '${meeting.durationSeconds.toStringAsFixed(0)} secs';

    // Summary data
    final summary = meeting.summary.value;
    final actionItems = meeting.actionItems.toList();
    final decisions = meeting.decisions.toList();
    final segments = meeting.transcript.value?.segments.toList() ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title & Meta
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    meeting.title ?? 'Meeting Summary',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Duration: $durationStr', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Executive Summary
            if (summary != null && summary.executiveSummary != null && summary.executiveSummary!.isNotEmpty) ...[
              pw.Text('Executive Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(summary.executiveSummary!, style: const pw.TextStyle(fontSize: 11, lineSpacing: 3)),
              pw.SizedBox(height: 20),
            ],

            // Key Takeaways
            if (summary != null && summary.keyTakeaways != null && summary.keyTakeaways!.isNotEmpty) ...[
              pw.Text('Key Takeaways', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(summary.keyTakeaways!, style: const pw.TextStyle(fontSize: 11, lineSpacing: 3)),
              pw.SizedBox(height: 20),
            ],

            // Decisions Made
            if (decisions.isNotEmpty) ...[
              pw.Text('Decisions Made', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...decisions.map(
                (d) => pw.Bullet(
                  text: d.description ?? '',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            // Action Items
            if (actionItems.isNotEmpty) ...[
              pw.Text('Action Items', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...actionItems.map(
                (item) {
                  final deadlineStr = item.deadline != null
                      ? ' (Due: ${DateFormat('yyyy-MM-dd').format(item.deadline!)})'
                      : '';
                  final assignedStr = item.assignedTo != null && item.assignedTo!.isNotEmpty
                      ? ' [Assigned to: ${item.assignedTo}]'
                      : '';
                  final statusStr = item.isCompleted ? '[Completed] ' : '[Pending] ';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(statusStr, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Expanded(
                          child: pw.Text(
                            '${item.description}$assignedStr$deadlineStr',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              pw.SizedBox(height: 20),
            ],

            // Full Transcript
            if (segments.isNotEmpty) ...[
              pw.Text('Transcript Log', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...segments.map(
                (seg) {
                  final startMin = (seg.startTime / 60).toInt();
                  final startSec = (seg.startTime % 60).toInt().toString().padLeft(2, '0');
                  final timestamp = '$startMin:$startSec';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(
                          width: 80,
                          child: pw.Text(
                            '[$timestamp] Speaker ${seg.speaker}:',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            seg.text ?? '',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ];
        },
      ),
    );

    // Save temporary PDF and launch sharing
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/meeting_${meeting.id}_export.pdf');
    await file.writeAsBytes(await pdf.save());

    final xFile = XFile(file.path);
    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: 'Summary of ${meeting.title}',
      ),
    );
  }

  /// Exports the summary and action items as a raw text layout and launches the share sheet
  static Future<void> shareMeetingText(MeetingModel meeting) async {
    final summary = meeting.summary.value;
    final actionItems = meeting.actionItems.toList();
    final decisions = meeting.decisions.toList();

    final buffer = StringBuffer();
    buffer.writeln('=== MEETING SUMMARY: ${meeting.title} ===');
    if (meeting.createdAt != null) {
      buffer.writeln('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(meeting.createdAt!)}');
    }
    buffer.writeln('==========================================\n');

    if (summary != null) {
      buffer.writeln('EXECUTIVE SUMMARY:');
      buffer.writeln('${summary.executiveSummary}\n');
      buffer.writeln('KEY TAKEAWAYS:');
      buffer.writeln('${summary.keyTakeaways}\n');
      if (summary.risks != null && summary.risks!.isNotEmpty) {
        buffer.writeln('RISKS IDENTIFIED:');
        buffer.writeln('${summary.risks}\n');
      }
    }

    if (decisions.isNotEmpty) {
      buffer.writeln('DECISIONS MADE:');
      for (var d in decisions) {
        buffer.writeln('- ${d.description}');
      }
      buffer.writeln();
    }

    if (actionItems.isNotEmpty) {
      buffer.writeln('ACTION ITEMS:');
      for (var item in actionItems) {
        final status = item.isCompleted ? '[X]' : '[ ]';
        final details = StringBuffer();
        if (item.assignedTo != null && item.assignedTo!.isNotEmpty) {
          details.write(' (Assigned to: ${item.assignedTo})');
        }
        if (item.deadline != null) {
          details.write(' (Due: ${DateFormat('yyyy-MM-dd').format(item.deadline!)})');
        }
        buffer.writeln('$status ${item.description}$details');
      }
    }

    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: 'Meeting summary: ${meeting.title}',
      ),
    );
  }
}
