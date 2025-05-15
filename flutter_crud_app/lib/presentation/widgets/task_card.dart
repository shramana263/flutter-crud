import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../screens/task_form_screen.dart';

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
    final double screenWidth = material.MediaQuery.of(context).size.width;
    final double screenHeight = material.MediaQuery.of(context).size.height;
    final bool isDesktop = kIsWeb && screenWidth > 600;
    final double scaleFactor = isDesktop ? 0.4 : 1.0; // Reduce sizes by 60% on desktop
    const double maxFontSize = 16.0; // Cap font size for desktop

    return material.Card(
      elevation: 2,
      shape: material.RoundedRectangleBorder(
        borderRadius: material.BorderRadius.circular(12),
      ),
      child: material.Padding(
        padding: material.EdgeInsets.all((screenWidth * 0.04 * scaleFactor).clamp(0, 16)),
        child: material.Column(
          crossAxisAlignment: material.CrossAxisAlignment.start,
          children: [
            material.Row(
              children: [
                material.Expanded(
                  child: material.Text(
                    task.title,
                    style: material.TextStyle(
                      fontSize: (screenWidth * 0.045 * scaleFactor).clamp(0, maxFontSize),
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
            material.SizedBox(height: (screenHeight * 0.01 * scaleFactor).clamp(0, 8)),
            material.Text(
              task.description,
              style: material.TextStyle(
                fontSize: (screenWidth * 0.035 * scaleFactor).clamp(0, maxFontSize - 2),
                color: material.Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.7),
              ),
            ),
            material.SizedBox(height: (screenHeight * 0.01 * scaleFactor).clamp(0, 8)),
            material.Text(
              'Created: ${DateFormat('MMM d, yyyy h:mm a').format(task.createdDate)}',
              style: material.TextStyle(
                fontSize: (screenWidth * 0.03 * scaleFactor).clamp(0, maxFontSize - 4),
                color: material.Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.5),
                fontStyle: material.FontStyle.italic,
              ),
            ),
            material.SizedBox(height: (screenHeight * 0.01 * scaleFactor).clamp(0, 8)),
            material.Row(
              mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
              children: [
                material.Row(
                  children: [
                    material.Icon(
                      material.Icons.flag,
                      size: (screenWidth * 0.04 * scaleFactor).clamp(0, 16),
                      color: task.priority == 1
                          ? material.Colors.green
                          : task.priority == 2
                              ? material.Colors.orange
                              : material.Colors.red,
                    ),
                    material.SizedBox(width: (screenWidth * 0.01 * scaleFactor).clamp(0, 4)),
                    material.Text(
                      task.priority == 1
                          ? 'Low'
                          : task.priority == 2
                              ? 'Medium'
                              : 'High',
                      style: material.TextStyle(
                        fontSize: (screenWidth * 0.03 * scaleFactor).clamp(0, maxFontSize - 4),
                        color: material.Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                material.Row(
                  children: [
                    material.IconButton(
                      icon: material.Icon(material.Icons.edit, size: (screenWidth * 0.05 * scaleFactor).clamp(0, 20)),
                      color: material.Colors.grey,
                      onPressed: onEdit,
                      tooltip: 'Edit Task',
                    ),
                    material.IconButton(
                      icon: material.Icon(material.Icons.delete, size: (screenWidth * 0.05 * scaleFactor).clamp(0, 20)),
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