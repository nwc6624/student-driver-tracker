import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/driver.dart';
import '../models/driving_session.dart';
import '../utils/pdf_generator.dart';
import '../widgets/background_widget.dart';
import 'add_session_screen.dart';
import 'edit_driver_screen.dart';

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
      // Redirect to home screen if driver not found
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
      return Scaffold(
        appBar: AppBar(
          title: const Text('Driver Profile'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(driver.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final sessionsBox = Hive.box<DrivingSession>('driving_sessions');
              final sessions = sessionsBox.values
                  .where((session) => session.driverId == widget.driverId)
                  .toList()
                  ..sort((a, b) => b.date.compareTo(a.date));
              
              await PDFGenerator.sharePDF(driver, sessions);
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/export',
                arguments: widget.driverId,
              );
            },
          ),
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
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit Driver'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditDriverScreen(driverId: widget.driverId),
                            ),
                          );
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
                                    
                                    // Delete all sessions for this driver
                                    final sessions = sessionsBox.values.toList();
                                    final sessionsToDelete = sessions
                                        .where((session) => session.driverId == widget.driverId)
                                        .toList();
                                    
                                    // Delete sessions in reverse order to maintain correct indices
                                    for (int i = sessions.length - 1; i >= 0; i--) {
                                      if (sessions[i].driverId == widget.driverId) {
                                        sessionsBox.deleteAt(i);
                                      }
                                    }
                                    
                                    Navigator.pop(context); // Close dialog
                                    Navigator.pushReplacementNamed(context, '/home'); // Go to home screen
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
      body: BackgroundWidget(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<Box<DrivingSession>>(
                valueListenable: sessionsBox.listenable(),
                builder: (context, box, _) {
                  return _buildDriverInfo(driver);
                },
              ),
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
                          child: InkWell(
                            onTap: () => _showSessionOptions(context, session),
                            child: ListTile(
                              title: Text(
                                '${session.hours.toStringAsFixed(1)} hours',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${session.date.year}-${session.date.month.toString().padLeft(2, '0')}-${session.date.day.toString().padLeft(2, '0')}',
                                  ),
                                  Text(session.location),
                                  if (session.weatherConditions != null && session.weatherConditions!.isNotEmpty)
                                    Text('Weather: ${session.weatherConditions!}'),
                                  if (session.notes != null && session.notes!.isNotEmpty)
                                    Text(session.notes!),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

  void _showSessionOptions(BuildContext context, DrivingSession session) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Session'),
              onTap: () {
                Navigator.pop(context);
                _editSession(context, session);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Session', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteSession(context, session);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editSession(BuildContext context, DrivingSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSessionScreen(
          driverId: widget.driverId,
          sessionToEdit: session,
        ),
      ),
    );
  }

  void _deleteSession(BuildContext context, DrivingSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to delete this session? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final sessionsBox = Hive.box<DrivingSession>('driving_sessions');
              
              // Find the session by ID and delete it by index
              final sessions = sessionsBox.values.toList();
              final sessionIndex = sessions.indexWhere((s) => s.id == session.id);
              
              if (sessionIndex != -1) {
                sessionsBox.deleteAt(sessionIndex);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session deleted successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Session not found'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfo(Driver driver) {
    final sessionsBox = Hive.box<DrivingSession>('driving_sessions');
    final sessions = sessionsBox.values
        .where((session) => session.driverId == widget.driverId)
        .toList();
    
    final totalHoursCompleted = sessions.fold<double>(
      0.0, 
      (sum, session) => sum + session.hours
    );
    
    final progress = driver.totalHoursRequired != null 
        ? (totalHoursCompleted / driver.totalHoursRequired!).clamp(0.0, 1.0)
        : 0.0;
    final completed = driver.totalHoursRequired != null && totalHoursCompleted >= driver.totalHoursRequired!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    driver.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                if (completed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            if (driver.age != null)
              Text(
                '${driver.age} years old',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${totalHoursCompleted.toStringAsFixed(1)} hours completed',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (driver.totalHoursRequired != null)
                        Text(
                          '${driver.totalHoursRequired} hours required',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (driver.totalHoursRequired != null)
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: progress >= 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),
              ],
            ),
            if (driver.totalHoursRequired != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.green : Colors.blue,
                ),
              ),
            ],
            if (driver.notes != null && driver.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
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
