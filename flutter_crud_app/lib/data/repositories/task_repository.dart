import '../api/task_api_service.dart';
import '../datasources/local/database_helper.dart';
import '../../models/task.dart';
import '../../core/errors/exceptions.dart';

class TaskRepository {
  final TaskApiService apiService;
  final DatabaseHelper localDataSource;

  TaskRepository({
    required this.apiService,
    required this.localDataSource,
  });

  Future<List<Task>> getTasks() async {
    try {
      final tasks = await apiService.getTasks();
      return tasks;
    } catch (e) {
      if (e is CacheException) {
        throw CacheException();
      } else {
        throw Exception('Unexpected error: ${e.toString()}');
      }
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final createdTask = await apiService.createTask(task);
      return createdTask;
    } catch (e) {
      if (e is CacheException) {
        throw CacheException();
      } else {
        throw Exception('Unexpected error: ${e.toString()}');
      }
    }
  }

  Future<Task> updateTask(Task task) async {
    try {
      final updatedTask = await apiService.updateTask(task);
      return updatedTask;
    } catch (e) {
      if (e is CacheException) {
        throw CacheException();
      } else {
        throw Exception('Unexpected error: ${e.toString()}');
      }
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await apiService.deleteTask(id);
    } catch (e) {
      if (e is CacheException) {
        throw CacheException();
      } else {
        throw Exception('Unexpected error: ${e.toString()}');
      }
    }
  }
}