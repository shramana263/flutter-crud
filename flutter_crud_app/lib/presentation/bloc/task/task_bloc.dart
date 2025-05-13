// lib/presentation/bloc/task/task_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../core/errors/exceptions.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repository;

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
    emit(TaskLoading());
    try {
      await repository.createTask(event.task);
      emit(const TaskOperationSuccess('Task added successfully!'));
      
      // Reload the tasks list
      final tasks = await repository.getTasks();
      emit(TasksLoaded(tasks));
    } on ServerException {
      emit(const TaskError('Failed to add task to the server.'));
    } on CacheException {
      emit(const TaskError('Failed to cache the task.'));
    } catch (e) {
      emit(TaskError('An error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      await repository.updateTask(event.task);
      emit(const TaskOperationSuccess('Task updated successfully!'));
      
      // Reload the tasks list
      final tasks = await repository.getTasks();
      emit(TasksLoaded(tasks));
    } on ServerException {
      emit(const TaskError('Failed to update task on the server.'));
    } on CacheException {
      emit(const TaskError('Failed to update cached task.'));
    } catch (e) {
      emit(TaskError('An error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      await repository.deleteTask(event.id);
      emit(const TaskOperationSuccess('Task deleted successfully!'));
      
      // Reload the tasks list
      final tasks = await repository.getTasks();
      emit(TasksLoaded(tasks));
    } on ServerException {
      emit(const TaskError('Failed to delete task from the server.'));
    } on CacheException {
      emit(const TaskError('Failed to delete cached task.'));
    } catch (e) {
      emit(TaskError('An error occurred: ${e.toString()}'));
    }
  }
}