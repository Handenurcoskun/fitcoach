import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../models/task_completion_model.dart';
import '../../models/nutrition_log_model.dart';
import '../../theme/app_theme.dart';
import 'task_management_screen.dart';
import 'member_detail_screen.dart';

class TrainerHomeScreen extends StatefulWidget {
  const TrainerHomeScreen({super.key});

  @override
  State<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends State<TrainerHomeScreen> {
  final _firestoreService = FirestoreService();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final trainer = context.watch<AuthService>().currentUser!;
    final today = TaskCompletionModel.dateKey(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: _currentIndex == 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba, ${trainer.name.split(' ').first} 👋',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    DateFormat('d MMMM yyyy', 'tr_TR').format(DateTime.now()),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              )
            : Text(_currentIndex == 1 ? 'Görevler' : 'Profil'),
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
          _MembersTab(
            trainerId: trainer.id,
            inviteCode: trainer.inviteCode ?? '',
            today: today,
            firestoreService: _firestoreService,
          ),
          TaskManagementScreen(trainerId: trainer.id),
          _ProfileTab(trainer: trainer),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined),
            activeIcon: Icon(Icons.people),
            label: 'Üyeler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined),
            activeIcon: Icon(Icons.task),
            label: 'Görevler',
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
            child:
                const Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final String trainerId;
  final String inviteCode;
  final String today;
  final FirestoreService firestoreService;

  const _MembersTab({
    required this.trainerId,
    required this.inviteCode,
    required this.today,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: firestoreService.watchMembersForTrainer(trainerId),
      builder: (context, membersSnap) {
        if (membersSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final members = membersSnap.data ?? [];

        return StreamBuilder<List<TaskModel>>(
          stream: firestoreService.watchTasksForTrainer(trainerId),
          builder: (context, tasksSnap) {
            final tasks = (tasksSnap.data ?? []).where((t) => t.isActive).toList();
            final totalTaskCount = tasks.length;

            return StreamBuilder<List<TaskCompletionModel>>(
              stream: firestoreService.watchCompletionsForTrainerMembers(
                memberIds: members.map((m) => m.id).toList(),
                date: today,
              ),
              builder: (context, completionsSnap) {
                final completions = completionsSnap.data ?? [];

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _SummaryCard(
                        members: members,
                        completions: completions,
                        totalTaskCount: totalTaskCount,
                        inviteCode: inviteCode,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: members.isEmpty
                          ? SliverToBoxAdapter(child: _EmptyMembers(inviteCode: inviteCode))
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final member = members[index];
                                  final completedCount = completions
                                      .where((c) => c.memberId == member.id && c.isCompleted)
                                      .length;
                                  return _MemberCard(
                                    member: member,
                                    completedCount: completedCount,
                                    totalCount: totalTaskCount,
                                    today: today,
                                    firestoreService: firestoreService,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MemberDetailScreen(
                                          member: member,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: members.length,
                              ),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<UserModel> members;
  final List<TaskCompletionModel> completions;
  final int totalTaskCount;
  final String inviteCode;

  const _SummaryCard({
    required this.members,
    required this.completions,
    required this.totalTaskCount,
    required this.inviteCode,
  });

  @override
  Widget build(BuildContext context) {
    final completedToday = completions.where((c) => c.isCompleted).length;
    final totalToday = members.length * totalTaskCount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bugünkü Özet',
            style: TextStyle(
                color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  value: '${members.length}',
                  label: 'Üye',
                  icon: Icons.people,
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: '$completedToday',
                  label: 'Tamamlandı',
                  icon: Icons.check_circle,
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: totalToday > 0
                      ? '%${((completedToday / totalToday) * 100).round()}'
                      : '%0',
                  label: 'Oran',
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Davet Kodu: $inviteCode',
            style: const TextStyle(
                color: Colors.black54, fontSize: 11),
          ),
          Text(
            'Bu kodu üyelerinizle paylaşın',
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.black87, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  final UserModel member;
  final int completedCount;
  final int totalCount;
  final String today;
  final FirestoreService firestoreService;
  final VoidCallback onTap;

  const _MemberCard({
    required this.member,
    required this.completedCount,
    required this.totalCount,
    required this.today,
    required this.firestoreService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final taskColor = progress == 1.0
        ? AppColors.success
        : progress > 0.5
            ? Colors.orangeAccent
            : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                backgroundImage: member.photoUrl != null
                    ? NetworkImage(member.photoUrl!)
                    : null,
                child: member.photoUrl == null
                    ? Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 6),
                    // Görev progress
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.cardBorder,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(taskColor),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.task_alt,
                            size: 12, color: taskColor),
                        const SizedBox(width: 4),
                        Text(
                          '$completedCount / $totalCount görev',
                          style: TextStyle(
                              color: taskColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Beslenme özeti
                    StreamBuilder<List<NutritionLogModel>>(
                      stream: firestoreService.watchNutritionLogsForMember(
                        memberId: member.id,
                        date: today,
                      ),
                      builder: (context, snap) {
                        final logs = snap.data ?? [];
                        if (logs.isEmpty) {
                          return const Row(
                            children: [
                              Icon(Icons.restaurant_outlined,
                                  size: 12,
                                  color: AppColors.textSecondary),
                              SizedBox(width: 4),
                              Text('Beslenme girilmedi',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11)),
                            ],
                          );
                        }
                        final cal =
                            logs.fold(0.0, (s, l) => s + l.calories);
                        final p =
                            logs.fold(0.0, (s, l) => s + l.protein);
                        final c = logs.fold(0.0, (s, l) => s + l.carbs);
                        final f = logs.fold(0.0, (s, l) => s + l.fat);
                        return Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _MiniChip(
                                '🔥 ${cal.toStringAsFixed(0)} kcal',
                                AppColors.primary),
                            _MiniChip('P ${p.toStringAsFixed(0)}g',
                                const Color(0xFF2979FF)),
                            _MiniChip('K ${c.toStringAsFixed(0)}g',
                                const Color(0xFFFFAB00)),
                            _MiniChip('Y ${f.toStringAsFixed(0)}g',
                                AppColors.error),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniChip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  final String inviteCode;

  const _EmptyMembers({required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Henüz üye yok',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Üyelerinize aşağıdaki davet kodunu verin.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary),
              ),
              child: SelectableText(
                inviteCode,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'monospace',
                    fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  final UserModel trainer;

  const _ProfileTab({required this.trainer});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  UserModel get trainer => widget.trainer;
  bool _copied = false;

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: trainer.inviteCode ?? ''));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              backgroundImage: trainer.photoUrl != null
                  ? NetworkImage(trainer.photoUrl!)
                  : null,
              child: trainer.photoUrl == null
                  ? Text(
                      trainer.name.isNotEmpty
                          ? trainer.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              trainer.name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(trainer.email,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Text(
                'Trainer',
                style:
                    TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Davet Kodu',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text(
                          trainer.inviteCode ?? '',
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _copyCode(context),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _copied
                          ? const Icon(Icons.check_circle, color: AppColors.primary, key: ValueKey('check'))
                          : const Icon(Icons.copy_outlined, color: AppColors.textSecondary, key: ValueKey('copy')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: ListTile(
                leading: Icon(Icons.info_outline, color: AppColors.textSecondary),
                title: Text('Davet Kodunu Paylaşın',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text(
                  'Üyeleriniz kayıt olurken bu kodu girerek sizinle bağlanabilir.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _confirmDeleteAccount(context),
            icon: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
            label: const Text('Hesabı Sil', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.error),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Hesabın ve tüm verilerin kalıcı olarak silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await context.read<AuthService>().deleteAccount();
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
