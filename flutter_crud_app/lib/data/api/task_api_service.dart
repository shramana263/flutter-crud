import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/task.dart';
import '../datasources/local/database_helper.dart';

class TaskApiService {
  final http.Client client;
  final DatabaseHelper dbHelper;
  static const String baseUrl = 'https://jsonplaceholder.typicode.com/todos';
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  TaskApiService({
    required this.client,
    required this.dbHelper,
  });

  Future<http.Response> _retryRequest(Future<http.Response> Function() request) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        final response = await request();
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        } else {
          throw Exception('Failed request with status: ${response.statusCode}');
        }
      } catch (e) {
        attempt++;
        if (attempt == maxRetries) {
          rethrow; // Throw the last error after all retries fail
        }
        await Future.delayed(retryDelay); // Wait before retrying
      }
    }
    throw Exception('Max retries reached'); // This line should never be reached
  }

  Future<List<Task>> getTasks() async {
    try {
      final response = await _retryRequest(() => client.get(Uri.parse(baseUrl)));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final apiTasks = data.map((json) => Task.fromJson(json)).toList();

        final localTasks = await dbHelper.getTasks();
        final Map<int, Task> mergedTasks = {};

        for (var localTask in localTasks) {
          mergedTasks[localTask.id!] = localTask;
        }

        for (var apiTask in apiTasks) {
          if (apiTask.serverId != null) {
            final localTask = localTasks.firstWhere(
              (task) => task.serverId == apiTask.serverId,
              orElse: () => Task(
                id: null,
                title: '',
                description: '',
                isCompleted: false,
                createdDate: DateTime.now(),
                priority: 1,
              ),
            );

            if (localTask.id == null) {
              final newId = DateTime.now().millisecondsSinceEpoch % 0xFFFFFFFF;
              mergedTasks[newId] = apiTask.copyWith(id: newId, lastSynced: DateTime.now());
            } else {
              if (localTask.lastSynced == null ||
                  (apiTask.lastSynced != null && apiTask.lastSynced!.isAfter(localTask.lastSynced!))) {
                mergedTasks[localTask.id!] = apiTask.copyWith(id: localTask.id, lastSynced: DateTime.now());
              }
            }
          }
        }

        final tasksToInsert = mergedTasks.values.toList();
        await dbHelper.clearTasks();
        await dbHelper.batchInsertTasks(tasksToInsert);

        return tasksToInsert;
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      return await dbHelper.getTasks();
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final response = await _retryRequest(() => client.post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(task.toJson()..remove('id')),
          ));
      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        final newTask = Task.fromJson(json);
        final localId = task.id ?? DateTime.now().millisecondsSinceEpoch % 0xFFFFFFFF;
        final taskToStore = newTask.copyWith(id: localId, serverId: newTask.serverId, lastSynced: DateTime.now());
        await dbHelper.insertTask(taskToStore);
        return taskToStore;
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      final localId = task.id ?? DateTime.now().millisecondsSinceEpoch % 0xFFFFFFFF;
      final taskToStore = task.copyWith(id: localId, lastSynced: null);
      await dbHelper.insertTask(taskToStore);
      return taskToStore;
    }
  }

  Future<Task> updateTask(Task task) async {
    try {
      final response = await _retryRequest(() => client.put(
            Uri.parse('$baseUrl/${task.serverId ?? task.id}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(task.toJson()),
          ));
      if (response.statusCode == 200) {
        final updatedTask = task.copyWith(lastSynced: DateTime.now());
        await dbHelper.updateTask(updatedTask);
        return updatedTask;
      } else {
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e) {
      final updatedTask = task.copyWith(lastSynced: null);
      await dbHelper.updateTask(updatedTask);
      return updatedTask;
    }
  }

  Future<void> deleteTask(int id, int? serverId) async {
    try {
      if (serverId != null) {
        final response = await _retryRequest(() => client.delete(Uri.parse('$baseUrl/$serverId')));
        if (response.statusCode == 200) {
          await dbHelper.deleteTask(id);
        } else {
          throw Exception('Failed to delete task: ${response.statusCode}');
        }
      } else {
        await dbHelper.deleteTask(id);
      }
    } catch (e) {
      await dbHelper.deleteTask(id);
    }
  }
}