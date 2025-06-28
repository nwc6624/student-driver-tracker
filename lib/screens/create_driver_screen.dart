import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/driver.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/background_widget.dart';

class CreateDriverScreen extends StatefulWidget {
  const CreateDriverScreen({super.key});

  @override
  State<CreateDriverScreen> createState() => _CreateDriverScreenState();
}

class _CreateDriverScreenState extends State<CreateDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _hoursController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _hoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveDriver() {
    if (_formKey.currentState!.validate()) {
      final driver = Driver(
        id: const Uuid().v4(),
        name: _nameController.text,
        age: _ageController.text.isEmpty ? null : int.tryParse(_ageController.text),
        totalHoursRequired: _hoursController.text.isEmpty 
            ? null 
            : double.tryParse(_hoursController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: DateTime.now(),
      );

      final box = Hive.box<Driver>('drivers');
      box.put(driver.id, driver);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Driver'),
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
                  child: const Text('Create Driver'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
