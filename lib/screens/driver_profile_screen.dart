import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/driver.dart';
import '../models/driving_session.dart';
import 'add_session_screen.dart';
import 'edit_session_screen.dart';
import 'timer_session_screen.dart';
import '../utils/pdf_generator.dart';
import '../utils/permission_handler.dart';
import '../widgets/driving_calendar.dart';
import 'package:intl/intl.dart';

class DriverProfileScreen extends StatefulWidget {
  final String driverId;
  const DriverProfileScreen({super.key, required this.driverId});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _dialogShown = false;

  void _onDaySelected(DateTime selectedDay, List<DrivingSession> sessions) {
    // Find sessions on the selected day
    final sessionsOnDay = sessions.where((session) {
      return session.date.year == selectedDay.year &&
          session.date.month == selectedDay.month &&
          session.date.day == selectedDay.day;
    }).toList();

    if (sessionsOnDay.isNotEmpty) {
      // If there's only one session, open it directly
      if (sessionsOnDay.length == 1) {
        _navigateToEditSession(sessionsOnDay.first);
      } else {
        // If multiple sessions, show a dialog to choose
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Sessions on ${DateFormat('MMM d, y').format(selectedDay)}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sessionsOnDay.length,
                itemBuilder: (context, index) {
                  final session = sessionsOnDay[index];
                  final duration = session.duration;
                  final hours = duration.inHours;
                  final minutes = duration.inMinutes.remainder(60);
                  return ListTile(
                    title: Text('${hours}h ${minutes}m'),
                    subtitle: Text(session.notes ?? 'No notes'),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToEditSession(session);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _navigateToEditSession(DrivingSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSessionScreen(sessionId: session.id),
      ),
    );
  }

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

            return CustomScrollView(
              slivers: [
                // Driver Info Card
                SliverToBoxAdapter(
                  child: _buildDriverInfo(driver, totalDuration, isComplete),
                ),
                // Calendar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: DrivingCalendar(
                      driverId: widget.driverId,
                      sessions: sessions,
                      onDaySelected: (day) => _onDaySelected(day, sessions),
                    ),
                  ),
                ),
                // Logs Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Driving Logs (${sessions.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Logs List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final session = sessions[index];
                      final duration = session.duration;
                      final hours = duration.inHours;
                      final minutes = duration.inMinutes.remainder(60);
                      final date = session.date;
                      final formattedDate = DateFormat('MMM d, y h:mm a').format(date);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: InkWell(
                          onTap: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditSessionScreen(sessionId: session.id!),
                              ),
                            );
                            if (updated == true) {
                              setState(() {}); // Refresh the list if session was updated
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${hours}h ${minutes}m',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                if (session.location.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    session.location,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                                if (session.notes != null && session.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    session.notes!,
                                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: sessions.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Driving Session'),
              content: const Text('Choose how to log your driving session:'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddSessionScreen(driverId: widget.driverId),
                      ),
                    );
                  },
                  child: const Text('Manual Entry'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TimerSessionScreen(driverId: widget.driverId),
                      ),
                    );
                  },
                  child: const Text('Timer Mode'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDriverInfo(Driver driver, Duration logged, bool isComplete) {
    final hours = logged.inHours;
    final minutes = logged.inMinutes.remainder(60);
    final requiredHours = driver.totalHoursRequired ?? 0;
    final progress = requiredHours > 0 ? (hours + minutes / 60) / requiredHours : 0.0;
    
    // Format progress text
    final progressText = requiredHours > 0
        ? '${_formatHours(hours + minutes / 60)} / ${_formatHours(requiredHours)} hours'
        : '${_formatHours(hours + minutes / 60)} hours';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  driver.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (isComplete)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  progressText,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            if (driver.totalHoursRequired != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.flag, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatHours(driver.totalHoursRequired!)} hours required',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatHours(hours + minutes / 60)} hours logged',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isComplete ? Colors.green : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (isComplete) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[800], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Required hours completed!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (driver.age != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${driver.age} years old',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            if (driver.notes != null && driver.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      driver.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
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
