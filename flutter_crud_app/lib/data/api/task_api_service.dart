import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/task.dart';
import '../../core/errors/exceptions.dart';
import '../datasources/local/database_helper.dart';

class TaskApiService {
  final String baseUrl = 'https://jsonplaceholder.typicode.com';
  final http.Client client;
  final DatabaseHelper dbHelper;
  final int maxRetries = 3;

  TaskApiService({
    required this.client,
    required this.dbHelper,
  });

  Future<List<Task>> getTasks() async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
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
                    description: json['title'],
                    isCompleted: json['completed'],
                    createdDate: DateTime.now(),
                    priority: 1,
                  ))
              .toList();

          for (final task in tasks) {
            await dbHelper.insertTask(task);
          }

          return await dbHelper.getTasks();
        } else {
          throw ServerException();
        }
      } catch (e) {
        if (attempt == maxRetries) {
          return await dbHelper.getTasks();
        }
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw ServerException('Failed after $maxRetries attempts');
  }

  Future<Task> createTask(Task task) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
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
        if (attempt == maxRetries) {
          final int localId = await dbHelper.insertTask(task);
          return task.copyWith(id: localId);
        }
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw ServerException('Failed after $maxRetries attempts');
  }

  Future<Task> updateTask(Task task) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
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
        if (attempt == maxRetries) {
          await dbHelper.updateTask(task);
          return task;
        }
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw ServerException('Failed after $maxRetries attempts');
  }

  Future<void> deleteTask(int id) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await client.delete(
          Uri.parse('$baseUrl/todos/$id'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          await dbHelper.deleteTask(id);
          return;
        } else {
          throw ServerException();
        }
      } catch (e) {
        if (attempt == maxRetries) {
          await dbHelper.deleteTask(id);
          return;
        }
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw ServerException('Failed after $maxRetries attempts');
  }
}