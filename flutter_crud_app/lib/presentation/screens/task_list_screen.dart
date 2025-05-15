import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' as material;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/task/task_bloc.dart';
import '../bloc/task/task_event.dart';
import '../bloc/task/task_state.dart';
import '../widgets/task_card.dart';
import '../widgets/search_bar.dart';
import '../screens/task_form_screen.dart';
import '../../models/task.dart';
import '../../main.dart';

class TaskListScreen extends material.StatefulWidget {
  const TaskListScreen({super.key});

  @override
  material.State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends material.State<TaskListScreen> {
  final material.ScrollController _scrollController = material.ScrollController();
  List<Task> _filteredTasks = [];
  String _searchQuery = '';
  String? _sortBy = 'createdDate';
  bool _sortAscending = false;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _isLoadingMore = false;
  List<Task> _allTasks = [];

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
      _applyFiltersAndSort();
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
    _filteredTasks = _allTasks.where((task) {
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

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _toggleTheme() {
    themeModeNotifier.value = themeModeNotifier.value == material.ThemeMode.light
        ? material.ThemeMode.dark
        : material.ThemeMode.light;
    material.ScaffoldMessenger.of(context).showSnackBar(
      material.SnackBar(
        content: material.Text(
            'Theme switched to ${themeModeNotifier.value == material.ThemeMode.dark ? "Dark" : "Light"} mode'),
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
  material.Widget build(material.BuildContext context) {
    final double screenWidth = material.MediaQuery.of(context).size.width;
    final double screenHeight = material.MediaQuery.of(context).size.height;
    final bool isLandscape = material.MediaQuery.of(context).orientation == material.Orientation.landscape;
    final bool isDesktop = kIsWeb && screenWidth > 600;
    final double scaleFactor = isDesktop ? 0.4 : 1.0; // Reduce sizes by 60% on desktop
    const double maxFontSize = 16.0; // Cap font size for desktop
    final double maxContentWidth = isDesktop ? 800 : screenWidth;

    return material.Scaffold(
      appBar: material.AppBar(
        title: const material.Text('Task Manager'),
        elevation: 0,
        backgroundColor: material.Theme.of(context).primaryColor,
        actions: [
          material.IconButton(
            icon: material.Icon(
              material.Theme.of(context).brightness == material.Brightness.light
                  ? material.Icons.dark_mode
                  : material.Icons.light_mode,
            ),
            onPressed: _toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          material.PopupMenuButton<String>(
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
              const material.PopupMenuItem(
                value: 'createdDateAsc',
                child: material.Text('Sort by Date (Oldest to Latest)'),
              ),
              const material.PopupMenuItem(
                value: 'createdDateDesc',
                child: material.Text('Sort by Date (Latest to Oldest)'),
              ),
              const material.PopupMenuItem(
                value: 'priorityAsc',
                child: material.Text('Sort by Priority (Low to High)'),
              ),
              const material.PopupMenuItem(
                value: 'priorityDesc',
                child: material.Text('Sort by Priority (High to Low)'),
              ),
              const material.PopupMenuItem(
                value: 'titleAsc',
                child: material.Text('Sort by Title (A to Z)'),
              ),
              const material.PopupMenuItem(
                value: 'titleDesc',
                child: material.Text('Sort by Title (Z to A)'),
              ),
            ],
            icon: const material.Icon(material.Icons.sort),
          ),
        ],
      ),
      body: material.Center(
        child: material.ConstrainedBox(
          constraints: material.BoxConstraints(maxWidth: maxContentWidth),
          child: BlocConsumer<TaskBloc, TaskState>(
            listener: (context, state) {
              if (state is TaskOperationSuccess) {
                material.ScaffoldMessenger.of(context).showSnackBar(
                  material.SnackBar(
                    content: material.Text(state.message),
                    backgroundColor: material.Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else if (state is TaskError) {
                material.ScaffoldMessenger.of(context).showSnackBar(
                  material.SnackBar(
                    content: material.Text(state.message),
                    backgroundColor: material.Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              if (state is TasksLoaded) {
                setState(() {
                  _allTasks = state.tasks;
                  _applyFiltersAndSort();
                });
              }
            },
            builder: (context, state) {
              return material.LayoutBuilder(
                builder: (context, constraints) {
                  return material.Column(
                    children: [
                      SearchBar(onSearch: _onSearch),
                      material.Expanded(
                        child: material.RefreshIndicator(
                          onRefresh: () async {
                            setState(() {
                              _currentPage = 1;
                              _allTasks.clear();
                            });
                            context.read<TaskBloc>().add(GetTasks());
                          },
                          child: _buildTaskList(
                              state, constraints, screenWidth, screenHeight, isLandscape, scaleFactor, maxFontSize),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: material.FloatingActionButton(
        onPressed: () {
          material.Navigator.push(
            context,
            material.MaterialPageRoute(builder: (context) => const TaskFormScreen()),
          );
        },
        backgroundColor: material.Theme.of(context).primaryColor,
        child: const material.Icon(material.Icons.add),
      ),
    );
  }

  material.Widget _buildTaskList(TaskState state, material.BoxConstraints constraints, double screenWidth,
      double screenHeight, bool isLandscape, double scaleFactor, double maxFontSize) {
    if (state is TaskLoading && _currentPage == 1 && _allTasks.isEmpty) {
      return const material.Center(child: material.CircularProgressIndicator());
    } else if (state is TasksLoaded || _allTasks.isNotEmpty) {
      if (_filteredTasks.isEmpty) {
        return material.Center(
          child: material.Column(
            mainAxisAlignment: material.MainAxisAlignment.center,
            children: [
              material.Icon(
                material.Icons.task_alt,
                size: (screenWidth * 0.15 * scaleFactor).clamp(0, 40), // Cap icon size for desktop
                color: material.Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.5),
              ),
              material.SizedBox(height: screenHeight * 0.02 * scaleFactor),
              material.Text(
                'No tasks yet. Add a new task by tapping the + button.',
                textAlign: material.TextAlign.center,
                style: material.TextStyle(
                  fontSize: (screenWidth * 0.04 * scaleFactor).clamp(0, maxFontSize),
                  color: material.Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      }

      final paginatedTasks = _filteredTasks.skip(0).take(_currentPage * _pageSize).toList();

      return material.ListView.separated(
        controller: _scrollController,
        padding: material.EdgeInsets.all((screenWidth * 0.04 * scaleFactor).clamp(0, 16)), // Cap padding
        itemCount: paginatedTasks.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => material.SizedBox(height: (screenHeight * 0.01 * scaleFactor).clamp(0, 8)),
        itemBuilder: (context, index) {
          if (index == paginatedTasks.length && _isLoadingMore) {
            return const material.Center(child: material.CircularProgressIndicator());
          }

          final task = paginatedTasks[index];
          return material.Dismissible(
            key: material.Key(task.id.toString()),
            background: material.Container(
              color: material.Colors.red,
              alignment: material.Alignment.centerRight,
              padding: material.EdgeInsets.only(right: (screenWidth * 0.05 * scaleFactor).clamp(0, 20)),
              child: const material.Icon(
                material.Icons.delete,
                color: material.Colors.white,
              ),
            ),
            direction: material.DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await material.showDialog(
                context: context,
                builder: (ctx) => material.AlertDialog(
                  title: const material.Text('Confirm Delete'),
                  content: const material.Text('Are you sure you want to delete this task?'),
                  actions: [
                    material.TextButton(
                      onPressed: () => material.Navigator.of(ctx).pop(false),
                      child: const material.Text('Cancel'),
                    ),
                    material.TextButton(
                      onPressed: () => material.Navigator.of(ctx).pop(true),
                      style: material.TextButton.styleFrom(foregroundColor: material.Colors.red),
                      child: const material.Text('Delete'),
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
                material.Navigator.push(
                  context,
                  material.MaterialPageRoute(builder: (context) => TaskFormScreen(task: task)),
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
    return material.Center(
      child: material.Column(
        mainAxisAlignment: material.MainAxisAlignment.center,
        children: [
          material.Icon(
            material.Icons.error_outline,
            size: (screenWidth * 0.15 * scaleFactor).clamp(0, 40),
            color: material.Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.5),
          ),
          material.SizedBox(height: screenHeight * 0.02 * scaleFactor),
          material.Text(
            'Failed to load tasks. Pull down to refresh.',
            style: material.TextStyle(
              fontSize: (screenWidth * 0.04 * scaleFactor).clamp(0, maxFontSize),
              color: material.Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}