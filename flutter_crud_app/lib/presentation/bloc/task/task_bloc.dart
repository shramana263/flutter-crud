import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../core/errors/exceptions.dart';
import '../../../models/task.dart'; // Added import for Task model
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repository;
  List<Task> _currentTasks = [];

  TaskBloc({required this.repository}) : super(TaskInitial()) {
    on<GetTasks>(_onGetTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
  }

  Future<void> _onGetTasks(GetTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final tasks = await repository.getTasks();
      // Sort tasks by createdDate in descending order
      tasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      _currentTasks = tasks;
      emit(TasksLoaded(tasks));
    } on ServerException {
      emit(const TaskError('Failed to fetch tasks from the server.'));
    } on CacheException {
      emit(const TaskError('Failed to fetch tasks from the cache.'));
    } catch (e) {
      emit(TaskError('An error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    // Optimistic update
    final updatedTasks = List<Task>.from(_currentTasks)..add(event.task);
    // Sort to ensure the new task appears at the top
    updatedTasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    _currentTasks = updatedTasks;
    emit(TasksLoaded(updatedTasks));

    try {
      final createdTask = await repository.createTask(event.task);
      _currentTasks = _currentTasks.map((task) {
        return task == event.task ? createdTask : task;
      }).toList();
      // Sort again after adding
      _currentTasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      emit(const TaskOperationSuccess('Task added successfully!'));
      emit(TasksLoaded(_currentTasks));
    } catch (e) {
      // Revert optimistic update on failure
      _currentTasks = _currentTasks.where((task) => task != event.task).toList();
      _currentTasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      emit(TasksLoaded(_currentTasks));
      if (e is ServerException) {
        emit(const TaskError('Failed to add task to the server.'));
      } else if (e is CacheException) {
        emit(const TaskError('Failed to cache the task.'));
      } else {
        emit(TaskError('An error occurred: ${e.toString()}'));
      }
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    // Optimistic update
    final updatedTasks = _currentTasks.map((task) {
      return task.id == event.task.id ? event.task : task;
    }).toList();
    updatedTasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    _currentTasks = updatedTasks;
    emit(TasksLoaded(updatedTasks));

    try {
      final updatedTask = await repository.updateTask(event.task);
      _currentTasks = _currentTasks.map((task) {
        return task.id == updatedTask.id ? updatedTask : task;
      }).toList();
      _currentTasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      emit(const TaskOperationSuccess('Task updated successfully!'));
      emit(TasksLoaded(_currentTasks));
    } catch (e) {
      // Revert optimistic update on failure
      final originalTask = _currentTasks.firstWhere((task) => task.id == event.task.id);
      _currentTasks = _currentTasks.map((task) {
        return task.id == event.task.id ? originalTask : task;
      }).toList();
      _currentTasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      emit(TasksLoaded(_currentTasks));
      if (e is ServerException) {
        emit(const TaskError('Failed to update task on the server.'));
      } else if (e is CacheException) {
        emit(const TaskError('Failed to update cached task.'));
      } else {
        emit(TaskError('An error occurred: ${e.toString()}'));
      }
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    // Optimistic update
    final deletedTask = _currentTasks.firstWhere((task) => task.id == event.id);
    final updatedTasks = _currentTasks.where((task) => task.id != event.id).toList();
    updatedTasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    _currentTasks = updatedTasks;
    emit(TasksLoaded(updatedTasks));

    try {
      await repository.deleteTask(event.id);
      emit(const TaskOperationSuccess('Task deleted successfully!'));
      emit(TasksLoaded(_currentTasks));
    } catch (e) {
      // Revert optimistic update on failure
      _currentTasks = List<Task>.from(_currentTasks)..add(deletedTask);
      _currentTasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      emit(TasksLoaded(_currentTasks));
      if (e is ServerException) {
        emit(const TaskError('Failed to delete task from the server.'));
      } else if (e is CacheException) {
        emit(const TaskError('Failed to delete cached task.'));
      } else {
        emit(TaskError('An error occurred: ${e.toString()}'));
      }
    }
  }
}