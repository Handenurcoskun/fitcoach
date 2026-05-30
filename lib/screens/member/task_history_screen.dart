import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/task_model.dart';
import '../../models/task_completion_model.dart';
import '../../theme/app_theme.dart';

class TaskHistoryScreen extends StatefulWidget {
  final String memberId;

  const TaskHistoryScreen({super.key, required this.memberId});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  final _firestoreService = FirestoreService();

  List<_DayRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final now = DateTime.now();
      final endDate = TaskCompletionModel.dateKey(now);
      final startDate = TaskCompletionModel.dateKey(
          now.subtract(const Duration(days: 30)));

      List<TaskCompletionModel> completions = [];
      try {
        completions = await _firestoreService.getCompletionsForMemberDateRange(
          memberId: widget.memberId,
          startDate: startDate,
          endDate: endDate,
        );
      } catch (_) {}

      final tasks = await _firestoreService
          .watchTasksForMember(widget.memberId)
          .first;

      final Map<String, List<TaskCompletionModel>> byDate = {};
      for (final c in completions) {
        byDate.putIfAbsent(c.date, () => []).add(c);
      }

      final records = <_DayRecord>[];
      for (int i = 0; i <= 30; i++) {
        final date = now.subtract(Duration(days: i));
        final key = TaskCompletionModel.dateKey(date);
        final dayCompletions = byDate[key] ?? [];
        final completedCount = dayCompletions.where((c) => c.isCompleted).length;
        records.add(_DayRecord(
          date: date,
          completedCount: completedCount,
          totalCount: tasks.length,
          completions: dayCompletions,
          tasks: tasks,
        ));
      }

      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasAnyActivity = _records.any((r) => r.totalCount > 0);

    if (!hasAnyActivity) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('Henüz geçmiş veri yok',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Görevleri tamamladıkça burada görünecek.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final record = _records[index];
          return _DayCard(record: record);
        },
      ),
    );
  }
}

class _DayRecord {
  final DateTime date;
  final int completedCount;
  final int totalCount;
  final List<TaskCompletionModel> completions;
  final List<TaskModel> tasks;

  const _DayRecord({
    required this.date,
    required this.completedCount,
    required this.totalCount,
    required this.completions,
    required this.tasks,
  });
}

class _DayCard extends StatefulWidget {
  final _DayRecord record;

  const _DayCard({required this.record});

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final progress = r.totalCount > 0 ? r.completedCount / r.totalCount : 0.0;
    final isToday = TaskCompletionModel.dateKey(r.date) ==
        TaskCompletionModel.dateKey(DateTime.now());
    final color = progress == 1.0
        ? AppColors.success
        : progress > 0.5
            ? Colors.orangeAccent
            : r.completedCount == 0
                ? AppColors.textSecondary
                : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${r.date.day}',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday
                              ? 'Bugün'
                              : DateFormat('d MMMM, EEEE', 'tr_TR')
                                  .format(r.date),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: AppColors.cardBorder,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                  minHeight: 5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${r.completedCount}/${r.totalCount}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: r.tasks.map((task) {
                  final completion = r.completions.firstWhere(
                    (c) => c.taskId == task.id,
                    orElse: () => TaskCompletionModel(
                      id: '',
                      taskId: task.id,
                      memberId: '',
                      date: '',
                      isCompleted: false,
                    ),
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(task.type.emoji),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              color: completion.isCompleted
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration: completion.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(
                          completion.isCompleted
                              ? Icons.check_circle
                              : Icons.cancel_outlined,
                          color: completion.isCompleted
                              ? AppColors.success
                              : AppColors.error,
                          size: 18,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
