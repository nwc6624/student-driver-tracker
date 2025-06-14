import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/driving_session.dart';
import '../utils/permission_handler.dart';
import '../utils/date_formatter.dart';

class TimerSessionScreen extends StatefulWidget {
  final String driverId;
  const TimerSessionScreen({super.key, required this.driverId});

  @override
  State<TimerSessionScreen> createState() => _TimerSessionScreenState();
}

class _TimerSessionScreenState extends State<TimerSessionScreen> {
  bool _isRunning = false;
  Duration _elapsed = Duration.zero;
  Duration _totalElapsed = Duration.zero;
  DateTime? _startTime;
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final _dateController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _updateDateText();
  }
  
  void _updateDateText() {
    _dateController.text = DateFormatter.formatDate(_selectedDate);
  }
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _locationController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _startTimer() async {
    setState(() {
      _isRunning = true;
      _startTime = DateTime.now().subtract(_elapsed);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _elapsed = DateTime.now().difference(_startTime!);
            // Update total elapsed time when timer is running
            _totalElapsed = Duration(seconds: _elapsed.inSeconds);
            // Save the current elapsed time periodically
            _saveTimerState();
          });
        }
      });
    });
  }
  
  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_elapsed_seconds', _elapsed.inSeconds);
  }

  Future<void> _stopTimer() async {
    setState(() {
      _isRunning = false;
      _totalElapsed = _elapsed; // Only keep the current elapsed time
      _timer?.cancel();
      _saveTimerState();
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  Future<void> _resetTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_elapsed_seconds');
    
    setState(() {
      _isRunning = false;
      _elapsed = Duration.zero;
      _totalElapsed = Duration.zero;
      _timer?.cancel();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    // Create a new context that won't be disposed when the dialog is shown
    final BuildContext dialogContext = context;
    
    try {
      final DateTime? picked = await showDatePicker(
        context: dialogContext,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100), // Extended to a more reasonable future date
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).primaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
      
      if (picked != null && picked != _selectedDate) {
        if (mounted) {
          setState(() {
            _selectedDate = picked;
            _updateDateText();
          });
        }
      }
    } catch (e) {
      debugPrint('Error showing date picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to show date picker')),
        );
      }
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
    if (_totalElapsed.inSeconds < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum session time is 1 minute')),
      );
      return;
    }

    final session = DrivingSession(
      id: const Uuid().v4(),
      driverId: widget.driverId,
      duration: _totalElapsed,
      date: _selectedDate,
      location: _locationController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    final box = Hive.box<DrivingSession>('driving_sessions');
    box.put(session.id, session);

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = _totalElapsed.inMinutes % 60;
    final totalHours = _totalElapsed.inHours;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer Mode'),
        actions: [
          if (_totalElapsed > Duration.zero)
            TextButton(
              onPressed: _saveSession,
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_elapsed.inHours.toString().padLeft(2, '0')}:${(_elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _toggleTimer,
                  child: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                ),
                if (!_isRunning && _elapsed > Duration.zero)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: _saveSession,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                FloatingActionButton(
                  onPressed: _resetTimer,
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
            const Divider(height: 40),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Date',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () {
                    _selectDate(context);
                  },
                ),
              ),
              controller: _dateController,
              readOnly: true,
              onTap: () {
                _selectDate(context);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _getCurrentLocation,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
