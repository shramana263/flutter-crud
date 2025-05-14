import 'package:flutter/material.dart' as material;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/task/task_bloc.dart';
import '../bloc/task/task_event.dart';
import '../../models/task.dart';

class TaskFormModal extends material.StatefulWidget {
  final Task? task;

  const TaskFormModal({super.key, this.task});

  @override
  material.State<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends material.State<TaskFormModal> {
  final _formKey = material.GlobalKey<material.FormState>();
  late material.TextEditingController _titleController;
  late material.TextEditingController _descriptionController;
  late bool _isCompleted;
  late int _priority;

  @override
  void initState() {
    super.initState();
    _titleController = material.TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = material.TextEditingController(text: widget.task?.description ?? '');
    _isCompleted = widget.task?.isCompleted ?? false;
    _priority = widget.task?.priority ?? 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        isCompleted: _isCompleted,
        createdDate: widget.task?.createdDate ?? DateTime.now(),
        priority: _priority,
      );

      if (widget.task == null) {
        context.read<TaskBloc>().add(AddTask(task));
      } else {
        context.read<TaskBloc>().add(UpdateTask(task));
      }

      material.Navigator.of(context).pop();
    }
  }

  @override
  material.Widget build(material.BuildContext context) {
    return material.Dialog(
      shape: material.RoundedRectangleBorder(
        borderRadius: material.BorderRadius.circular(12),
      ),
      backgroundColor: material.Theme.of(context).cardColor, // Use cardColor for modal background
      child: material.Padding(
        padding: const material.EdgeInsets.all(20),
        child: material.Form(
          key: _formKey,
          child: material.Column(
            mainAxisSize: material.MainAxisSize.min,
            crossAxisAlignment: material.CrossAxisAlignment.start,
            children: [
              material.Text(
                widget.task == null ? 'Add Task' : 'Edit Task',
                style: material.TextStyle(
                  fontSize: 20,
                  fontWeight: material.FontWeight.bold,
                  color: material.Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
              const material.SizedBox(height: 20),
              material.TextFormField(
                controller: _titleController,
                decoration: const material.InputDecoration(
                  labelText: 'Title',
                  border: material.OutlineInputBorder(),
                ),
                style: material.TextStyle(
                  color: material.Theme.of(context).textTheme.bodyLarge!.color,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const material.SizedBox(height: 16),
              material.TextFormField(
                controller: _descriptionController,
                decoration: const material.InputDecoration(
                  labelText: 'Description',
                  border: material.OutlineInputBorder(),
                ),
                style: material.TextStyle(
                  color: material.Theme.of(context).textTheme.bodyLarge!.color,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const material.SizedBox(height: 16),
              material.Row(
                children: [
                  material.Text(
                    'Completed:',
                    style: material.TextStyle(
                      color: material.Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                  ),
                  const material.SizedBox(width: 10),
                  material.Checkbox(
                    value: _isCompleted,
                    onChanged: (value) {
                      setState(() {
                        _isCompleted = value ?? false;
                      });
                    },
                    activeColor: material.Theme.of(context).primaryColor,
                  ),
                ],
              ),
              const material.SizedBox(height: 16),
              material.Row(
                children: [
                  material.Text(
                    'Priority:',
                    style: material.TextStyle(
                      color: material.Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                  ),
                  const material.SizedBox(width: 10),
                  material.DropdownButton<int>(
                    value: _priority,
                    items: const [
                      material.DropdownMenuItem(
                        value: 1,
                        child: material.Text('Low'),
                      ),
                      material.DropdownMenuItem(
                        value: 2,
                        child: material.Text('Medium'),
                      ),
                      material.DropdownMenuItem(
                        value: 3,
                        child: material.Text('High'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _priority = value ?? 1;
                      });
                    },
                    dropdownColor: material.Theme.of(context).cardColor,
                    style: material.TextStyle(
                      color: material.Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                ],
              ),
              const material.SizedBox(height: 20),
              material.Row(
                mainAxisAlignment: material.MainAxisAlignment.end,
                children: [
                  material.TextButton(
                    onPressed: () {
                      material.Navigator.of(context).pop();
                    },
                    child: material.Text(
                      'Cancel',
                      style: material.TextStyle(
                        color: material.Colors.grey[400], // Lighter grey for visibility
                      ),
                    ),
                  ),
                  const material.SizedBox(width: 10),
                  material.ElevatedButton(
                    onPressed: _submitForm,
                    child: material.Text(
                      widget.task == null ? 'Add' : 'Update',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}