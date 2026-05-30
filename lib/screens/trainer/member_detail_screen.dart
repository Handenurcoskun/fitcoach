import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../models/task_completion_model.dart';
import '../../theme/app_theme.dart';
import '../measurements/measurements_screen.dart';

class MemberDetailScreen extends StatefulWidget {
  final UserModel member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime.now();

  String get _dateKey => TaskCompletionModel.dateKey(_selectedDate);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Görev Ata',
            onPressed: () => _showTaskAssignment(context),
          ),
          IconButton(
            icon: const Icon(Icons.monitor_weight_outlined),
            tooltip: 'Ölçümler',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MeasurementsScreen(member: widget.member),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          _DateHeader(date: _selectedDate, onTap: _pickDate),
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: _firestoreService
                  .watchTasksForMember(widget.member.id),
              builder: (context, tasksSnap) {
                if (tasksSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = tasksSnap.data ?? [];

                return StreamBuilder<List<TaskCompletionModel>>(
                  stream: _firestoreService.watchCompletionsForMember(
                    memberId: widget.member.id,
                    date: _dateKey,
                  ),
                  builder: (context, completionsSnap) {
                    final completions = completionsSnap.data ?? [];

                    if (tasks.isEmpty) {
                      return const Center(
                        child: Text(
                          'Bu üyeye atanmış görev yok',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    final completedCount = completions
                        .where((c) => c.isCompleted)
                        .length;

                    return Column(
                      children: [
                        _ProgressSummary(
                          completedCount: completedCount,
                          totalCount: tasks.length,
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              final completion = completions.firstWhere(
                                (c) => c.taskId == task.id,
                                orElse: () => TaskCompletionModel(
                                  id: '',
                                  taskId: task.id,
                                  memberId: widget.member.id,
                                  date: _dateKey,
                                  isCompleted: false,
                                ),
                              );
                              return _TrainerTaskCard(
                                task: task,
                                completion: completion,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskAssignment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TaskAssignmentSheet(
        member: widget.member,
        service: _firestoreService,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateHeader({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isToday = TaskCompletionModel.dateKey(date) ==
        TaskCompletionModel.dateKey(DateTime.now());
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.surface,
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              isToday
                  ? 'Bugün - ${DateFormat('d MMMM', 'tr_TR').format(date)}'
                  : DateFormat('d MMMM yyyy', 'tr_TR').format(date),
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Text('Değiştir',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final int completedCount;
  final int totalCount;

  const _ProgressSummary(
      {required this.completedCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? AppColors.success : Colors.orangeAccent,
                  ),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$completedCount / $totalCount görev',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                completedCount == totalCount && totalCount > 0
                    ? 'Tüm görevler tamamlandı! 🎉'
                    : 'tamamlandı',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrainerTaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskCompletionModel completion;

  const _TrainerTaskCard({required this.task, required this.completion});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: completion.isCompleted
                ? AppColors.success.withOpacity(0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(task.type.emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: completion.isCompleted
                ? TextDecoration.lineThrough
                : null,
            color: completion.isCompleted
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.description.isNotEmpty)
              Text(task.description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            if (!completion.isCompleted && completion.note != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.close, size: 12, color: AppColors.error),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(completion.note!,
                          style: const TextStyle(color: AppColors.error, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: completion.isCompleted
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : completion.note != null
                ? const Icon(Icons.cancel, color: AppColors.error)
                : const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─── Task Assignment Sheet ────────────────────────────────────────────────────

class _TaskAssignmentSheet extends StatelessWidget {
  final UserModel member;
  final FirestoreService service;

  const _TaskAssignmentSheet({required this.member, required this.service});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('${member.name} – Görev Ataması',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Hangi görevleri alacağını seç',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: service.watchTasksForTrainer(member.trainerId ?? ''),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = snap.data ?? [];
                if (tasks.isEmpty) {
                  return const Center(
                    child: Text('Henüz görev oluşturulmamış.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isAssigned = task.assignedMemberIds.contains(member.id);
                    return CheckboxListTile(
                      value: isAssigned,
                      activeColor: AppColors.primary,
                      secondary: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: isAssigned
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(task.type.emoji,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      title: Text(task.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: task.description.isNotEmpty
                          ? Text(task.description,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                          : null,
                      onChanged: (val) {
                        if (val == true) {
                          service.assignTaskToMember(task.id, member.id);
                        } else {
                          service.unassignTaskFromMember(task.id, member.id);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ),
        ],
      ),
    );
  }
}
