import 'package:flutter/material.dart';
import '../../data/models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = task.deadline.difference(now);
    final isExpired = remaining.isNegative;
    final isUrgent = remaining.inHours < 24 && !isExpired && !task.isCompleted;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Deadline'),
            content: Text('Are you sure you want to delete "${task.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
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
      },
      onDismissed: (direction) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isUrgent
                ? Colors.orange.withOpacity(0.4)
                : isExpired
                ? Colors.red.withOpacity(0.4)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildCheckbox(context),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event_outlined,
                                  size: 14,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(task.deadline),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(task.deadline),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).primaryColor.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildActionButtons(context),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCountdownTimer(context, remaining, isExpired, task.createdAt),
                  const SizedBox(height: 16),
                  Text(
                    task.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: task.isCompleted
                          ? Theme.of(context).textTheme.bodySmall?.color
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    return GestureDetector(
      onTap: onToggleComplete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: task.isCompleted
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          border: Border.all(
            color: task.isCompleted
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: task.isCompleted
            ? const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 18,
        )
            : null,
      ),
    );
  }

  Widget _buildCountdownTimer(BuildContext context, Duration remaining, bool isExpired, DateTime createdAt) {
    final color = task.isCompleted
        ? Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey
        : isExpired
        ? Colors.red.shade600
        : remaining.inHours < 24
        ? Colors.orange.shade700
        : Theme.of(context).primaryColor;

    final bgColor = color.withOpacity(0.08);
    final darkerColor = HSLColor.fromColor(color).withLightness(
      (HSLColor.fromColor(color).lightness - 0.15).clamp(0.0, 1.0)
    ).toColor();

    // Calculate remaining progress: how much time is LEFT (reverse order)
    final totalDuration = task.deadline.difference(createdAt);
    double remainingProgress = 1.0;
    if (!task.isCompleted && !isExpired && totalDuration.inSeconds > 0) {
      remainingProgress = (remaining.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);
    } else if (isExpired) {
      remainingProgress = 0.0;
    } else if (task.isCompleted) {
      remainingProgress = 0.0;
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // Progress bar embedded at the bottom of the container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: remainingProgress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: darkerColor,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(remainingProgress < 1.0 ? 3 : 0),
                          bottomRight: Radius.circular(remainingProgress < 1.0 ? 3 : 0),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Timer content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (task.isCompleted)
                  Icon(Icons.check_circle, size: 24, color: color)
                else if (isExpired)
                  Icon(Icons.warning_amber_rounded, size: 24, color: color)
                else
                  Icon(Icons.timer_outlined, size: 24, color: color),
                const SizedBox(width: 12),
                Text(
                  _formatCountdown(remaining),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.2,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).textTheme.bodySmall?.color),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              const Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatCountdown(Duration d) {
    if (task.isCompleted) return 'COMPLETED';
    if (d.isNegative) return 'EXPIRED';

    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
    } else if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${seconds}s';
    }
  }
}