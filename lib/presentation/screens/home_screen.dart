import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/bloc/task_bloc.dart';
import '../../logic/bloc/task_event.dart';
import '../../logic/bloc/task_state.dart';
import '../../data/models/task.dart';
import '../widgets/add_task_form.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _filterOption = 'active'; // all, active, completed, expired

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          _buildFilterChips(),
          BlocConsumer<TaskBloc, TaskState>(
            listener: (context, state) {
              if (state.status == TaskStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'An error occurred'),
                    backgroundColor: Colors.red.shade400,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state.status == TaskStatus.loading && state.tasks.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final filteredTasks = _getFilteredTasks(state.tasks);

              if (filteredTasks.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyState(
                    filterOption: _filterOption,
                    onReset: () => setState(() => _filterOption = 'all'),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final task = filteredTasks[index];
                      return TaskCard(
                        task: task,
                        onEdit: () => _showEditTaskSheet(context, task),
                        onDelete: () => _confirmDelete(context, task),
                        onToggleComplete: () {
                          context.read<TaskBloc>().add(
                            ToggleTaskComplete(task.id),
                          );
                        },
                        onTryAgain: () => _showEditTaskSheet(context, task),
                      );
                    },
                    childCount: filteredTasks.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deadline Flow',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                final activeCount = state.tasks
                    .where((t) =>
                !t.isCompleted && t.deadline.isAfter(DateTime.now()))
                    .length;
                if (activeCount == 0) return const SizedBox.shrink();
                return Text(
                  '$activeCount active countdown${activeCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_rounded, color: Theme.of(context).appBarTheme.titleTextStyle?.color),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            ).then((_) {
              if (context.mounted) {
                context.read<TaskBloc>().add(RescheduleAllNotifications());
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', 'all', Icons.list_rounded),
              const SizedBox(width: 8),
              _buildFilterChip('Active', 'active', Icons.play_circle_outline),
              const SizedBox(width: 8),
              _buildFilterChip('Completed', 'completed', Icons.check_circle_outline),
              const SizedBox(width: 8),
              _buildFilterChip('Expired', 'expired', Icons.timer_off_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filterOption == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() => _filterOption = value);
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: FontWeight.w600,
      ),
      elevation: isSelected ? 4 : 0,
      shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).dividerColor,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddTaskSheet(context),
      icon: const Icon(Icons.timer_outlined),
      label: const Text('Add Deadline'),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 4,
    );
  }

  List<Task> _getFilteredTasks(List<Task> tasks) {
    final now = DateTime.now();
    switch (_filterOption) {
      case 'active':
        return tasks.where((t) => !t.isCompleted && t.deadline.isAfter(now)).toList();
      case 'completed':
        return tasks.where((t) => t.isCompleted).toList();
      case 'expired':
        return tasks.where((t) => !t.isCompleted && t.deadline.isBefore(now)).toList();
      default:
        return tasks;
    }
  }

  void _showAddTaskSheet(BuildContext context) {
    final taskBloc = context.read<TaskBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: taskBloc,
        child: const AddTaskForm(),
      ),
    );
  }

  void _showEditTaskSheet(BuildContext context, Task task) {
    final taskBloc = context.read<TaskBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: taskBloc,
        child: AddTaskForm(task: task),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              this.context.read<TaskBloc>().add(DeleteTask(task.id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}