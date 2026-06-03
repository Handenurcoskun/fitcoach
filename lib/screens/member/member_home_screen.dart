import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/task_model.dart';
import '../../models/task_completion_model.dart';
import '../../theme/app_theme.dart';
import 'task_history_screen.dart';
import 'nutrition_screen.dart';
import 'profile_screen.dart';
import '../measurements/measurements_screen.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  final _firestoreService = FirestoreService();
  int _currentIndex = 0;
  Key _historyKey = UniqueKey();

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
            : Text(_currentIndex == 1
              ? 'Geçmiş'
              : _currentIndex == 2
                  ? 'Ölçümlerim'
                  : _currentIndex == 3
                      ? 'Beslenme'
                      : 'Profil'),
        actions: const [],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _TodayTasksTab(memberId: member.id, firestoreService: _firestoreService),
          TaskHistoryScreen(key: _historyKey, memberId: member.id),
          MeasurementsScreen(member: member, canAdd: true),
          const NutritionScreen(),
          const MemberProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() {
          if (i == 1) _historyKey = UniqueKey();
          _currentIndex = i;
        }),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight_outlined),
            activeIcon: Icon(Icons.monitor_weight),
            label: 'Ölçümler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_outlined),
            activeIcon: Icon(Icons.restaurant),
            label: 'Beslenme',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
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
                          onAction: ({required bool isCompleted, String? note}) =>
                              firestoreService.setTaskCompletion(
                            taskId: task.id,
                            memberId: memberId,
                            date: _today,
                            isCompleted: isCompleted,
                            note: note,
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
              ? [AppColors.success, const Color(0xFF388E3C)]
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
  final Future<void> Function({required bool isCompleted, String? note}) onAction;

  const _MemberTaskCard({
    required this.task,
    required this.completion,
    required this.onAction,
  });

  bool get _isFailed => !completion.isCompleted && completion.note != null;

  void _showOptions(BuildContext context) {
    if (completion.isCompleted || _isFailed) {
      onAction(isCompleted: false, note: null);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(task.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Yaptım'),
                onPressed: () {
                  Navigator.pop(context);
                  onAction(isCompleted: true);
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                label: const Text('Yapamadım',
                    style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showFailDialog(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFailDialog(BuildContext context) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Neden yapamadın?'),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Sebep yaz (isteğe bağlı)...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onAction(
                isCompleted: false,
                note: noteCtrl.text.trim().isEmpty ? 'Neden belirtilmedi' : noteCtrl.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = completion.isCompleted;
    final isFailed = _isFailed;

    Color borderColor = AppColors.cardBorder;
    Color bgColor = AppColors.card;
    if (isDone) { borderColor = AppColors.success.withOpacity(0.4); bgColor = AppColors.success.withOpacity(0.08); }
    if (isFailed) { borderColor = AppColors.error.withOpacity(0.4); bgColor = AppColors.error.withOpacity(0.06); }

    return GestureDetector(
      onTap: () => _showOptions(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: (isDone || isFailed) ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: isDone ? AppColors.success.withOpacity(0.15)
                    : isFailed ? AppColors.error.withOpacity(0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(task.type.emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(task.description,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (isDone && completion.completedAt != null) ...[
                    const SizedBox(height: 4),
                    Text('Tamamlandı: ${DateFormat('HH:mm').format(completion.completedAt!)}',
                        style: const TextStyle(color: AppColors.success, fontSize: 11)),
                  ],
                  if (isFailed && completion.note != null) ...[
                    const SizedBox(height: 4),
                    Text('Yapamadım: ${completion.note}',
                        style: const TextStyle(color: AppColors.error, fontSize: 11)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isDone
                  ? const Icon(Icons.check_circle, color: AppColors.success, size: 28, key: ValueKey('done'))
                  : isFailed
                      ? const Icon(Icons.cancel, color: AppColors.error, size: 28, key: ValueKey('fail'))
                      : const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary, size: 28, key: ValueKey('none')),
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
              'Eğitmeniniz yakında görevler atayacak.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
