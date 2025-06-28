import 'package:flutter/material.dart';
import '../models/driver.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/background_widget.dart';

class EditDriverScreen extends StatefulWidget {
  final String driverId;
  const EditDriverScreen({super.key, required this.driverId});

  @override
  State<EditDriverScreen> createState() => _EditDriverScreenState();
}

class _EditDriverScreenState extends State<EditDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _hoursController = TextEditingController();
  final _notesController = TextEditingController();
  Driver? _originalDriver;
  double? _originalRequiredHours;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  void _loadDriverData() {
    final driversBox = Hive.box<Driver>('drivers');
    final driver = driversBox.get(widget.driverId);
    if (driver != null) {
      _originalDriver = driver;
      _originalRequiredHours = driver.totalHoursRequired;
      
      _nameController.text = driver.name;
      _ageController.text = driver.age?.toString() ?? '';
      _hoursController.text = driver.totalHoursRequired?.toString() ?? '';
      _notesController.text = driver.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _hoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveDriver() {
    if (_formKey.currentState!.validate() && _originalDriver != null) {
      final newRequiredHours = _hoursController.text.isEmpty 
          ? null 
          : double.tryParse(_hoursController.text);
      
      // Check if required hours were increased
      bool shouldResetGoalCompletion = false;
      if (_originalRequiredHours != null && newRequiredHours != null) {
        if (newRequiredHours > _originalRequiredHours!) {
          shouldResetGoalCompletion = true;
        }
      }
      
      final updatedDriver = _originalDriver!.copyWith(
        name: _nameController.text,
        age: _ageController.text.isEmpty ? null : int.tryParse(_ageController.text),
        totalHoursRequired: newRequiredHours,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        goalCompletedShown: shouldResetGoalCompletion ? false : _originalDriver!.goalCompletedShown,
      );

      final box = Hive.box<Driver>('drivers');
      box.put(widget.driverId, updatedDriver);

      Navigator.pop(context);
      
      if (shouldResetGoalCompletion) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal completion status has been reset for the new target'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_originalDriver == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Driver'),
        ),
        body: const Center(
          child: Text('Driver not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Driver'),
      ),
      body: BackgroundWidget(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _hoursController,
                  decoration: const InputDecoration(
                    labelText: 'Total Hours Required (optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Increasing this value will reset goal completion status',
                  ),
                  keyboardType: TextInputType.number,
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
                  onPressed: _saveDriver,
                  child: const Text('Update Driver'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 