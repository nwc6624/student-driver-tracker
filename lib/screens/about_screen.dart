import 'package:flutter/material.dart';
import '../widgets/background_widget.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: BackgroundWidget(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Student Driver Tracker',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Track supervised driving sessions for teen drivers. Create profiles, log sessions, and monitor progress toward required hours.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Text(
                'Features:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('• Create and manage driver profiles'),
              const Text('• Log individual driving sessions'),
              const Text('• Track progress toward required hours'),
              const Text('• Export driving logs as PDF'),
              const Text('• Light and dark mode support'),
              const SizedBox(height: 24),
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
