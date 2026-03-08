import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/task.dart';
import '../../logic/bloc/task_bloc.dart';
import '../../logic/bloc/task_event.dart';

class AddTaskForm extends StatefulWidget {
  final Task? task;

  const AddTaskForm({super.key, this.task});

  @override
  State<AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<AddTaskForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task?.name ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');

    final deadline = widget.task?.deadline ?? DateTime.now();
    _selectedDate = DateTime(deadline.year, deadline.month, deadline.day);
    _selectedTime = TimeOfDay(hour: deadline.hour, minute: deadline.minute);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDragHandle(),
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isEditing ? Icons.edit_calendar_outlined : Icons.timer_outlined,
            color: colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          isEditing ? 'Edit Deadline' : 'New Deadline',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDateTimeSelectors(),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            autofocus: !isEditing,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              hintText: 'e.g., Project submission, Meeting',
              prefixIcon: Icon(
                Icons.title_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            validator: (value) =>
            value == null || value.trim().isEmpty
                ? 'Please enter a title'
                : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              hintText: 'Add notes or details about this deadline',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEditing ? Icons.check_rounded : Icons.timer_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'Update Deadline' : 'Start Countdown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelectors() {
    return Row(
      children: [
        Expanded(child: _buildDateSelector()),
        const SizedBox(width: 12),
        Expanded(child: _buildTimeSelector()),
      ],
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDateShort(_selectedDate),
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

  Widget _buildTimeSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.access_time_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Time',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(_selectedTime),
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.primaryColor,
              brightness: theme.brightness,
              primary: theme.primaryColor,
              onPrimary: Colors.white,
              surface: theme.cardColor,
              onSurface: theme.textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final theme = Theme.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.primaryColor,
              brightness: theme.brightness,
              primary: theme.primaryColor,
              onPrimary: Colors.white,
              surface: theme.cardColor,
              onSurface: theme.textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final deadline = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final bloc = context.read<TaskBloc>();

    if (isEditing) {
      final updatedTask = widget.task!.copyWith(
        name: _nameController.text.trim(),
        deadline: deadline,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      bloc.add(UpdateTask(updatedTask));
    } else {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        deadline: deadline,
        createdAt: DateTime.now(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      bloc.add(AddTask(task));
    }

    Navigator.pop(context);
  }

  String _formatDateShort(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}