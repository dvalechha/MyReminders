import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/task_status_helper.dart';

/// Task card with "Ghost Card" UI for pending completion
/// Matches the visual design of SubscriptionCard with rounded corners
class TaskCard extends StatelessWidget {
  final Task task;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TaskCard({
    super.key,
    required this.task,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final isPending = provider.isTaskPendingCompletion(task.id);

        if (isPending) {
          return _buildGhostCard(context, provider);
        } else {
          return _buildNormalCard(context, provider);
        }
      },
    );
  }

  Widget _buildGhostCard(BuildContext context, TaskProvider provider) {
    final duration = provider.getCompletionTimerDuration(task.id) ?? 10;
    final totalSeconds = duration.toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: totalSeconds, end: 0.0),
      duration: Duration(seconds: duration),
      builder: (context, value, child) {
        final remainingSeconds = value.ceil();
        final progress = value / totalSeconds;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.green.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 12),
              // Task title
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Undo button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Marking as complete...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade700,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => provider.undoTaskCompletion(task.id),
                    icon: const Icon(Icons.undo, size: 16),
                    label: Text('Undo (${remainingSeconds}s)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade700,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNormalCard(BuildContext context, TaskProvider provider) {
    const brandBlue = Color(0xFF2D62ED);

    // Determine due date text color
    Color? dueDateColor;
    if (task.dueDate != null) {
      final now = DateTime.now();
      if (task.dueDate!.isBefore(now) && !isSameDay(task.dueDate, now)) {
        dueDateColor = Colors.red; // Overdue
      } else if (isSameDay(task.dueDate, now)) {
        dueDateColor = Colors.orange; // Today
      }
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: brandBlue, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Main content: Title and Due Date
            Expanded(
              child: Opacity(
                opacity: task.isCompleted ? 0.6 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Title (Bold, size 16) - strikethrough if completed
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    // Due Date (Grey, size 12, or Red/Orange if today/overdue)
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        formatTaskDueDate(task.dueDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: dueDateColor ?? Colors.grey[700],
                          fontWeight: FontWeight.w400,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Trailing: Chevron right (adaptive icon) or checkmark if selected
            if (isSelected)
              CircleAvatar(
                radius: 12,
                backgroundColor: brandBlue,
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else if (!provider.isSelectionMode)
              Platform.isIOS
                  ? const Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    )
                  : const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
          ],
        ),
      ),
    );
  }
}
