import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/driving_session.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/permission_handler.dart';
import '../utils/date_formatter.dart';

class AddSessionScreen extends StatefulWidget {
  final String driverId;
  const AddSessionScreen({super.key, required this.driverId});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
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

  @override
  void dispose() {
    _durationController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      final BuildContext dialogContext = context;
      final DateTime? picked = await showDatePicker(
        context: dialogContext,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100), // Extended the last date to 2100
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
    if (_formKey.currentState!.validate()) {
      final minutes = int.parse(_durationController.text);
      
      final session = DrivingSession(
        id: const Uuid().v4(),
        driverId: widget.driverId,
        duration: Duration(minutes: minutes),
        date: _selectedDate,
        location: _locationController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final box = Hive.box<DrivingSession>('driving_sessions');
      box.put(session.id, session);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Driving Session'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: _dateController,
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSession,
                child: const Text('Save Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
