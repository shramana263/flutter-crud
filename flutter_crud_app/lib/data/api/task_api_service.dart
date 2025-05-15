import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/task.dart';
import '../datasources/local/database_helper.dart';

class TaskApiService {
  final http.Client client;
  final DatabaseHelper dbHelper;
  static const String baseUrl = 'https://jsonplaceholder.typicode.com/todos';

  TaskApiService({
    required this.client,
    required this.dbHelper,
  });

  Future<List<Task>> getTasks() async {
    try {
      final response = await client.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final apiTasks = data.map((json) => Task.fromJson(json)).toList();

        // Get local tasks
        final localTasks = await dbHelper.getTasks();

        // Merge API tasks with local tasks
        final Map<int, Task> mergedTasks = {};

        // First, add all local tasks to preserve them
        for (var localTask in localTasks) {
          mergedTasks[localTask.id!] = localTask;
        }

        // Then, update with API tasks
        for (var apiTask in apiTasks) {
          if (apiTask.serverId != null) {
            // Find if this API task already exists locally
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
              // This is a new task from the API, add it
              final newId = DateTime.now().millisecondsSinceEpoch % 0xFFFFFFFF;
              mergedTasks[newId] = apiTask.copyWith(id: newId, lastSynced: DateTime.now());
            } else {
              // Update the existing local task if the API version is newer
              if (localTask.lastSynced == null ||
                  (apiTask.lastSynced != null && apiTask.lastSynced!.isAfter(localTask.lastSynced!))) {
                mergedTasks[localTask.id!] = apiTask.copyWith(id: localTask.id, lastSynced: DateTime.now());
              }
            }
          }
        }

        // Update Hive with merged tasks using batch operation
        final tasksToInsert = mergedTasks.values.toList();
        await dbHelper.clearTasks();
        await dbHelper.batchInsertTasks(tasksToInsert);

        return tasksToInsert;
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      // If API fails, return tasks from Hive
      return await dbHelper.getTasks();
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final response = await client.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(task.toJson()..remove('id')),
      );
      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        final newTask = Task.fromJson(json);
        // Store the new task in Hive with the local ID
        final localId = task.id ?? DateTime.now().millisecondsSinceEpoch % 0xFFFFFFFF;
        final taskToStore = newTask.copyWith(id: localId, serverId: newTask.serverId, lastSynced: DateTime.now());
        await dbHelper.insertTask(taskToStore);
        return taskToStore;
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      // If API fails, store locally
      final localId = task.id ?? DateTime.now().millisecondsSinceEpoch % 0xFFFFFFFF;
      final taskToStore = task.copyWith(id: localId, lastSynced: null);
      await dbHelper.insertTask(taskToStore);
      return taskToStore;
    }
  }

  Future<Task> updateTask(Task task) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/${task.serverId ?? task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(task.toJson()),
      );
      if (response.statusCode == 200) {
        final updatedTask = task.copyWith(lastSynced: DateTime.now());
        await dbHelper.updateTask(updatedTask);
        return updatedTask;
      } else {
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e) {
      // If API fails, update locally
      final updatedTask = task.copyWith(lastSynced: null);
      await dbHelper.updateTask(updatedTask);
      return updatedTask;
    }
  }

  Future<void> deleteTask(int id, int? serverId) async {
    try {
      if (serverId != null) {
        final response = await client.delete(Uri.parse('$baseUrl/$serverId'));
        if (response.statusCode == 200) {
          await dbHelper.deleteTask(id);
        } else {
          throw Exception('Failed to delete task: ${response.statusCode}');
        }
      } else {
        // No serverId, delete locally only
        await dbHelper.deleteTask(id);
      }
    } catch (e) {
      // If API fails, delete locally
      await dbHelper.deleteTask(id);
    }
  }
}