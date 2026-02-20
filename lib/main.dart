import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:provider/provider.dart';
import 'data/models/task.dart';
import 'data/repositories/task_repository.dart';
import 'logic/theme_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());

  // Initialize services
  await PreferencesService.instance.initialize();
  await NotificationService.instance.initialize();

  final taskRepository = TaskRepository();
  await taskRepository.initialize();
  runApp(MyApp(taskRepository: taskRepository));
}

class MyApp extends StatelessWidget {
  final TaskRepository taskRepository;

  const MyApp({super.key, required this.taskRepository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'DeadlineFlow',
            theme: themeProvider.getLightTheme(),
            darkTheme: themeProvider.getDarkTheme(),
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: SplashScreen(taskRepository: taskRepository),
          );
        },
      ),
    );
  }
}
