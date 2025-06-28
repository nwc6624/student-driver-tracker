import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../models/driver.dart';
import '../models/driving_session.dart';
import '../utils/pdf_generator.dart';
import '../widgets/background_widget.dart';

class ExportScreen extends StatelessWidget {
  final String driverId;
  const ExportScreen({super.key, required this.driverId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Driving Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePDF(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePDF(context),
          ),
        ],
      ),
      body: BackgroundWidget(
        child: ValueListenableBuilder<Box<Driver>>(
          valueListenable: Hive.box<Driver>('drivers').listenable(),
          builder: (context, driverBox, _) {
            final driver = driverBox.values.firstWhere((d) => d.id == driverId);
            
            return ValueListenableBuilder<Box<DrivingSession>>(
              valueListenable: Hive.box<DrivingSession>('driving_sessions').listenable(),
              builder: (context, sessionBox, _) {
                final sessions = sessionBox.values
                    .where((s) => s.driverId == driverId)
                    .toList()
                  ..sort((a, b) => b.date.compareTo(a.date));
                
                final totalHours = sessions.fold<double>(
                  0, (sum, session) => sum + session.hours);
                
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Driver: ${driver.name}',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              if (driver.age != null) ...[
                                const SizedBox(height: 8),
                                Text('Age: ${driver.age} years'),
                              ],
                              const SizedBox(height: 8),
                              Text('Total Hours: ${totalHours.toStringAsFixed(1)}'),
                              if (driver.totalHoursRequired != null) ...[
                                Text('Required Hours: ${driver.totalHoursRequired}'),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: totalHours / driver.totalHoursRequired!,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Driving Sessions (${sessions.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: sessions.isEmpty
                            ? const Center(
                                child: Text('No sessions recorded yet'),
                              )
                            : ListView.builder(
                                itemCount: sessions.length,
                                itemBuilder: (context, index) {
                                  final session = sessions[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(
                                        DateFormat('MMM dd, yyyy').format(session.date),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Duration: ${session.hours.toStringAsFixed(1)} hours'),
                                          if (session.location.isNotEmpty)
                                            Text('Location: ${session.location}'),
                                          if (session.weatherConditions != null && session.weatherConditions!.isNotEmpty)
                                            Text('Weather: ${session.weatherConditions}'),
                                          if (session.notes != null && session.notes!.isNotEmpty)
                                            Text('Notes: ${session.notes}'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _generatePDF(BuildContext context) async {
    try {
      final driverBox = Hive.box<Driver>('drivers');
      final sessionBox = Hive.box<DrivingSession>('driving_sessions');
      
      final driver = driverBox.values.firstWhere((d) => d.id == driverId);
      final sessions = sessionBox.values
          .where((s) => s.driverId == driverId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      
      final totalHours = sessions.fold<double>(
        0, (sum, session) => sum + session.hours);
      
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Student Driver Tracker - Driving Log'),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Driver: ${driver.name}'),
                if (driver.age != null) pw.Text('Age: ${driver.age} years'),
                pw.Text('Total Hours: ${totalHours.toStringAsFixed(1)}'),
                if (driver.totalHoursRequired != null)
                  pw.Text('Required Hours: ${driver.totalHoursRequired}'),
                pw.SizedBox(height: 20),
                pw.Text('Driving Sessions', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...sessions.map((session) => pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(DateFormat('MMM dd, yyyy').format(session.date)),
                      pw.Text('Duration: ${session.hours.toStringAsFixed(1)} hours'),
                      if (session.location.isNotEmpty)
                        pw.Text('Location: ${session.location}'),
                      if (session.weatherConditions != null && session.weatherConditions!.isNotEmpty)
                        pw.Text('Weather: ${session.weatherConditions}'),
                      if (session.notes != null && session.notes!.isNotEmpty)
                        pw.Text('Notes: ${session.notes}'),
                      pw.Divider(),
                    ],
                  ),
                )),
              ],
            );
          },
        ),
      );
      
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/driving_log_${driver.name.replaceAll(' ', '_')}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved to: ${file.path}')),
        );
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  Future<void> _sharePDF(BuildContext context) async {
    try {
      final driverBox = Hive.box<Driver>('drivers');
      final sessionBox = Hive.box<DrivingSession>('driving_sessions');
      
      final driver = driverBox.values.firstWhere((d) => d.id == driverId);
      final sessions = sessionBox.values
          .where((s) => s.driverId == driverId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      
      await PDFGenerator.sharePDF(driver, sessions);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing PDF: $e')),
        );
      }
    }
  }
} 