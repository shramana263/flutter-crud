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
      int key = await box.add(task);
      return key;
    }
  }

  Future<List<Task>> getTasks() async {
    var box = await this.box;
    return box.values.toList();
  }

  Future<void> updateTask(Task task) async {
    var box = await this.box;
    if (task.id != null) {
      await box.put(task.id!, task);
    } else {
      // If no id, fallback to add
      await box.add(task);
    }
  }

  Future<void> deleteTask(int id) async {
    var box = await this.box;
    await box.delete(id);
  }
}
