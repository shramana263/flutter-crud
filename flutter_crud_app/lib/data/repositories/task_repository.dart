import 'package:connectivity_plus/connectivity_plus.dart';
import '../api/task_api_service.dart';
import '../datasources/local/database_helper.dart';
import '../../models/task.dart';
import '../../core/errors/exceptions.dart';

class TaskRepository {
  final TaskApiService apiService;
  final DatabaseHelper localDataSource;
  final Connectivity connectivity;

  TaskRepository({
    required this.apiService,
    required this.localDataSource,
    required this.connectivity,
  });

  Future<bool> _isOnline() async {
    var connectivityResult = await connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<List<Task>> getTasks() async {
    try {
      if (await _isOnline()) {
        final tasks = await apiService.getTasks();
        return tasks;
      } else {
        final tasks = await localDataSource.getTasks();
        return tasks;
      }
    } catch (e) {
      if (e is ServerException) {
        throw ServerException();
      } else if (e is CacheException) {
        throw CacheException();
      } else {
        throw Exception('Unexpected error: ${e.toString()}');
      }
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      if (await _isOnline()) {
        final createdTask = await apiService.createTask(task);
        return createdTask;
      } else {
        final localId = await localDataSource.insertTask(task);
        return task.copyWith(id: localId);
      }
    } catch (e) {
      if (e is ServerException) {
        throw ServerException();
      } else if (e is CacheException) {
        throw CacheException();
      } else {
        throw Exception('Unexpected error: ${e.toString()}');
      }
    }
  }

  Future<Task> updateTask(Task task) async {
    try {
      if (await _isOnline()) {
        final updatedTask = await apiService.updateTask(task);
        return updatedTask;
      } else {
        await localDataSource.updateTask(task);
        return task;
      }
    } catch (e) {
      if (e is ServerException) {
        throw ServerException();
      } else if (e is CacheException) {
        throw CacheException();
      } else {
        throw Exception('Unexpected error: ${e.toString()}');
      }
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      if (await _isOnline()) {
        await apiService.deleteTask(id);
      } else {
        await localDataSource.deleteTask(id);
      }
    } catch (e) {
      if (e is ServerException) {
        throw ServerException();
      } else if (e is CacheException) {
        throw CacheException();
      } else {
        throw Exception('Unexpected error: ${e.toString()}');
      }
    }
  }
}