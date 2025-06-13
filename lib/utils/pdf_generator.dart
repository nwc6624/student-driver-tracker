import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../models/driver.dart';
import '../models/driving_session.dart';
import 'dart:io';

class PDFGenerator {
  static Future<void> generateDriverLogPDF(Driver driver, List<DrivingSession> sessions) async {
    final pdf = pw.Document();

    // Add title page
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Driving Log',
                style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                driver.name,
                style: pw.TextStyle(fontSize: 24),
              ),
              if (driver.age != null)
                pw.Text(
                  '${driver.age} years old',
                  style: pw.TextStyle(fontSize: 16),
                ),
              if (driver.totalHoursRequired != null)
                pw.Text(
                  '${driver.totalHoursRequired} hours required',
                  style: pw.TextStyle(fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );

    // Add sessions table
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Text(
              'Driving Sessions',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Center(child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Center(child: pw.Text('Duration', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Center(child: pw.Text('Location', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Center(child: pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...sessions.map((session) => pw.TableRow(
                  children: [
                    pw.Center(child: pw.Text('${session.date.year}-${session.date.month}-${session.date.day}')),
                    pw.Center(child: pw.Text('${session.hours.toStringAsFixed(1)} hours')), // Convert minutes to hours
                    pw.Center(child: pw.Text(session.location)),
                    pw.Center(child: pw.Text(session.notes ?? '')),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );

    // Save and open PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/driving_log_${driver.name.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the PDF
    await OpenFile.open(file.path);
  }
}
