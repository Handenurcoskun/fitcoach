import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/task_completion_model.dart';
import '../models/measurement_model.dart';
import '../models/nutrition_log_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Users ───────────────────────────────────────────────────────────────

  Future<List<UserModel>> getMembersForTrainer(String trainerId) async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'member')
        .where('trainerId', isEqualTo: trainerId)
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
  }

  Stream<List<UserModel>> watchMembersForTrainer(String trainerId) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'member')
        .where('trainerId', isEqualTo: trainerId)
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  // ─── Tasks ────────────────────────────────────────────────────────────────

  Stream<List<TaskModel>> watchTasksForTrainer(String trainerId) {
    return _db
        .collection('tasks')
        .where('trainerId', isEqualTo: trainerId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<TaskModel>> watchTasksForMember(String memberId) {
    return _db
        .collection('tasks')
        .where('assignedMemberIds', arrayContains: memberId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => TaskModel.fromMap(d.data(), d.id))
            .where((t) => t.isActive)
            .toList());
  }

  Future<void> createTask(TaskModel task) async {
    await _db.collection('tasks').add(task.toMap());
  }

  Future<void> updateTask(TaskModel task) async {
    await _db.collection('tasks').doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({'isActive': false});
  }

  Future<void> assignTaskToMember(String taskId, String memberId) async {
    await _db.collection('tasks').doc(taskId).update({
      'assignedMemberIds': FieldValue.arrayUnion([memberId]),
    });
  }

  Future<void> unassignTaskFromMember(String taskId, String memberId) async {
    await _db.collection('tasks').doc(taskId).update({
      'assignedMemberIds': FieldValue.arrayRemove([memberId]),
    });
  }

  // ─── Task Completions ─────────────────────────────────────────────────────

  String _completionDocId(String taskId, String memberId, String date) {
    return '${taskId}_${memberId}_$date';
  }

  Future<void> setTaskCompletion({
    required String taskId,
    required String memberId,
    required String date,
    required bool isCompleted,
    String? note,
  }) async {
    final docId = _completionDocId(taskId, memberId, date);
    final data = TaskCompletionModel(
      id: docId,
      taskId: taskId,
      memberId: memberId,
      date: date,
      isCompleted: isCompleted,
      note: note,
      completedAt: isCompleted ? DateTime.now() : null,
    );
    await _db.collection('task_completions').doc(docId).set(data.toMap());
  }

  Stream<List<TaskCompletionModel>> watchCompletionsForMember({
    required String memberId,
    required String date,
  }) {
    return _db
        .collection('task_completions')
        .where('memberId', isEqualTo: memberId)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((s) => s.docs
            .map((d) => TaskCompletionModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<List<TaskCompletionModel>> getCompletionsForMemberDateRange({
    required String memberId,
    required String startDate,
    required String endDate,
  }) async {
    final snap = await _db
        .collection('task_completions')
        .where('memberId', isEqualTo: memberId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();
    return snap.docs
        .map((d) => TaskCompletionModel.fromMap(d.data(), d.id))
        .toList();
  }

  Stream<List<TaskCompletionModel>> watchCompletionsForTrainerMembers({
    required List<String> memberIds,
    required String date,
  }) {
    if (memberIds.isEmpty) {
      return Stream.value([]);
    }
    return _db
        .collection('task_completions')
        .where('memberId', whereIn: memberIds)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((s) => s.docs
            .map((d) => TaskCompletionModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ─── Measurements ────────────────────────────────────────────────────────

  Future<void> addMeasurement(MeasurementModel m) async {
    await _db.collection('measurements').add(m.toMap());
  }

  Future<void> deleteMeasurement(String id) async {
    await _db.collection('measurements').doc(id).delete();
  }

  Stream<List<MeasurementModel>> watchMeasurementsForMember(String memberId) {
    return _db
        .collection('measurements')
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => MeasurementModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  // ─── Nutrition Logs ───────────────────────────────────────────────────────

  Future<void> addNutritionLog(NutritionLogModel log) async {
    await _db.collection('nutrition_logs').add(log.toMap());
  }

  Future<void> updateUserPhotoUrl(String uid, String photoUrl) async {
    await _db.collection('users').doc(uid).update({'photoUrl': photoUrl});
  }

  Future<void> deleteNutritionLog(String id) async {
    await _db.collection('nutrition_logs').doc(id).delete();
  }

  Stream<List<NutritionLogModel>> watchNutritionLogsForMember({
    required String memberId,
    required String date,
  }) {
    return _db
        .collection('nutrition_logs')
        .where('memberId', isEqualTo: memberId)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((s) => s.docs
            .map((d) => NutritionLogModel.fromMap(d.data(), d.id))
            .toList());
  }
}
