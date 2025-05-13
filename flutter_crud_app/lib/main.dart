import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/task.dart';
import 'data/datasources/local/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasks');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive Task CRUD',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Box<Task> taskBox;
  late DatabaseHelper dbHelper;
  bool isLoading = true;
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');
    dbHelper = DatabaseHelper();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      tasks = await dbHelper.getTasks();
    } catch (e) {
      print('Error loading tasks: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addOrUpdateTask({Task? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task == null ? 'Add Task' : 'Edit Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title cannot be empty')),
                );
                return;
              }

              // Create the task object
              final newTask = Task(
                id: task?.id, // Will be null for new tasks
                title: titleController.text,
                description: descController.text,
                isCompleted: task?.isCompleted ?? false,
                createdDate: task?.createdDate ?? DateTime.now(),
                priority: task?.priority ?? 1,
              );

              try {
                if (task == null) {
                  // Add new task
                  await dbHelper.insertTask(newTask);
                  print('New task added');
                } else {
                  // Update existing task
                  await dbHelper.updateTask(newTask);
                  print('Task updated');
                }
                // Refresh the task list
                await _loadTasks();
                Navigator.pop(context);
              } catch (e) {
                print('Error saving task: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error saving task: $e')),
                );
              }
            },
            child: Text(task == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(int id) async {
    try {
      await dbHelper.deleteTask(id);
      await _loadTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted')),
      );
    } catch (e) {
      print('Error deleting task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hive Task CRUD')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(child: Text('No tasks found.'))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      title: Text(task.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.description),
                          Text(
                            'Created: ${task.createdDate.toString().substring(0, 16)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (bool? value) async {
                          final updatedTask = Task(
                            id: task.id,
                            title: task.title,
                            description: task.description,
                            isCompleted: value ?? false,
                            createdDate: task.createdDate,
                            priority: task.priority,
                          );
                          await dbHelper.updateTask(updatedTask);
                          await _loadTasks();
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _addOrUpdateTask(task: task),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              if (task.id != null) {
                                _deleteTask(task.id!);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateTask(),
        child: const Icon(Icons.add),
      ),
    );
  }
}