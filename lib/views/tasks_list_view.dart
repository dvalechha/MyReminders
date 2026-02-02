import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/selection_app_bar.dart';
import '../utils/task_status_helper.dart';
import 'task_form_view.dart';
import 'main_navigation_view.dart';

class TasksListView extends StatefulWidget {
  const TasksListView({super.key});

  @override
  State<TasksListView> createState() => _TasksListViewState();
}

class _TasksListViewState extends State<TasksListView> {
  String _searchText = '';
  TaskPriority? _filterPriority;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool? _filterCompleted = false; // Default to Active only

  @override
  void initState() {
    super.initState();
    // Use a PostFrameCallback to ensure the context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data every time dependencies change (e.g., when returning to this view)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
    });
  }

  List<Task> _filterTasks(List<Task> tasks, String searchText) {
    var filtered = tasks;

    // Apply search filter
    if (searchText.isNotEmpty) {
      final lowerSearchText = searchText.toLowerCase();
      filtered = filtered.where((task) {
        final title = task.title.toLowerCase();
        final notes = (task.notes ?? '').toLowerCase();
        return title.contains(lowerSearchText) ||
            notes.contains(lowerSearchText);
      }).toList();
    }

    // Apply priority filter
    if (_filterPriority != null) {
      filtered = filtered.where((task) => task.priority == _filterPriority).toList();
    }

    // Apply completion filter
    // null = Show All
    // true = Show Completed Only
    // false = Show Incomplete Only
    if (_filterCompleted != null) {
      filtered = filtered.where((task) => task.isCompleted == _filterCompleted).toList();
    }

    // Apply date range filter
    if (_filterStartDate != null || _filterEndDate != null) {
      filtered = filtered.where((task) {
        if (task.dueDate == null) return false;
        final dueDate = task.dueDate!;
        if (_filterStartDate != null && dueDate.isBefore(_filterStartDate!)) {
          return false;
        }
        if (_filterEndDate != null && dueDate.isAfter(_filterEndDate!)) {
          return false;
        }
        return true;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Tasks'),
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final filteredTasks = _filterTasks(provider.tasks, _searchText);

        return PopScope(
          canPop: !provider.isSelectionMode,
          onPopInvoked: (didPop) {
            if (!didPop && provider.isSelectionMode) {
              provider.clearSelection();
            }
          },
          child: Scaffold(
            appBar: provider.isSelectionMode
                ? SelectionAppBar(
                    selectionCount: provider.selectedIds.length,
                    onClearSelection: provider.clearSelection,
                    onDeleteSelected: () => _handleDeleteSelected(context, provider),
                  )
                : AppBar(
                    title: const Text('My Tasks'),
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          MainNavigationKeys.homeNavigatorKey.currentState?.push(
                            MaterialPageRoute(
                              builder: (context) => const TaskFormView(),
                              settings: const RouteSettings(name: 'TaskFormView'),
                            ),
                          );
                        },
                      ),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(56),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchText = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search tasks...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Filter icon
                                IconButton(
                                  icon: Stack(
                                    children: [
                                      const Icon(Icons.tune, size: 20),
                                      if (_filterPriority != null ||
                                          _filterStartDate != null ||
                                          _filterEndDate != null ||
                                          _filterCompleted != null)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.blue,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  onPressed: () async {
                                    final result = await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (context) => TaskFilterDialog(
                                        initialPriority: _filterPriority,
                                        initialStartDate: _filterStartDate,
                                        initialEndDate: _filterEndDate,
                                        initialCompleted: _filterCompleted,
                                      ),
                                    );
                                    if (result != null) {
                                      setState(() {
                                        _filterPriority = result['priority'] as TaskPriority?;
                                        _filterStartDate = result['startDate'] as DateTime?;
                                        _filterEndDate = result['endDate'] as DateTime?;
                                        _filterCompleted = result['completed'] as bool?;
                                      });
                                    }
                                  },
                                ),
                                // Clear icon (only show when there's text)
                                if (_searchText.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _searchText = '';
                                      });
                                    },
                                  ),
                              ],
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            backgroundColor: Colors.grey[100], // Light grey background
            body: provider.tasks.isEmpty
                ? _buildEmptyState(context)
                : _buildTasksList(context, provider, filteredTasks),
          ),
        );
      },
    );
  }

  void _handleDeleteSelected(BuildContext context, TaskProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tasks'),
        content: Text('Are you sure you want to delete ${provider.selectedIds.length} tasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteSelected();
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateView(
      icon: Icons.check_circle_outline_rounded,
      title: 'No Pending Tasks',
      description: 'Capture your to-dos, set priorities, and get things done.',
      buttonText: 'Create Task',
      onPressed: () {
        MainNavigationKeys.homeNavigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const TaskFormView(),
            settings: const RouteSettings(name: 'TaskFormView'),
          ),
        );
      },
    );
  }

  Widget _buildTasksList(
      BuildContext context, TaskProvider provider, List<Task> filteredTasks) {
    if (filteredTasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    // Sort tasks: incomplete first, then by overdue status, due date, and priority
    // Completed tasks go to the bottom
    final sortedTasks = List<Task>.from(filteredTasks);
    sortedTasks.sort((a, b) {
      // Completed tasks go to the bottom
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      
      // If both are completed or both incomplete, sort normally
      final now = DateTime.now();
      final aOverdue = a.dueDate != null && a.dueDate!.isBefore(now) && !isSameDay(a.dueDate, now);
      final bOverdue = b.dueDate != null && b.dueDate!.isBefore(now) && !isSameDay(b.dueDate, now);
      
      if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;
      
      final priorityOrder = {TaskPriority.high: 0, TaskPriority.medium: 1, TaskPriority.low: 2};
      final aPriority = priorityOrder[a.priority] ?? 3;
      final bPriority = priorityOrder[b.priority] ?? 3;
      return aPriority.compareTo(bPriority);
    });

    // Determine scroll physics based on platform
    final scrollPhysics = Platform.isIOS
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      physics: scrollPhysics,
      itemCount: sortedTasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        return _buildTaskCard(context, task, provider);
      },
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    Task task,
    TaskProvider provider,
  ) {
    final isSelected = provider.selectedIds.contains(task.id);

    // Don't allow swipe if task is already completed
    final canSwipe = !task.isCompleted && !provider.isSelectionMode;

    final cardContent = TaskCard(
      task: task,
      isSelected: isSelected,
      onTap: () {
        if (provider.isSelectionMode) {
          provider.toggleSelection(task.id);
        } else {
          MainNavigationKeys.homeNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => TaskFormView(
                task: task,
              ),
              settings: const RouteSettings(name: 'TaskFormView'),
            ),
          );
        }
      },
      onLongPress: () {
        HapticFeedback.lightImpact();
        provider.toggleSelection(task.id);
      },
    );

    // Wrap in Dismissible for swipe-to-complete (left to right)
    return Dismissible(
      key: Key(task.id),
      direction: canSwipe ? DismissDirection.startToEnd : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.check_circle, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Trigger completion with timer, but don't actually dismiss
          await provider.startTaskCompletion(task.id);
          return false; // Don't remove from list
        }
        return false;
      },
      child: cardContent,
    );
  }
}


