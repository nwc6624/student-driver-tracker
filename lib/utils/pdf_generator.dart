import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
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
                    pw.Center(child: pw.Text('Weather', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Center(child: pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...sessions.map((session) => pw.TableRow(
                  children: [
                    pw.Center(child: pw.Text('${session.date.year}-${session.date.month}-${session.date.day}')),
                    pw.Center(child: pw.Text('${session.hours.toStringAsFixed(1)} hours')),
                    pw.Center(child: pw.Text(session.location)),
                    pw.Center(child: pw.Text(session.weatherConditions ?? '')),
                    pw.Center(child: pw.Text(session.notes ?? '')),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Summary',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Total Hours Completed: ${sessions.fold<double>(0.0, (sum, s) => sum + s.hours).toStringAsFixed(1)}'),
            if (driver.totalHoursRequired != null)
              pw.Text('Required Hours: ${driver.totalHoursRequired}'),
            if (driver.totalHoursRequired != null && sessions.fold<double>(0.0, (sum, s) => sum + s.hours) >= driver.totalHoursRequired!)
              pw.Text('Status: COMPLETED', style: pw.TextStyle(color: PdfColors.green, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/driving_log_${driver.name.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Show sharing options
    await _showSharingOptions(file, driver.name);
  }

  static Future<void> _showSharingOptions(File file, String driverName) async {
    final result = await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Driving Log for $driverName',
      subject: 'Student Driver Log - $driverName',
    );

    if (result.status == ShareResultStatus.success) {
      // Share was successful
      print('PDF shared successfully');
    } else if (result.status == ShareResultStatus.dismissed) {
      // User dismissed the share sheet, open the file locally
      await OpenFile.open(file.path);
    }
  }

  static Future<void> sharePDF(Driver driver, List<DrivingSession> sessions) async {
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
                    pw.Center(child: pw.Text('Weather', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Center(child: pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...sessions.map((session) => pw.TableRow(
                  children: [
                    pw.Center(child: pw.Text('${session.date.year}-${session.date.month}-${session.date.day}')),
                    pw.Center(child: pw.Text('${session.hours.toStringAsFixed(1)} hours')),
                    pw.Center(child: pw.Text(session.location)),
                    pw.Center(child: pw.Text(session.weatherConditions ?? '')),
                    pw.Center(child: pw.Text(session.notes ?? '')),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Summary',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Total Hours Completed: ${sessions.fold<double>(0.0, (sum, s) => sum + s.hours).toStringAsFixed(1)}'),
            if (driver.totalHoursRequired != null)
              pw.Text('Required Hours: ${driver.totalHoursRequired}'),
            if (driver.totalHoursRequired != null && sessions.fold<double>(0.0, (sum, s) => sum + s.hours) >= driver.totalHoursRequired!)
              pw.Text('Status: COMPLETED', style: pw.TextStyle(color: PdfColors.green, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/driving_log_${driver.name.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Share the PDF
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Driving Log for ${driver.name}',
      subject: 'Student Driver Log - ${driver.name}',
    );
  }
}
