import 'package:isar/isar.dart';
import '../database/isar_database.dart';
import '../database/schemas/meeting_models.dart';

abstract class TaskRepository {
  Future<List<ActionItemModel>> getAllTasks();
  Stream<List<ActionItemModel>> watchTasks({bool? isCompleted});
  Future<void> updateTaskStatus(int taskId, bool isCompleted);
  Future<void> updateTask(ActionItemModel task);
  Future<void> deleteTask(int taskId);
  Future<Map<String, int>> getTaskStats();
}

class IsarTaskRepository implements TaskRepository {
  Isar get _isar => IsarDatabase.instance.isar;

  @override
  Future<List<ActionItemModel>> getAllTasks() async {
    return await _isar.actionItemModels.where().findAll();
  }

  @override
  Stream<List<ActionItemModel>> watchTasks({bool? isCompleted}) {
    final query = _isar.actionItemModels.where();
    if (isCompleted != null) {
      return query.filter().isCompletedEqualTo(isCompleted).watch(fireImmediately: true);
    }
    return query.watch(fireImmediately: true);
  }

  @override
  Future<void> updateTaskStatus(int taskId, bool isCompleted) async {
    final task = await _isar.actionItemModels.get(taskId);
    if (task == null) return;
    
    task.isCompleted = isCompleted;
    await _isar.writeTxn(() async {
      await _isar.actionItemModels.put(task);
    });
  }

  @override
  Future<void> updateTask(ActionItemModel task) async {
    await _isar.writeTxn(() async {
      await _isar.actionItemModels.put(task);
    });
  }

  @override
  Future<void> deleteTask(int taskId) async {
    await _isar.writeTxn(() async {
      await _isar.actionItemModels.delete(taskId);
    });
  }

  @override
  Future<Map<String, int>> getTaskStats() async {
    final total = await _isar.actionItemModels.count();
    final completed = await _isar.actionItemModels.filter().isCompletedEqualTo(true).count();
    final pending = total - completed;

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
    };
  }
}
