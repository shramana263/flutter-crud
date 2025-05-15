import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/task.dart';
import '../bloc/task/task_bloc.dart';
import '../bloc/task/task_event.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({Key? key, this.task}) : super(key: key);

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late int _priority;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _priority = widget.task?.priority ?? 1;
    _isCompleted = widget.task?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isDesktop = kIsWeb && screenWidth > 600;
    final double scaleFactor = isDesktop ? 0.4 : 1.0; // Reduce sizes by 60% on desktop
    const double maxFontSize = 16.0; // Cap font size for desktop
    final double maxContentWidth = isDesktop ? 600 : screenWidth;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: (screenWidth * 0.05 * scaleFactor).clamp(0, 16),
              vertical: (screenHeight * 0.02 * scaleFactor).clamp(0, 12),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(
                      color: isDark ? colorScheme.onSurface : Colors.black87,
                      fontSize: (screenWidth * 0.04 * scaleFactor).clamp(0, maxFontSize),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                        color: isDark ? colorScheme.primary : Colors.black54,
                        fontSize: (screenWidth * 0.035 * scaleFactor).clamp(0, maxFontSize - 2),
                      ),
                      filled: true,
                      fillColor: isDark ? colorScheme.background : Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      if (value.length > 100) {
                        return 'Title cannot exceed 100 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: (screenHeight * 0.02 * scaleFactor).clamp(0, 12)),
                  TextFormField(
                    controller: _descriptionController,
                    style: TextStyle(
                      color: isDark ? colorScheme.onSurface : Colors.black87,
                      fontSize: (screenWidth * 0.04 * scaleFactor).clamp(0, maxFontSize),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                        color: isDark ? colorScheme.primary : Colors.black54,
                        fontSize: (screenWidth * 0.035 * scaleFactor).clamp(0, maxFontSize - 2),
                      ),
                      filled: true,
                      fillColor: isDark ? colorScheme.background : Colors.white,
                    ),
                    maxLines: isLandscape ? 2 : 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: (screenHeight * 0.02 * scaleFactor).clamp(0, 12)),
                  Text(
                    'Priority: $_priority',
                    // style: TextStyle(
                    //   color: Colors.white,
                    // ),
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: (screenWidth * 0.04 * scaleFactor).clamp(0, maxFontSize),
                    ),
                  ),
                  Slider(
                    value: _priority.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _priority.toString(),
                    activeColor: colorScheme.primary,
                    inactiveColor: isDark
                        ? colorScheme.primary.withOpacity(0.3)
                        : colorScheme.primary.withOpacity(0.2),
                    onChanged: (value) {
                      setState(() {
                        _priority = value.toInt();
                      });
                    },
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _isCompleted,
                        activeColor: colorScheme.primary,
                        checkColor: isDark ? colorScheme.surface : Colors.white,
                        onChanged: (value) {
                          setState(() {
                            _isCompleted = value ?? false;
                          });
                        },
                      ),
                      Text(
                        'Mark as completed',
                        style: TextStyle(
                          color: Colors.purple,
                          fontSize: (screenWidth * 0.035 * scaleFactor).clamp(0, maxFontSize - 2),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: (screenHeight * 0.03 * scaleFactor).clamp(0, 16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontSize: (screenWidth * 0.04 * scaleFactor).clamp(0, maxFontSize),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: (screenWidth * 0.02 * scaleFactor).clamp(0, 12)),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(
                              vertical: (screenHeight * 0.02 * scaleFactor).clamp(0, 12),
                              horizontal: (screenWidth * 0.05 * scaleFactor).clamp(0, 16),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final task = Task(
                                id: widget.task?.id,
                                title: _titleController.text.trim(),
                                description: _descriptionController.text.trim(),
                                priority: _priority,
                                isCompleted: _isCompleted,
                                createdDate: widget.task?.createdDate ?? DateTime.now(),
                              );

                              if (widget.task == null) {
                                context.read<TaskBloc>().add(AddTask(task));
                              } else {
                                context.read<TaskBloc>().add(UpdateTask(task));
                              }

                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            widget.task == null ? 'Add Task' : 'Save Changes',
                            style: TextStyle(fontSize: (screenWidth * 0.04 * scaleFactor).clamp(0, maxFontSize)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}