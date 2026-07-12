import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/isar_database.dart';
import '../database/schemas/meeting_models.dart';
import '../providers/app_providers.dart';
import '../services/firestore_service.dart';

abstract class TaskRepository {
  Future<List<ActionItemModel>> getAllTasks();
  Stream<List<ActionItemModel>> watchTasks({bool? isCompleted});
  Future<void> updateTaskStatus(int taskId, bool isCompleted);
  Future<void> updateTask(ActionItemModel task);
  Future<void> deleteTask(int taskId);
  Future<Map<String, int>> getTaskStats();
}

class IsarTaskRepository implements TaskRepository {
  final Ref _ref;
  IsarTaskRepository(this._ref);

  Isar get _isar => IsarDatabase.instance.isar;

  String get _currentUserId {
    final uid = _ref.read(authRepositoryProvider).currentUser?.uid;
    return uid ?? 'offline_fallback';
  }

  @override
  Future<List<ActionItemModel>> getAllTasks() async {
    return await _isar.actionItemModels
        .filter()
        .userIdEqualTo(_currentUserId)
        .findAll();
  }

  @override
  Stream<List<ActionItemModel>> watchTasks({bool? isCompleted}) {
    var query = _isar.actionItemModels.filter().userIdEqualTo(_currentUserId);
    if (isCompleted != null) {
      return query.isCompletedEqualTo(isCompleted).watch(fireImmediately: true);
    }
    return query.watch(fireImmediately: true);
  }

  @override
  Future<void> updateTaskStatus(int taskId, bool isCompleted) async {
    final task = await _isar.actionItemModels.get(taskId);
    if (task == null || task.userId != _currentUserId) return;

    task.isCompleted = isCompleted;
    await _isar.writeTxn(() async {
      await _isar.actionItemModels.put(task);
    });
    FirestoreService.instance.saveTask(task, _currentUserId).catchError((e) {
      print(
        "[TaskRepository ERROR] updateTaskStatus Firestore sync failed: $e",
      );
    });
  }

  @override
  Future<void> updateTask(ActionItemModel task) async {
    if (task.userId != _currentUserId) return;
    await _isar.writeTxn(() async {
      await _isar.actionItemModels.put(task);
    });
    FirestoreService.instance.saveTask(task, _currentUserId).catchError((e) {
      print("[TaskRepository ERROR] updateTask Firestore sync failed: $e");
    });
  }

  @override
  Future<void> deleteTask(int taskId) async {
    final task = await _isar.actionItemModels.get(taskId);
    if (task == null || task.userId != _currentUserId) return;

    await _isar.writeTxn(() async {
      await _isar.actionItemModels.delete(taskId);
    });
    FirestoreService.instance.deleteTask(taskId, _currentUserId).catchError((
      e,
    ) {
      print("[TaskRepository ERROR] deleteTask Firestore sync failed: $e");
    });
  }

  @override
  Future<Map<String, int>> getTaskStats() async {
    final uid = _currentUserId;
    final total = await _isar.actionItemModels
        .filter()
        .userIdEqualTo(uid)
        .count();
    final completed = await _isar.actionItemModels
        .filter()
        .userIdEqualTo(uid)
        .isCompletedEqualTo(true)
        .count();
    final pending = total - completed;

    return {'total': total, 'completed': completed, 'pending': pending};
  }
}
