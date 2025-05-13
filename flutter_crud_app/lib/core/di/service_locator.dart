// lib/core/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/api/task_api_service.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/repositories/task_repository.dart';
import '../../presentation/bloc/task/task_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoC
  sl.registerFactory(() => TaskBloc(repository: sl()));

  // Repositories
  sl.registerLazySingleton(() => TaskRepository(
        apiService: sl(),
        localDataSource: sl(),
        connectivity: sl(),
      ));

  // Data sources
  sl.registerLazySingleton(() => TaskApiService(client: sl(), dbHelper: sl()));
  sl.registerLazySingleton(() => DatabaseHelper());

  // External
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => Connectivity());
}