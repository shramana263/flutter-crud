import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/task/task_bloc.dart';
import '../bloc/task/task_event.dart';
import '../bloc/task/task_state.dart';
import '../widgets/task_card.dart';
import '../widgets/search_bar.dart' as custom_widgets;
import 'task_form_modal.dart';
import '../../models/task.dart';
import '../../main.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Task> _filteredTasks = [];
  String _searchQuery = '';
  String _sortBy = 'createdDate';
  bool _sortAscending = false;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(GetTasks());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
      context.read<TaskBloc>().add(GetTasks());
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _applyFiltersAndSort();
    });
  }

  void _onSort(String sortBy, bool ascending) {
    setState(() {
      _sortBy = sortBy;
      _sortAscending = ascending;
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    final state = context.read<TaskBloc>().state;
    if (state is TasksLoaded) {
      _filteredTasks = state.tasks.where((task) {
        return task.title.toLowerCase().contains(_searchQuery) ||
            task.description.toLowerCase().contains(_searchQuery);
      }).toList();

      _filteredTasks.sort((a, b) {
        int compare;
        if (_sortBy == 'createdDate') {
          compare = a.createdDate.compareTo(b.createdDate);
        } else if (_sortBy == 'priority') {
          compare = a.priority.compareTo(b.priority);
        } else {
          compare = a.title.compareTo(b.title);
        }
        return _sortAscending ? compare : -compare;
      });
    }
  }

  void _toggleTheme() {
    themeModeNotifier.value = themeModeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme switched to ${themeModeNotifier.value == ThemeMode.dark ? "Dark" : "Light"} mode'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: _toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'createdDateAsc') {
                _onSort('createdDate', true);
              } else if (value == 'createdDateDesc') {
                _onSort('createdDate', false);
              } else if (value == 'priorityAsc') {
                _onSort('priority', true);
              } else if (value == 'priorityDesc') {
                _onSort('priority', false);
              } else if (value == 'titleAsc') {
                _onSort('title', true);
              } else if (value == 'titleDesc') {
                _onSort('title', false);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'createdDateAsc',
                child: Text('Sort by Date (Asc)'),
              ),
              const PopupMenuItem(
                value: 'createdDateDesc',
                child: Text('Sort by Date (Desc)'),
              ),
              const PopupMenuItem(
                value: 'priorityAsc',
                child: Text('Sort by Priority (Asc)'),
              ),
              const PopupMenuItem(
                value: 'priorityDesc',
                child: Text('Sort by Priority (Desc)'),
              ),
              const PopupMenuItem(
                value: 'titleAsc',
                child: Text('Sort by Title (Asc)'),
              ),
              const PopupMenuItem(
                value: 'titleDesc',
                child: Text('Sort by Title (Desc)'),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          if (state is TasksLoaded) {
            setState(() {
              _isLoadingMore = false;
            });
            _applyFiltersAndSort();
          }
        },
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  custom_widgets.SearchBar(onSearch: _onSearch),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _currentPage = 1;
                        });
                        context.read<TaskBloc>().add(GetTasks());
                      },
                      child: _buildTaskList(state, constraints),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const TaskFormModal(),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskList(TaskState state, BoxConstraints constraints) {
    if (state is TaskLoading && _currentPage == 1) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is TasksLoaded) {
      if (_filteredTasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt,
                size: 60,
                color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No tasks yet. Add a new task by tapping the + button.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      }

      final paginatedTasks = _filteredTasks
          .skip(0)
          .take(_currentPage * _pageSize)
          .toList();

      return ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: paginatedTasks.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == paginatedTasks.length && _isLoadingMore) {
            return const Center(child: CircularProgressIndicator());
          }

          final task = paginatedTasks[index];
          return Dismissible(
            key: Key(task.id.toString()),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: const Text('Are you sure you want to delete this task?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              context.read<TaskBloc>().add(DeleteTask(task.id!));
            },
            child: TaskCard(
              task: task,
              onEdit: () {
                showDialog(
                  context: context,
                  builder: (context) => TaskFormModal(task: task),
                );
              },
              onDelete: () {
                context.read<TaskBloc>().add(DeleteTask(task.id!));
              },
              onStatusChanged: (value) {
                final updatedTask = task.copyWith(isCompleted: value);
                context.read<TaskBloc>().add(UpdateTask(updatedTask));
              },
            ),
          );
        },
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load tasks. Pull down to refresh.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}