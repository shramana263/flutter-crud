import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'data/api/task_api_service.dart';
import 'data/datasources/local/database_helper.dart';
import 'data/repositories/task_repository.dart';
import 'presentation/bloc/task/task_bloc.dart';
import 'presentation/screens/task_list_screen.dart';
import 'models/task.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());

  // Removed clearTasks() to persist user-created tasks
  // final databaseHelper = DatabaseHelper();
  // await databaseHelper.clearTasks();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => DatabaseHelper(),
        ),
        RepositoryProvider(
          create: (context) => TaskApiService(
            client: http.Client(),
            dbHelper: RepositoryProvider.of<DatabaseHelper>(context),
          ),
        ),
        RepositoryProvider(
          create: (context) => TaskRepository(
            apiService: RepositoryProvider.of<TaskApiService>(context),
            localDataSource: RepositoryProvider.of<DatabaseHelper>(context),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => TaskBloc(
              repository: RepositoryProvider.of<TaskRepository>(context),
            ),
          ),
        ],
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, themeMode, child) {
            return MaterialApp(
              title: 'Task Manager',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                brightness: Brightness.light,
                cardColor: Colors.white,
                scaffoldBackgroundColor: Colors.grey[100],
                textTheme: const TextTheme(
                  bodyLarge: TextStyle(color: Colors.black87),
                  bodyMedium: TextStyle(color: Colors.black54),
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.grey,
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(),
                ),
              ),
              darkTheme: ThemeData(
                primarySwatch: Colors.blue,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: Colors.grey[900],
                cardColor: Colors.grey[850],
                textTheme: const TextTheme(
                  bodyLarge: TextStyle(color: Colors.white),
                  bodyMedium: TextStyle(color: Colors.white70),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.grey[800],
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
              themeMode: themeMode,
              home: const TaskListScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}