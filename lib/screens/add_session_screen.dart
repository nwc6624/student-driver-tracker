import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/driving_session.dart';
import '../models/driver.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/permission_handler.dart';
import '../widgets/background_widget.dart';

class AddSessionScreen extends StatefulWidget {
  final String driverId;
  final DrivingSession? sessionToEdit;
  const AddSessionScreen({
    super.key, 
    required this.driverId, 
    this.sessionToEdit,
  });

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isEditing = false;
  String? _selectedWeather;

  final List<String> _weatherOptions = [
    'Clear',
    'Cloudy',
    'Rain',
    'Snow',
    'Fog',
    'Windy',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.sessionToEdit != null;
    if (_isEditing && widget.sessionToEdit != null) {
      final session = widget.sessionToEdit!;
      _durationController.text = session.durationMinutes.toString();
      _locationController.text = session.location;
      _notesController.text = session.notes ?? '';
      _selectedDate = session.date;
      _selectedWeather = session.weatherConditions;
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (await PermissionHandler.requestLocationPermission()) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _locationController.text = 'Lat: ${position.latitude}, Lon: ${position.longitude}';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get location')),
      );
    }
  }

  void _saveSession() {
    if (_formKey.currentState!.validate()) {
      final duration = int.tryParse(_durationController.text) ?? 0;
      
      final sessionsBox = Hive.box<DrivingSession>('driving_sessions');
      final driversBox = Hive.box<Driver>('drivers');
      
      if (_isEditing && widget.sessionToEdit != null) {
        // Find the existing session and update it
        final sessions = sessionsBox.values.toList();
        final sessionIndex = sessions.indexWhere((session) => session.id == widget.sessionToEdit!.id);
        
        if (sessionIndex != -1) {
          // Update existing session
          final updatedSession = DrivingSession(
            id: widget.sessionToEdit!.id,
            driverId: widget.driverId,
            durationMinutes: duration,
            date: _selectedDate,
            location: _locationController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            weatherConditions: _selectedWeather,
          );
          
          sessionsBox.putAt(sessionIndex, updatedSession);
          
          // Check for goal completion before navigation
          _checkGoalCompletion();
          
          Navigator.pop(context);
          
          // Show success message using the parent context
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Session not found, show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Session not found'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Create new session
        final session = DrivingSession(
          id: const Uuid().v4(),
          driverId: widget.driverId,
          durationMinutes: duration,
          date: _selectedDate,
          location: _locationController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          weatherConditions: _selectedWeather,
        );

        sessionsBox.add(session);
        
        // Check for goal completion before navigation
        _checkGoalCompletion();
        
        Navigator.pop(context);
      }
    }
  }

  void _checkGoalCompletion() {
    final driversBox = Hive.box<Driver>('drivers');
    final sessionsBox = Hive.box<DrivingSession>('driving_sessions');
    
    final driver = driversBox.get(widget.driverId);
    if (driver == null || driver.totalHoursRequired == null) return;
    
    // Calculate total hours completed
    final sessions = sessionsBox.values
        .where((session) => session.driverId == widget.driverId)
        .toList();
    
    final totalHoursCompleted = sessions.fold<double>(
      0.0, 
      (sum, session) => sum + session.hours
    );
    
    // Check if goal is reached and popup hasn't been shown yet
    if (totalHoursCompleted >= driver.totalHoursRequired! && !driver.goalCompletedShown) {
      // Update driver to mark goal completion as shown
      final updatedDriver = driver.copyWith(goalCompletedShown: true);
      driversBox.put(widget.driverId, updatedDriver);
      
      // Show congratulations popup after a short delay to ensure navigation is complete
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          _showGoalCompletionDialog(driver.name, driver.totalHoursRequired!);
        }
      });
    }
  }

  void _showGoalCompletionDialog(String driverName, double requiredHours) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.orange),
            SizedBox(width: 8),
            Text('Goal Reached!'),
          ],
        ),
        content: Text(
          'Congratulations! You\'ve completed the required ${requiredHours.toStringAsFixed(1)} driving hours for $driverName!',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/export',
                arguments: widget.driverId,
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Session' : 'Log New Session'),
      ),
      body: BackgroundWidget(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Date/Time
                ListTile(
                  title: Text('Date: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                const SizedBox(height: 16),
                // Duration
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter duration';
                    }
                    final intValue = int.tryParse(value);
                    if (intValue == null || intValue <= 0) {
                      return 'Enter a valid duration';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Location
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location),
                      tooltip: 'Use GPS',
                      onPressed: _getCurrentLocation,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Weather Conditions
                DropdownButtonFormField<String>(
                  value: _selectedWeather,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Weather (optional)'),
                    ),
                    ..._weatherOptions.map((weather) => DropdownMenuItem<String>(
                          value: weather,
                          child: Text(weather),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedWeather = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveSession,
                        child: Text(_isEditing ? 'Save Changes' : 'Save Session'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
