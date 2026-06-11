// =============================================
// MAIN.DART - Final Version
// Sets up providers and launches the real app
// =============================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'providers/category_provider.dart';
import 'providers/task_provider.dart';
import 'providers/note_provider.dart';
import 'providers/roadmap_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/app_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      final db = await DatabaseHelper.instance.database;
      final cats = await db.query('categories');
      debugPrint('✅ DB ready: ${cats.length} categories');
    } catch (e) {
      debugPrint('❌ DB error: $e');
    }
  }

  runApp(const ProductivityAppRoot());
}

class ProductivityAppRoot extends StatelessWidget {
  const ProductivityAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = SettingsProvider();
    final categoryProvider = CategoryProvider();
    final taskProvider = TaskProvider();
    final noteProvider = NoteProvider();
    final roadmapProvider = RoadmapProvider();
    final notificationProvider = NotificationProvider();

    final appProvider = AppProvider(
      settings: settingsProvider,
      categories: categoryProvider,
      tasks: taskProvider,
      notes: noteProvider,
      roadmap: roadmapProvider,
      notifications: notificationProvider,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: categoryProvider),
        ChangeNotifierProvider.value(value: taskProvider),
        ChangeNotifierProvider.value(value: noteProvider),
        ChangeNotifierProvider.value(value: roadmapProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: const ProductivityApp(),
    );
  }
}

class ProductivityApp extends StatelessWidget {
  const ProductivityApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Trackeon',
      debugShowCheckedModeBanner: false,
      theme: settingsProvider.getThemeData(),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    if (appProvider.isLoading) {
      return const _LoadingScreen();
    }

    if (appProvider.error != null) {
      return _ErrorScreen(
        error: appProvider.error!,
        onRetry: () => context.read<AppProvider>().initialize(),
      );
    }

    return const DashboardScreen();
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F46E5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚡', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            const Text(
              'Productivity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('❌', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(error, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}