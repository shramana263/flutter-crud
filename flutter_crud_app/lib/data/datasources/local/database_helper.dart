import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../../../models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Box<Task>? _box;
  final Logger _logger = Logger();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Box<Task>> get box async {
    if (_box != null) return _box!;
    _box = await Hive.openBox<Task>('tasks');
    _logger.i('Hive box "tasks" opened');
    return _box!;
  }

  Future<int> insertTask(Task task) async {
    var box = await this.box;
    if (task.id != null) {
      await box.put(task.id!, task);
      _logger.i('Inserted task with ID: ${task.id}, Title: ${task.title}');
      return task.id!;
    } else {
      final newId = DateTime.now().millisecondsSinceEpoch % 0xFFFFFFFF;
      final taskWithId = task.copyWith(id: newId);
      await box.put(newId, taskWithId);
      _logger.i('Inserted new task with ID: $newId, Title: ${task.title}');
      return newId;
    }
  }

  Future<void> batchInsertTasks(List<Task> tasks) async {
    var box = await this.box;
    final tasksWithIds = tasks.map((task) {
      if (task.id != null) {
        return task;
      } else {
        final newId = DateTime.now().millisecondsSinceEpoch % 0xFFFFFFFF;
        return task.copyWith(id: newId);
      }
    }).toList();

    final map = {for (var task in tasksWithIds) task.id!: task};
    await box.putAll(map);
    _logger.i('Batch inserted ${tasks.length} tasks');
  }

  Future<List<Task>> getTasks() async {
    var box = await this.box;
    final tasks = box.values.toList();
    tasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    _logger.i('Retrieved ${tasks.length} tasks from Hive');
    return tasks;
  }

  Future<void> updateTask(Task task) async {
    var box = await this.box;
    if (task.id != null) {
      await box.put(task.id!, task);
      _logger.i('Updated task with ID: ${task.id}, Title: ${task.title}');
    } else {
      _logger.e('Cannot update a task without an ID');
      throw Exception('Cannot update a task without an ID');
    }
  }

  Future<void> deleteTask(int id) async {
    var box = await this.box;
    await box.delete(id);
    _logger.i('Deleted task with ID: $id');
  }

  Future<void> clearTasks() async {
    var box = await this.box;
    await box.clear();
    _logger.i('Cleared all tasks from Hive');
  }

  Future<void> printAllTasks() async {
    var box = await this.box;
    final tasks = box.values.toList();
    final keys = box.keys.toList();

    _logger.i('===== TASKS IN DATABASE =====');
    for (int i = 0; i < box.length; i++) {
      _logger.i('Key: ${keys[i]}, ID: ${tasks[i].id}, ServerID: ${tasks[i].serverId}, Title: ${tasks[i].title}');
    }
    _logger.i('============================');
  }
}