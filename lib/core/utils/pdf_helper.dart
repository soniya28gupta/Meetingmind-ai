import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../database/schemas/meeting_models.dart';

class ExportHelper {
  /// Generates a PDF document for a meeting and shares it
  static Future<void> shareMeetingPdf(MeetingModel meeting) async {
    final pdf = pw.Document();

    final dateStr = meeting.createdAt != null
        ? DateFormat('MMMM d, yyyy - h:mm a').format(meeting.createdAt!)
        : 'Unknown Date';
    final double min = meeting.durationSeconds / 60.0;
    final durationStr = min >= 1.0
        ? '${min.toStringAsFixed(0)} mins'
        : '${meeting.durationSeconds.toStringAsFixed(0)} secs';

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
                    meeting.title ?? 'Meeting Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Date: $dateStr',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Duration: $durationStr',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Executive Summary
            if (summary != null &&
                summary.executiveSummary != null &&
                summary.executiveSummary!.isNotEmpty) ...[
              pw.Text(
                'Executive Summary',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                summary.executiveSummary!,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
              ),
              pw.SizedBox(height: 20),
            ],

            // Key Takeaways
            if (summary != null &&
                summary.keyTakeaways != null &&
                summary.keyTakeaways!.isNotEmpty) ...[
              pw.Text(
                'Key Takeaways & Highlights',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                summary.keyTakeaways!,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
              ),
              pw.SizedBox(height: 20),
            ],

            // Risks & Concerns
            if (summary != null &&
                summary.risks != null &&
                summary.risks!.isNotEmpty) ...[
              pw.Text(
                'Risks & Roadblocks',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                summary.risks!,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
              ),
              pw.SizedBox(height: 20),
            ],

            // Next Steps / Follow Ups
            if (summary != null &&
                summary.followUps != null &&
                summary.followUps!.isNotEmpty) ...[
              pw.Text(
                'Next Steps',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                summary.followUps!,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
              ),
              pw.SizedBox(height: 20),
            ],

            // Decisions Made
            if (decisions.isNotEmpty) ...[
              pw.Text(
                'Decisions Made',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
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
              pw.Text(
                'Action Items',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              ...actionItems.map((item) {
                final deadlineStr = item.deadline != null
                    ? ' (Due: ${DateFormat('yyyy-MM-dd').format(item.deadline!)})'
                    : '';
                final assignedStr =
                    item.assignedTo != null && item.assignedTo!.isNotEmpty
                    ? ' [Assigned to: ${item.assignedTo}]'
                    : '';
                final statusStr = item.isCompleted
                    ? '[Completed] '
                    : '[Pending] ';
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        statusStr,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          '${item.description}$assignedStr$deadlineStr',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 20),
            ],

            // Full Transcript
            if (segments.isNotEmpty) ...[
              pw.Text(
                'Transcript Log',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              ...segments.map((seg) {
                final startMin = (seg.startTime / 60).toInt();
                final startSec = (seg.startTime % 60)
                    .toInt()
                    .toString()
                    .padLeft(2, '0');
                final timestamp = '$startMin:$startSec';
                final speakerName =
                    seg.speakerProfile.value?.name ?? 'Speaker ${seg.speaker}';
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 100,
                        child: pw.Text(
                          '[$timestamp] $speakerName:',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
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
              }),
            ],
          ];
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/meeting_${meeting.id}_export.pdf');
    await file.writeAsBytes(await pdf.save());

    final xFile = XFile(file.path);
    await SharePlus.instance.share(
      ShareParams(files: [xFile], text: 'PDF Report of ${meeting.title}'),
    );
  }

  /// Exports the summary and transcript as Markdown and shares the file
  static Future<void> shareMeetingMarkdown(MeetingModel meeting) async {
    final summary = meeting.summary.value;
    final actionItems = meeting.actionItems.toList();
    final decisions = meeting.decisions.toList();
    final segments = meeting.transcript.value?.segments.toList() ?? [];

    final buffer = StringBuffer();
    buffer.writeln('# Meeting Notes: ${meeting.title}');
    if (meeting.createdAt != null) {
      buffer.writeln(
        '**Date:** ${DateFormat('MMMM d, yyyy - h:mm a').format(meeting.createdAt!)}  ',
      );
    }
    buffer.writeln(
      '**Duration:** ${(meeting.durationSeconds / 60).toStringAsFixed(1)} minutes  \n',
    );

    if (summary != null) {
      if ((summary.executiveSummary ?? '').isNotEmpty) {
        buffer.writeln('## Executive Summary\n${summary.executiveSummary}\n');
      }
      if ((summary.keyTakeaways ?? '').isNotEmpty) {
        buffer.writeln('## Key Takeaways\n${summary.keyTakeaways}\n');
      }
      if ((summary.risks ?? '').isNotEmpty) {
        buffer.writeln('## Risks & Roadblocks\n${summary.risks}\n');
      }
      if ((summary.followUps ?? '').isNotEmpty) {
        buffer.writeln('## Next Steps\n${summary.followUps}\n');
      }
      if ((summary.deadlines ?? '').isNotEmpty) {
        buffer.writeln('## Deadlines & Dates\n${summary.deadlines}\n');
      }
    }

    if (decisions.isNotEmpty) {
      buffer.writeln('## Decisions Made');
      for (var d in decisions) {
        buffer.writeln('- ${d.description}');
      }
      buffer.writeln();
    }

    if (actionItems.isNotEmpty) {
      buffer.writeln('## Action Items');
      for (var item in actionItems) {
        final status = item.isCompleted ? '[x]' : '[ ]';
        final details = StringBuffer();
        if (item.assignedTo != null && item.assignedTo!.isNotEmpty) {
          details.write(' (Assigned to: ${item.assignedTo})');
        }
        if (item.deadline != null) {
          details.write(
            ' (Due: ${DateFormat('yyyy-MM-dd').format(item.deadline!)})',
          );
        }
        buffer.writeln('- $status ${item.description}$details');
      }
      buffer.writeln();
    }

    if (segments.isNotEmpty) {
      buffer.writeln('## Transcript Log');
      for (var seg in segments) {
        final startMin = (seg.startTime / 60).toInt();
        final startSec = (seg.startTime % 60).toInt().toString().padLeft(
          2,
          '0',
        );
        final speakerName =
            seg.speakerProfile.value?.name ?? 'Speaker ${seg.speaker}';
        buffer.writeln('**[$startMin:$startSec] $speakerName:** ${seg.text}  ');
      }
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/meeting_${meeting.id}_export.md');
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Markdown Report: ${meeting.title}',
      ),
    );
  }

  /// Exports as a DOCX-compatible HTML word document
  static Future<void> shareMeetingDocx(MeetingModel meeting) async {
    final summary = meeting.summary.value;
    final actionItems = meeting.actionItems.toList();
    final decisions = meeting.decisions.toList();
    final segments = meeting.transcript.value?.segments.toList() ?? [];

    final html = StringBuffer();
    html.writeln(
      '<html><head><meta charset="utf-8"><title>${meeting.title}</title></head>',
    );
    html.writeln(
      '<body style="font-family: Arial, sans-serif; line-height: 1.6; padding: 20px;">',
    );
    html.writeln('<h1 style="color: #2b579a;">${meeting.title}</h1>');
    if (meeting.createdAt != null) {
      html.writeln(
        '<p><strong>Date:</strong> ${DateFormat('MMMM d, yyyy - h:mm a').format(meeting.createdAt!)}</p>',
      );
    }
    html.writeln(
      '<p><strong>Duration:</strong> ${(meeting.durationSeconds / 60).toStringAsFixed(1)} minutes</p>',
    );
    html.writeln('<hr/>');

    if (summary != null) {
      if ((summary.executiveSummary ?? '').isNotEmpty) {
        html.writeln('<h2>Executive Summary</h2>');
        html.writeln(
          '<p>${summary.executiveSummary!.replaceAll('\n', '<br/>')}</p>',
        );
      }
      if ((summary.keyTakeaways ?? '').isNotEmpty) {
        html.writeln('<h2>Key Takeaways</h2>');
        html.writeln(
          '<p>${summary.keyTakeaways!.replaceAll('\n', '<br/>')}</p>',
        );
      }
      if ((summary.risks ?? '').isNotEmpty) {
        html.writeln('<h2>Risks & Roadblocks</h2>');
        html.writeln('<p>${summary.risks!.replaceAll('\n', '<br/>')}</p>');
      }
      if ((summary.followUps ?? '').isNotEmpty) {
        html.writeln('<h2>Next Steps</h2>');
        html.writeln('<p>${summary.followUps!.replaceAll('\n', '<br/>')}</p>');
      }
      if ((summary.deadlines ?? '').isNotEmpty) {
        html.writeln('<h2>Deadlines & Dates</h2>');
        html.writeln('<p>${summary.deadlines!.replaceAll('\n', '<br/>')}</p>');
      }
    }

    if (decisions.isNotEmpty) {
      html.writeln('<h2>Decisions Made</h2>');
      html.writeln('<ul>');
      for (var d in decisions) {
        html.writeln('<li>${d.description}</li>');
      }
      html.writeln('</ul>');
    }

    if (actionItems.isNotEmpty) {
      html.writeln('<h2>Action Items</h2>');
      html.writeln('<ul>');
      for (var item in actionItems) {
        final status = item.isCompleted
            ? '<strong>[Completed]</strong>'
            : '<strong>[Pending]</strong>';
        final details = StringBuffer();
        if (item.assignedTo != null && item.assignedTo!.isNotEmpty) {
          details.write(' (Assigned to: ${item.assignedTo})');
        }
        if (item.deadline != null) {
          details.write(
            ' (Due: ${DateFormat('yyyy-MM-dd').format(item.deadline!)})',
          );
        }
        html.writeln('<li>$status ${item.description}$details</li>');
      }
      html.writeln('</ul>');
    }

    if (segments.isNotEmpty) {
      html.writeln('<h2>Transcript Log</h2>');
      html.writeln(
        '<table border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse; width: 100%;">',
      );
      html.writeln(
        '<tr style="background-color: #f2f2f2;"><th>Time</th><th>Speaker</th><th>Sentence</th></tr>',
      );
      for (var seg in segments) {
        final startMin = (seg.startTime / 60).toInt();
        final startSec = (seg.startTime % 60).toInt().toString().padLeft(
          2,
          '0',
        );
        final speakerName =
            seg.speakerProfile.value?.name ?? 'Speaker ${seg.speaker}';
        html.writeln('<tr>');
        html.writeln('<td>$startMin:$startSec</td>');
        html.writeln('<td><strong>$speakerName</strong></td>');
        html.writeln('<td>${seg.text}</td>');
        html.writeln('</tr>');
      }
      html.writeln('</table>');
    }

    html.writeln('</body></html>');

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/meeting_${meeting.id}_export.doc');
    await file.writeAsString(html.toString());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Word DOCX Report: ${meeting.title}',
      ),
    );
  }

  /// Exports as plain text layout and shares
  static Future<void> shareMeetingText(MeetingModel meeting) async {
    final summary = meeting.summary.value;
    final actionItems = meeting.actionItems.toList();
    final decisions = meeting.decisions.toList();
    final segments = meeting.transcript.value?.segments.toList() ?? [];

    final buffer = StringBuffer();
    buffer.writeln('=== MEETING SUMMARY: ${meeting.title} ===');
    if (meeting.createdAt != null) {
      buffer.writeln(
        'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(meeting.createdAt!)}',
      );
    }
    buffer.writeln('==========================================\n');

    if (summary != null) {
      if ((summary.executiveSummary ?? '').isNotEmpty) {
        buffer.writeln('EXECUTIVE SUMMARY:');
        buffer.writeln('${summary.executiveSummary}\n');
      }
      if ((summary.keyTakeaways ?? '').isNotEmpty) {
        buffer.writeln('KEY TAKEAWAYS:');
        buffer.writeln('${summary.keyTakeaways}\n');
      }
      if ((summary.risks ?? '').isNotEmpty) {
        buffer.writeln('RISKS IDENTIFIED:');
        buffer.writeln('${summary.risks}\n');
      }
      if ((summary.followUps ?? '').isNotEmpty) {
        buffer.writeln('NEXT STEPS:');
        buffer.writeln('${summary.followUps}\n');
      }
      if ((summary.deadlines ?? '').isNotEmpty) {
        buffer.writeln('DATES & DEADLINES:');
        buffer.writeln('${summary.deadlines}\n');
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
          details.write(
            ' (Due: ${DateFormat('yyyy-MM-dd').format(item.deadline!)})',
          );
        }
        buffer.writeln('$status ${item.description}$details');
      }
      buffer.writeln();
    }

    if (segments.isNotEmpty) {
      buffer.writeln('TRANSCRIPT:');
      for (var seg in segments) {
        final startMin = (seg.startTime / 60).toInt();
        final startSec = (seg.startTime % 60).toInt().toString().padLeft(
          2,
          '0',
        );
        final speakerName =
            seg.speakerProfile.value?.name ?? 'Speaker ${seg.speaker}';
        buffer.writeln('[$startMin:$startSec] $speakerName: ${seg.text}');
      }
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/meeting_${meeting.id}_export.txt');
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Text Report: ${meeting.title}',
      ),
    );
  }
}
