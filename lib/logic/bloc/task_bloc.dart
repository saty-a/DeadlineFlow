import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../services/notification_service.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _repository;
  Timer? _timer;

  TaskBloc({required TaskRepository repository})
      : _repository = repository,
        super(TaskState()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<ToggleTaskComplete>(_onToggleTaskComplete);
    on<RescheduleAllNotifications>(_onRescheduleAllNotifications);
    on<_TickInternal>(_onTick);

    _startTicker();
    add(LoadTasks());
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    try {
      emit(state.copyWith(status: TaskStatus.loading));
      final tasks = await _repository.loadTasks();
      emit(TaskState(
        tasks: tasks,
        timestamp: DateTime.now(),
        status: TaskStatus.success,
      ));
      await _repository.updateHomeWidget(tasks);
    } catch (e) {
      emit(state.copyWith(
        status: TaskStatus.error,
        errorMessage: 'Failed to load tasks: $e',
      ));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    try {
      final updatedTasks = List<Task>.from(state.tasks)..add(event.task);
      _repository.sortTasks(updatedTasks);
      emit(TaskState(
        tasks: updatedTasks,
        timestamp: DateTime.now(),
        status: TaskStatus.success,
      ));
      await _repository.saveTasks(updatedTasks);
      await NotificationService.instance.scheduleTaskReminders(event.task);
    } catch (e) {
      emit(state.copyWith(
        status: TaskStatus.error,
        errorMessage: 'Failed to add task: $e',
      ));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      final updatedTasks = state.tasks.map((task) {
        return task.id == event.task.id ? event.task : task;
      }).toList();
      _repository.sortTasks(updatedTasks);
      emit(TaskState(
        tasks: updatedTasks,
        timestamp: DateTime.now(),
        status: TaskStatus.success,
      ));
      await _repository.saveTasks(updatedTasks);
      await NotificationService.instance.scheduleTaskReminders(event.task);
    } catch (e) {
      emit(state.copyWith(
        status: TaskStatus.error,
        errorMessage: 'Failed to update task: $e',
      ));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      final updatedTasks = state.tasks
          .where((task) => task.id != event.taskId)
          .toList();
      _repository.sortTasks(updatedTasks);
      emit(TaskState(
        tasks: updatedTasks,
        timestamp: DateTime.now(),
        status: TaskStatus.success,
      ));
      await _repository.saveTasks(updatedTasks);
      await NotificationService.instance.cancelTaskNotifications(event.taskId);
    } catch (e) {
      emit(state.copyWith(
        status: TaskStatus.error,
        errorMessage: 'Failed to delete task: $e',
      ));
    }
  }

  Future<void> _onToggleTaskComplete(
      ToggleTaskComplete event, Emitter<TaskState> emit) async {
    try {
      final updatedTasks = state.tasks.map((task) {
        if (task.id == event.taskId) {
          return task.copyWith(isCompleted: !task.isCompleted);
        }
        return task;
      }).toList();
      _repository.sortTasks(updatedTasks);
      emit(TaskState(
        tasks: updatedTasks,
        timestamp: DateTime.now(),
        status: TaskStatus.success,
      ));
      await _repository.saveTasks(updatedTasks);
      // Cancel reminders when completed, reschedule when uncompleted
      final toggled = updatedTasks.firstWhere((t) => t.id == event.taskId);
      if (toggled.isCompleted) {
        await NotificationService.instance.cancelTaskNotifications(event.taskId);
      } else {
        await NotificationService.instance.scheduleTaskReminders(toggled);
      }
    } catch (e) {
      emit(state.copyWith(
        status: TaskStatus.error,
        errorMessage: 'Failed to toggle task: $e',
      ));
    }
  }

  Future<void> _onRescheduleAllNotifications(
      RescheduleAllNotifications event, Emitter<TaskState> emit) async {
    final now = DateTime.now();
    for (final task in state.tasks) {
      if (!task.isCompleted && task.deadline.isAfter(now)) {
        await NotificationService.instance.scheduleTaskReminders(task);
      }
    }
  }

  void _onTick(_TickInternal event, Emitter<TaskState> emit) {
    emit(TaskState(
      tasks: state.tasks,
      timestamp: DateTime.now(),
      status: state.status,
    ));
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(_TickInternal());
    });
  }

  void refreshHomeWidget() {
    _repository.updateHomeWidget(state.tasks);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

class _TickInternal extends TaskEvent {
  @override
  List<Object?> get props => [];
}