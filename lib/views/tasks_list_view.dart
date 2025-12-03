import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/navigation_model.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'task_form_view.dart';

class TasksListView extends StatefulWidget {
  const TasksListView({super.key});

  @override
  State<TasksListView> createState() => _TasksListViewState();
}

class _TasksListViewState extends State<TasksListView> {
  String _searchText = '';
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Refresh data every time the view becomes visible
    if (_isInit) {
      // First time - let provider handle initial load
      _isInit = false;
    } else {
      // Subsequent times - refresh data from the provider
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
    }
  }

  List<Task> _filterTasks(List<Task> tasks, String searchText) {
    if (searchText.isEmpty) {
      return tasks;
    }

    final lowerSearchText = searchText.toLowerCase();
    return tasks.where((task) {
      final title = task.title.toLowerCase();
      final category = (task.category ?? '').toLowerCase();
      final notes = (task.notes ?? '').toLowerCase();

      return title.contains(lowerSearchText) ||
          category.contains(lowerSearchText) ||
          notes.contains(lowerSearchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final navigationModel = Provider.of<NavigationModel>(context, listen: false);
    
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Tasks'),
              leading: IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => navigationModel.popToRoot(),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final filteredTasks = _filterTasks(provider.tasks, _searchText);

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Tasks'),
            leading: IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => navigationModel.popToRoot(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TaskFormView(),
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
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchText = '';
                              });
                            },
                          )
                        : null,
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
          body: provider.tasks.isEmpty
              ? _buildEmptyState(context)
              : _buildTasksList(context, provider, filteredTasks),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Tasks',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first task',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList(
      BuildContext context, TaskProvider provider, List<Task> filteredTasks) {
    return filteredTasks.isEmpty
        ? Padding(
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
          )
        : ListView.builder(
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return _buildTaskRow(context, task, provider);
            },
          );
  }

  Widget _buildTaskRow(
    BuildContext context,
    Task task,
    TaskProvider provider,
  ) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Are you sure you want to delete ${task.title}?'),
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
      },
      onDismissed: (direction) {
        provider.deleteTask(task.id);
      },
      child: ListTile(
        title: Text(
          task.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (task.category != null)
              Text(
                task.category!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),
            if (task.dueDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Due: ${DateFormat('MMM d, yyyy').format(task.dueDate!)} at ${DateFormat('h:mm a').format(task.dueDate!)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
            if (task.priority != null)
              Text(
                'Priority: ${task.priority!.value}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskFormView(
                task: task,
              ),
            ),
          );
        },
      ),
    );
  }
}

