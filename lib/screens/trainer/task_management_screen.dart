import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/task_model.dart';
import '../../theme/app_theme.dart';
import 'add_task_screen.dart';

class TaskManagementScreen extends StatelessWidget {
  final String trainerId;

  const TaskManagementScreen({super.key, required this.trainerId});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<TaskModel>>(
        stream: service.watchTasksForTrainer(trainerId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snap.data ?? [];

          if (tasks.isEmpty) {
            return _EmptyTasks(trainerId: trainerId);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskManagementCard(
                task: task,
                service: service,
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTaskScreen(
                      trainerId: trainerId,
                      existingTask: task,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTaskScreen(trainerId: trainerId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Görev Ekle'),
      ),
    );
  }
}

class _TaskManagementCard extends StatelessWidget {
  final TaskModel task;
  final FirestoreService service;
  final VoidCallback onEdit;

  const _TaskManagementCard({
    required this.task,
    required this.service,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(task.type.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Text(
                        task.type.label,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.textSecondary),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                task.description,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${task.assignedMemberIds.length} üyeye atandı',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Görevi Sil'),
        content: Text('"${task.title}" görevini silmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              service.deleteTask(task.id);
            },
            child: const Text('Sil',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  final String trainerId;

  const _EmptyTasks({required this.trainerId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Henüz görev yok',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Üyeleriniz için günlük görevler oluşturun.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTaskScreen(trainerId: trainerId),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('İlk Görevi Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
