import 'package:http/http.dart' as http;
import '../../models/task.dart';
import '../datasources/local/database_helper.dart';

class TaskApiService {
  final http.Client client; // Keep this for potential future API integration
  final DatabaseHelper dbHelper;

  TaskApiService({
    required this.client,
    required this.dbHelper,
  });

  Future<List<Task>> getTasks() async {
    // Directly fetch tasks from Hive, no API calls
    final tasks = await dbHelper.getTasks();
    return tasks;
  }

  Future<Task> createTask(Task task) async {
    // Directly insert the task into Hive
    final newId = await dbHelper.insertTask(task);
    return task.copyWith(id: newId);
  }

  Future<Task> updateTask(Task task) async {
    // Directly update the task in Hive
    await dbHelper.updateTask(task);
    return task;
  }

  Future<void> deleteTask(int id) async {
    // Directly delete the task from Hive
    await dbHelper.deleteTask(id);
  }
}