import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/driving_session.dart';
import '../utils/permission_handler.dart';

class EditSessionScreen extends StatefulWidget {
  final String sessionId;
  
  const EditSessionScreen({super.key, required this.sessionId});

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  late final Box<DrivingSession> _sessionsBox;
  late DrivingSession _session;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late TextEditingController _durationController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _sessionsBox = Hive.box<DrivingSession>('driving_sessions');
    _session = _sessionsBox.get(widget.sessionId)!;
    _locationController = TextEditingController(text: _session.location);
    _notesController = TextEditingController(text: _session.notes ?? '');
    _durationController = TextEditingController(
      text: '${_session.duration.inMinutes}',
    );
    _selectedDate = _session.date;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final BuildContext dialogContext = context;
    final DateTime? picked = await showDatePicker(
      context: dialogContext,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location')),
        );
      }
    }
  }

  void _saveChanges() {
    final duration = int.tryParse(_durationController.text) ?? 0;
    
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid duration')),
      );
      return;
    }

    final updatedSession = _session.copyWith(
      duration: Duration(minutes: duration),
      date: _selectedDate,
      location: _locationController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    _sessionsBox.put(widget.sessionId, updatedSession);
    Navigator.pop(context, true); // Return true to indicate successful update
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View/Edit Driving Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Picker
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Date',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
                border: const OutlineInputBorder(),
              ),
              controller: TextEditingController(
                text: DateFormat.yMMMd().format(_selectedDate),
              ),
              readOnly: true,
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
            ),
            const SizedBox(height: 16),
            
            // Location
            TextFormField(
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
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
