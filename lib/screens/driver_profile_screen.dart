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
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final driversBox = Hive.box<Driver>('drivers');
    final sessionsBox = Hive.box<DrivingSession>('driving_sessions');
    
    final driver = driversBox.get(widget.driverId);
    if (driver == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver not found')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Driver not found'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Return Home'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Delete Profile'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  // Driver might have been stored with an auto increment key, so search by id field.
                  final key = driversBox.keys.firstWhere(
                    (k) {
                      final d = driversBox.get(k);
                      return d is Driver && d.id == widget.driverId;
                    },
                    orElse: () => null,
                  );
                  if (key != null) {
                    driversBox.delete(key);
                  }
                  sessionsBox.values
                      .where((s) => s.driverId == widget.driverId)
                      .forEach((s) => sessionsBox.delete(s.id));
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
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
                                    // Driver might have been stored with an auto increment key, so search by id field.
                                    final key = driversBox.keys.firstWhere(
                                      (k) {
                                        final d = driversBox.get(k);
                                        return d is Driver && d.id == widget.driverId;
                                      },
                                      orElse: () => null,
                                    );
                                    if (key != null) {
                                      driversBox.delete(key);
                                    }
                                    sessionsBox.values
                                        .where((session) => session.driverId == widget.driverId)
                                        .forEach((session) => sessionsBox.delete(session.id));
                                    Navigator.of(context).popUntil((route) => route.isFirst);
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
        child: ValueListenableBuilder<Box<DrivingSession>>(
          valueListenable: sessionsBox.listenable(),
          builder: (context, box, _) {
            final sessions = box.values
                .where((session) => session.driverId == widget.driverId)
                .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

            final totalDuration = sessions.fold<Duration>(
                Duration.zero, (prev, s) => prev + s.duration);
            final totalMinutes = totalDuration.inMinutes;
            final totalHours = totalMinutes / 60.0;
            final requiredHours = driver.totalHoursRequired ?? 0;
            final isComplete = totalHours >= requiredHours && requiredHours > 0;

            // show congratulations dialog once per screen build when completed
            if (isComplete && !_dialogShown) {
              _dialogShown = true;
              Future.microtask(() {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Congratulations!'),
                    content: Text(
                      "You've completed your required hours!\n\nRequired: ${_formatHours(requiredHours)} hrs\nLogged: ${_formatDuration(totalDuration)}\nTotal logs: ${sessions.length}",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDriverInfo(driver, totalDuration, isComplete),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${session.duration.inMinutes} minutes',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${session.date.year}-${session.date.month}-${session.date.day}'),
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
                  ),
                ),
              ],
            );
          },
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

  Widget _buildDriverInfo(Driver driver, Duration logged, bool isComplete) {
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
            Text(
              'Logged: ${_formatDuration(logged)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isComplete ? Colors.green : null,
                  ),
            ),
            if (isComplete)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Driving Hours Complete',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final hrs = minutes / 60.0;
    final hrsStr = _formatHours(hrs);
    if (minutes >= 60) {
      return '$hrsStr hrs ($minutes minutes)';
    }
    return '$hrsStr hrs ($minutes minutes)';
  }

  String _formatHours(double hrs) {
    if (hrs % 1 == 0) {
      return hrs.toStringAsFixed(0);
    }
    // keep up to 2 decimal places, remove trailing zeros
    String s = hrs.toStringAsFixed(2);
    if (s.endsWith('0')) s = s.substring(0, s.length - 1);
    if (s.endsWith('0')) s = s.substring(0, s.length - 1);
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }
}
