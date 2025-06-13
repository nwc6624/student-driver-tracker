import 'package:flutter/material.dart';
import 'package:student_driver_tracker/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/driver.dart';
import 'models/driving_session.dart';
import 'providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/about_screen.dart';
import 'screens/add_session_screen.dart';
import 'screens/create_driver_screen.dart';
import 'screens/driver_profile_screen.dart';
import 'adapters/duration_adapter.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(DurationAdapter());
  Hive.registerAdapter(DriverAdapter());
  Hive.registerAdapter(DrivingSessionAdapter());
  
  // Open boxes
  await Hive.openBox<Driver>('drivers');
  await Hive.openBox<DrivingSession>('driving_sessions');
  
  final sharedPreferences = await SharedPreferences.getInstance();
  
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(ThemeProvider.provider);
    final themeProvider = ref.watch(ThemeProvider.provider.notifier);
    
    return MaterialApp(
      title: 'Student Driver Tracker',
      theme: AppTheme.lightTheme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      builder: (context, child) {
        final theme = Theme.of(context);
        final appTheme = theme.extension<AppThemeExtension>();
        
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(appTheme?.backgroundImage ?? 'assets/images/light_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: child,
        );
      },
      home: const HomeScreen(),
      routes: {
        '/create-driver': (context) => const CreateDriverScreen(),
        '/driver-profile': (context) => DriverProfileScreen(
          driverId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/add-session': (context) => AddSessionScreen(
          driverId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Driver Tracker'),
        actions: [
          Consumer(
            builder: (context, ref, child) => IconButton(
              icon: Icon(ref.watch(ThemeProvider.provider) == ThemeMode.dark 
                  ? Icons.light_mode 
                  : Icons.dark_mode),
              onPressed: () {
                ref.read(ThemeProvider.provider.notifier).toggleTheme();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/about');
            },
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Drivers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _DriverList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-driver');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Placeholder for driver list
class _DriverList extends StatelessWidget {
  const _DriverList();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Driver>>(
      valueListenable: Hive.box<Driver>('drivers').listenable(),
      builder: (context, box, _) {
        final drivers = box.values.toList();
        if (drivers.isEmpty) {
          return const Center(
            child: Text('No drivers added yet'),
          );
        }
        return ListView.builder(
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];
            return Card(
              child: ListTile(
                title: Text(driver.name),
                subtitle: driver.age != null
                    ? Text('${driver.age} years old')
                    : null,
                trailing: Text(
                  '${driver.totalHoursRequired ?? 0} hours required',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/driver-profile',
                    arguments: driver.id,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
