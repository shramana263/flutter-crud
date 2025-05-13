import '../../models/task.dart';
import '../datasources/local/database_helper.dart';
import '../api/task_api_service.dart';
import '../../core/errors/exceptions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class TaskRepository {
  final TaskApiService apiService;
  final DatabaseHelper localDataSource;
  final Connectivity connectivity;

  TaskRepository({
    required this.apiService,
    required this.localDataSource,
    required this.connectivity,
  });

  Future<List<Task>> getTasks() async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      try {
        final remoteTasks = await apiService.getTasks();
        for (var task in remoteTasks) {
          await localDataSource.insertTask(task);
        }
        return remoteTasks;
      } on ServerException {
        return await localDataSource.getTasks();
      }
    } else {
      return await localDataSource.getTasks();
    }
  }

  Future<Task> createTask(Task task) async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      try {
        final remoteTask = await apiService.createTask(task);
        await localDataSource.insertTask(remoteTask);
        return remoteTask;
      } on ServerException {
        final id = await localDataSource.insertTask(task);
        return task.copyWith(id: id);
      }
    } else {
      final id = await localDataSource.insertTask(task);
      return task.copyWith(id: id);
    }
  }

  Future<Task> updateTask(Task task) async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      try {
        final remoteTask = await apiService.updateTask(task);
        await localDataSource.updateTask(remoteTask);
        return remoteTask;
      } on ServerException {
        await localDataSource.updateTask(task);
        return task;
      }
    } else {
      await localDataSource.updateTask(task);
      return task;
    }
  }

  Future<void> deleteTask(int id) async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      try {
        await apiService.deleteTask(id);
      } catch (_) {
        // ignore API failure, proceed to local delete
      }
    }
    await localDataSource.deleteTask(id);
  }
}
