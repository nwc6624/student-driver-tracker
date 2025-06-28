import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/driver.dart';
import 'models/driving_session.dart';
import 'providers/theme_provider.dart';
import 'providers/background_provider.dart';
import 'widgets/background_widget.dart';
import 'screens/splash_screen.dart';
import 'screens/create_driver_screen.dart';
import 'screens/driver_profile_screen.dart';
import 'screens/add_session_screen.dart';
import 'screens/about_screen.dart';
import 'screens/export_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(DriverAdapter());
  Hive.registerAdapter(DrivingSessionAdapter());
  
  // Open boxes
  await Hive.openBox<Driver>('drivers');
  await Hive.openBox<DrivingSession>('driving_sessions');
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'Student Driver Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD2691E), // Southwestern orange
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8B4513), // Saddle brown
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD2691E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFD2691E),
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD2691E), // Southwestern orange
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF654321), // Dark brown
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD2691E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFD2691E),
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/create-driver': (context) => const CreateDriverScreen(),
        '/driver-profile': (context) => DriverProfileScreen(
          driverId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/add-session': (context) => AddSessionScreen(
          driverId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/export': (context) => ExportScreen(
          driverId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Driver Tracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(ref.watch(themeProvider) == ThemeMode.dark 
                ? Icons.light_mode 
                : Icons.dark_mode),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: BackgroundWidget(
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // App Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFD2691E), Color(0xFF8B4513)],
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Create New Driver Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/create-driver');
                      },
                      icon: const Icon(Icons.person_add, size: 24),
                      label: const Text(
                        'Create New Driver',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: const Color(0xFFD2691E),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Existing Drivers Section
                  const Text(
                    'Existing Drivers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Driver List
                  Expanded(
                    child: _DriverList(),
                  ),
                ],
              ),
            ),
            
            // Help Icon in bottom-right corner
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/about');
                },
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                mini: true,
                child: const Icon(Icons.help_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Driver list widget
class _DriverList extends ConsumerWidget {
  const _DriverList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<Box<Driver>>(
      valueListenable: Hive.box<Driver>('drivers').listenable(),
      builder: (context, box, _) {
        final drivers = box.values.toList();
        if (drivers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No drivers added yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap "Create New Driver" to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/driver-profile',
                    arguments: driver.id,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFD2691E),
                        child: Text(
                          driver.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (driver.age != null)
                              Text(
                                '${driver.age} years old',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (driver.totalHoursRequired != null)
                              Text(
                                '${driver.totalHoursRequired} hours required',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
