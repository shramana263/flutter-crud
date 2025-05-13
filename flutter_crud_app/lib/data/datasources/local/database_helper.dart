import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Box<Task>? _box;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Box<Task>> get box async {
    if (_box != null) return _box!;
    _box = await Hive.openBox<Task>('tasks');
    return _box!;
  }

    Future<int> insertTask(Task task) async {
    var box = await this.box;
    if (task.id != null) {
      // Use task.id as key to avoid duplicates
      await box.put(task.id!, task);
      return task.id!;
    } else {
      // Generate a new ID for the task within Hive's allowed range
      final newId = DateTime.now().millisecondsSinceEpoch % 0xFFFFFFFF;
      
      // Create a new task with the generated ID
      final taskWithId = Task(
        id: newId,
        title: task.title,
        description: task.description,
        isCompleted: task.isCompleted,
        createdDate: task.createdDate,
        priority: task.priority,
      );
      
      // Store the task using the new ID as the key
      await box.put(newId, taskWithId);
      return newId;
    }
  }

  Future<List<Task>> getTasks() async {
    var box = await this.box;
    return box.values.toList();
  }

  Future<void> updateTask(Task task) async {
    var box = await this.box;
    if (task.id != null) {
      // Make sure we're using the ID as the key
      await box.put(task.id!, task);
      print('Updated task with ID: ${task.id}');
    } else {
      throw Exception('Cannot update a task without an ID');
    }
  }

  Future<void> deleteTask(int id) async {
    var box = await this.box;
    await box.delete(id);
    print('Deleted task with ID: $id');
  }
  
  // For debugging purposes
  Future<void> printAllTasks() async {
    var box = await this.box;
    final tasks = box.values.toList();
    final keys = box.keys.toList();
    
    print('===== TASKS IN DATABASE =====');
    for (int i = 0; i < box.length; i++) {
      print('Key: ${keys[i]}, ID: ${tasks[i].id}, Title: ${tasks[i].title}');
    }
    print('============================');
  }
}