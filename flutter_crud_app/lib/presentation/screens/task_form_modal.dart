import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/task.dart';
import '../bloc/task/task_bloc.dart';
import '../bloc/task/task_event.dart';

class TaskFormModal extends StatefulWidget {
  final Task? task;

  const TaskFormModal({Key? key, this.task}) : super(key: key);

  @override
  State<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends State<TaskFormModal> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: isDark ? colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        widget.task == null ? 'Add Task' : 'Edit Task',
        style: TextStyle(
          color: isDark ? colorScheme.onSurface : Colors.black87,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: isDark ? colorScheme.onSurface : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? colorScheme.primary : Colors.black54),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: isDark ? colorScheme.onSurface : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isDark ? colorScheme.primary : Colors.black54),
                  filled: true,
                  fillColor: isDark ? colorScheme.background : Colors.white,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Priority',
                style: TextStyle(
                  color: isDark ? colorScheme.onSurface : Colors.black87,
                  fontSize: 16,
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
                    style: TextStyle(color: isDark ? colorScheme.onSurface : Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: colorScheme.secondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
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
          child: Text(widget.task == null ? 'Add Task' : 'Save Changes'),
        ),
      ],
    );
  }
}