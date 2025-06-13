import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/driver.dart';
import '../models/driving_session.dart';
import 'add_session_screen.dart';
import '../utils/pdf_generator.dart';
import '../utils/permission_handler.dart';

class DriverProfileScreen extends StatefulWidget {
  final String driverId;
  const DriverProfileScreen({super.key, required this.driverId});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final driversBox = Hive.box<Driver>('drivers');
    final sessionsBox = Hive.box<DrivingSession>('driving_sessions');
    
    final driver = driversBox.get(widget.driverId);
    if (driver == null) {
      return const Scaffold(
        body: Center(child: Text('Driver not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(driver.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Options'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: const Text('Export to PDF'),
                        onTap: () async {
                          if (await PermissionHandler.requestStoragePermission()) {
                            final sessions = sessionsBox.values
                                .where((session) => session.driverId == widget.driverId)
                                .toList()
                                ..sort((a, b) => b.date.compareTo(a.date));
                            
                            await PDFGenerator.generateDriverLogPDF(driver, sessions);
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Storage permission denied')),
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text('Delete Driver'),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Driver'),
                              content: const Text('Are you sure you want to delete this driver?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    driversBox.delete(widget.driverId);
                                    sessionsBox.values
                                        .where((session) => session.driverId == widget.driverId)
                                        .forEach((session) => sessionsBox.delete(session.id));
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDriverInfo(driver),
            const SizedBox(height: 24),
            Expanded(
              child: ValueListenableBuilder<Box<DrivingSession>>(
                valueListenable: sessionsBox.listenable(),
                builder: (context, box, _) {
                  final sessions = box.values
                      .where((session) => session.driverId == widget.driverId)
                      .toList()
                      ..sort((a, b) => b.date.compareTo(a.date));
                  
                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${session.hours.toStringAsFixed(1)} hours',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${session.date.year}-${session.date.month}-${session.date.day}',
                              ),
                              Text(session.location),
                              if (session.notes != null && session.notes!.isNotEmpty)
                                Text(session.notes!),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Session'),
                                  content: const Text('Are you sure you want to delete this session?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        sessionsBox.delete(session.id);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddSessionScreen(driverId: widget.driverId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDriverInfo(Driver driver) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              driver.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (driver.age != null)
              Text(
                '${driver.age} years old',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (driver.totalHoursRequired != null)
              Text(
                '${driver.totalHoursRequired} hours required',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (driver.notes != null && driver.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  driver.notes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
