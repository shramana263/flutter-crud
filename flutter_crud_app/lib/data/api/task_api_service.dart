// lib/data/api/task_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/task.dart';
import '../../core/errors/exceptions.dart';
// TODO: Update the import path below if your database_helper.dart is in a different folder.
import '../datasources/local/database_helper.dart';

class TaskApiService {
  final String baseUrl = 'https://jsonplaceholder.typicode.com'; // Example API
  final http.Client client;
  final DatabaseHelper dbHelper;

  TaskApiService({
    required this.client,
    required this.dbHelper,
  });

  /// Fetch tasks from API, store in Hive, and return the list.
  Future<List<Task>> getTasks() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/todos'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> tasksJson = json.decode(response.body);
        final List<Task> tasks = tasksJson
            .map((json) => Task(
                  id: json['id'],
                  title: json['title'],
                  description: json['title'], // API doesn't have description
                  isCompleted: json['completed'],
                  createdDate: DateTime.now(),
                  priority: 1,
                ))
            .toList();

        // Store fetched tasks in Hive
        for (final task in tasks) {
          await dbHelper.insertTask(task);
        }

        return await dbHelper.getTasks(); // Return tasks from Hive
      } else {
        throw ServerException();
      }
    } catch (e) {
      // On error, try to return tasks from Hive (offline support)
      return await dbHelper.getTasks();
    }
  }

  /// Create task in API, then store in Hive
  Future<Task> createTask(Task task) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/todos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': task.title,
          'completed': task.isCompleted,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Task createdTask = Task(
          id: responseData['id'],
          title: responseData['title'],
          description: task.description,
          isCompleted: responseData['completed'],
          createdDate: task.createdDate,
          priority: task.priority,
        );
        await dbHelper.insertTask(createdTask);
        return createdTask;
      } else {
        throw ServerException();
      }
    } catch (e) {
      // On error, store locally (offline-first)
      final int localId = await dbHelper.insertTask(task);
      return task.copyWith(id: localId);
    }
  }

  /// Update task in API, then update in Hive
  Future<Task> updateTask(Task task) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/todos/${task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': task.title,
          'completed': task.isCompleted,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Task updatedTask = Task(
          id: task.id,
          title: responseData['title'],
          description: task.description,
          isCompleted: responseData['completed'],
          createdDate: task.createdDate,
          priority: task.priority,
        );
        await dbHelper.updateTask(updatedTask);
        return updatedTask;
      } else {
        throw ServerException();
      }
    } catch (e) {
      // On error, update locally
      await dbHelper.updateTask(task);
      return task;
    }
  }

  /// Delete task from API, then from Hive
  Future<void> deleteTask(int id) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/todos/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await dbHelper.deleteTask(id);
      } else {
        throw ServerException();
      }
    } catch (e) {
      // On error, delete locally
      await dbHelper.deleteTask(id);
    }
  }
}
