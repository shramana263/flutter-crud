import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart'; // For formatting DateTime
import '../../models/task.dart';

class TaskCard extends material.StatelessWidget {
  final Task task;
  final material.VoidCallback onEdit;
  final material.VoidCallback onDelete;
  final Function(bool) onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  material.Widget build(material.BuildContext context) {
    return material.Card(
      elevation: 2,
      shape: material.RoundedRectangleBorder(
        borderRadius: material.BorderRadius.circular(12),
      ),
      child: material.Padding(
        padding: const material.EdgeInsets.all(16),
        child: material.Column(
          crossAxisAlignment: material.CrossAxisAlignment.start,
          children: [
            material.Row(
              children: [
                material.Expanded(
                  child: material.Text(
                    task.title,
                    style: material.TextStyle(
                      fontSize: 18,
                      fontWeight: material.FontWeight.bold,
                      color: material.Theme.of(context).textTheme.bodyLarge!.color,
                      decoration: task.isCompleted
                          ? material.TextDecoration.lineThrough
                          : material.TextDecoration.none,
                    ),
                  ),
                ),
                material.Checkbox(
                  value: task.isCompleted,
                  onChanged: (value) {
                    if (value != null) {
                      onStatusChanged(value);
                    }
                  },
                  activeColor: material.Theme.of(context).primaryColor,
                ),
              ],
            ),
            const material.SizedBox(height: 8),
            material.Text(
              task.description,
              style: material.TextStyle(
                fontSize: 14,
                color: material.Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.7),
              ),
            ),
            const material.SizedBox(height: 8),
            // Display the created date and time
            material.Text(
              'Created: ${DateFormat('MMM d, yyyy h:mm a').format(task.createdDate)}',
              style: material.TextStyle(
                fontSize: 12,
                color: material.Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.5),
                fontStyle: material.FontStyle.italic,
              ),
            ),
            const material.SizedBox(height: 8),
            material.Row(
              mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
              children: [
                material.Row(
                  children: [
                    material.Icon(
                      material.Icons.flag,
                      size: 16,
                      color: task.priority == 1
                          ? material.Colors.green
                          : task.priority == 2
                              ? material.Colors.orange
                              : material.Colors.red,
                    ),
                    const material.SizedBox(width: 4),
                    material.Text(
                      task.priority == 1
                          ? 'Low'
                          : task.priority == 2
                              ? 'Medium'
                              : 'High',
                      style: material.TextStyle(
                        fontSize: 12,
                        color: material.Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                material.Row(
                  children: [
                    material.IconButton(
                      icon: const material.Icon(material.Icons.edit, size: 20),
                      color: material.Colors.grey,
                      onPressed: onEdit,
                      tooltip: 'Edit Task',
                    ),
                    material.IconButton(
                      icon: const material.Icon(material.Icons.delete, size: 20),
                      color: material.Colors.red,
                      onPressed: onDelete,
                      tooltip: 'Delete Task',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}