import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/task_model.dart';
import '../../models/task_completion_model.dart';
import '../../theme/app_theme.dart';
import 'task_history_screen.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  final _firestoreService = FirestoreService();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final member = context.watch<AuthService>().currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: _currentIndex == 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba, ${member.name.split(' ').first} 💪',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    DateFormat('d MMMM yyyy', 'tr_TR').format(DateTime.now()),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              )
            : const Text('Geçmiş'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _TodayTasksTab(memberId: member.id, firestoreService: _firestoreService),
          TaskHistoryScreen(memberId: member.id),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today),
            label: 'Bugün',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Geçmiş',
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthService>().signOut();
            },
            child: const Text('Çıkış Yap',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _TodayTasksTab extends StatelessWidget {
  final String memberId;
  final FirestoreService firestoreService;

  const _TodayTasksTab(
      {required this.memberId, required this.firestoreService});

  String get _today => TaskCompletionModel.dateKey(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: firestoreService.watchTasksForMember(memberId),
      builder: (context, tasksSnap) {
        if (tasksSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = tasksSnap.data ?? [];

        return StreamBuilder<List<TaskCompletionModel>>(
          stream: firestoreService.watchCompletionsForMember(
            memberId: memberId,
            date: _today,
          ),
          builder: (context, completionsSnap) {
            final completions = completionsSnap.data ?? [];
            final completedCount =
                completions.where((c) => c.isCompleted).length;

            if (tasks.isEmpty) {
              return const _EmptyTasksView();
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ProgressHeader(
                    completedCount: completedCount,
                    totalCount: tasks.length,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = tasks[index];
                        final completion = completions.firstWhere(
                          (c) => c.taskId == task.id,
                          orElse: () => TaskCompletionModel(
                            id: '',
                            taskId: task.id,
                            memberId: memberId,
                            date: _today,
                            isCompleted: false,
                          ),
                        );
                        return _MemberTaskCard(
                          task: task,
                          completion: completion,
                          onToggle: (isCompleted) =>
                              firestoreService.setTaskCompletion(
                            taskId: task.id,
                            memberId: memberId,
                            date: _today,
                            isCompleted: isCompleted,
                          ),
                        );
                      },
                      childCount: tasks.length,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int completedCount;
  final int totalCount;

  const _ProgressHeader(
      {required this.completedCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final progress =
        totalCount > 0 ? completedCount / totalCount : 0.0;
    final isAllDone = completedCount == totalCount && totalCount > 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAllDone
              ? [AppColors.primary, AppColors.primaryDark]
              : [AppColors.card, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isAllDone
            ? null
            : Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: isAllDone
                      ? Colors.black26
                      : AppColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAllDone ? Colors.black : AppColors.primary,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$completedCount',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isAllDone ? Colors.black : AppColors.primary,
                        ),
                      ),
                      Text(
                        '/ $totalCount',
                        style: TextStyle(
                          fontSize: 11,
                          color: isAllDone
                              ? Colors.black54
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAllDone
                      ? 'Harika! Tamamladın! 🎉'
                      : completedCount == 0
                          ? 'Hadi başlayalım!'
                          : 'İyi gidiyorsun!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isAllDone ? Colors.black : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAllDone
                      ? 'Bugün tüm görevlerini yaptın!'
                      : '${totalCount - completedCount} görev kaldı',
                  style: TextStyle(
                    color: isAllDone ? Colors.black54 : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isAllDone
                        ? Colors.black26
                        : AppColors.cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isAllDone ? Colors.black : AppColors.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskCompletionModel completion;
  final Future<void> Function(bool) onToggle;

  const _MemberTaskCard({
    required this.task,
    required this.completion,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = completion.isCompleted;

    return GestureDetector(
      onTap: () => onToggle(!isDone),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDone
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? AppColors.primary.withOpacity(0.4) : AppColors.cardBorder,
            width: isDone ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(task.type.emoji,
                    style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (isDone && completion.completedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tamamlandı: ${DateFormat('HH:mm').format(completion.completedAt!)}',
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isDone
                  ? const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 28, key: ValueKey(true))
                  : const Icon(Icons.radio_button_unchecked,
                      color: AppColors.textSecondary,
                      size: 28,
                      key: ValueKey(false)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTasksView extends StatelessWidget {
  const _EmptyTasksView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏋️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Henüz görev atanmadı',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Eğitmeniniz yakında görevler atayacak. Trainer ID\'nizi eğitmeninizle paylaşın.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
