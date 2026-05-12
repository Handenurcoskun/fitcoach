import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/task_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(const DemoApp());
}

// ─── Models ───────────────────────────────────────────────────────────────────

class _Measurement {
  final String id;
  final String memberId;
  final DateTime date;
  final String gender;        // 'K' = Kadın, 'E' = Erkek
  final double? fatPercent;   // Yağ Oranı % (otomatik hesaplanır)
  final double? weightKg;     // Kilo
  final double? heightCm;     // Boy
  final double? neckCm;       // Boyun Çevresi
  final double? waistCm;      // Bel Çevresi
  final double? hipCm;        // Kalça Çevresi
  final String? note;

  const _Measurement({
    required this.id,
    required this.memberId,
    required this.date,
    this.gender = 'K',
    this.fatPercent,
    this.weightKg,
    this.heightCm,
    this.neckCm,
    this.waistCm,
    this.hipCm,
    this.note,
  });
}

// U.S. Navy Body Fat Formula
double _log10(double x) => math.log(x) / math.ln10;

double? _calcNavyBodyFat({
  required String gender,
  double? heightCm,
  double? neckCm,
  double? waistCm,
  double? hipCm,
}) {
  if (heightCm == null || neckCm == null || waistCm == null) return null;
  if (heightCm <= 0 || neckCm <= 0 || waistCm <= 0) return null;
  double fat;
  if (gender == 'E') {
    final diff = waistCm - neckCm;
    if (diff <= 0) return null;
    fat = 86.010 * _log10(diff) - 70.041 * _log10(heightCm) + 36.76;
  } else {
    if (hipCm == null || hipCm <= 0) return null;
    final sum = waistCm + hipCm - neckCm;
    if (sum <= 0) return null;
    fat = 163.205 * _log10(sum) - 97.684 * _log10(heightCm) - 78.387;
  }
  return fat.clamp(1.0, 60.0);
}

// Demo ölçüm verisi
final List<_Measurement> _measurements = [
  _Measurement(id: 'ms1', memberId: 'm1', date: DateTime(2026, 3, 1), gender: 'K', weightKg: 72, heightCm: 165, neckCm: 34, waistCm: 82, hipCm: 96, note: 'Program başlangıcı'),
  _Measurement(id: 'ms2', memberId: 'm1', date: DateTime(2026, 4, 1), gender: 'K', weightKg: 69, heightCm: 165, neckCm: 33, waistCm: 78, hipCm: 93),
  _Measurement(id: 'ms3', memberId: 'm1', date: DateTime(2026, 5, 1), gender: 'K', weightKg: 66, heightCm: 165, neckCm: 32, waistCm: 74, hipCm: 90),
  _Measurement(id: 'ms4', memberId: 'm2', date: DateTime(2026, 3, 1), gender: 'E', weightKg: 85, heightCm: 178, neckCm: 38, waistCm: 90, hipCm: 98, note: 'Program başlangıcı'),
  _Measurement(id: 'ms5', memberId: 'm2', date: DateTime(2026, 4, 15), gender: 'E', weightKg: 82, heightCm: 178, neckCm: 37, waistCm: 86, hipCm: 96),
];

class _MockTask {
  final String id;
  String title;
  TaskType type;
  String description;
  List<String> assignedMemberIds;

  _MockTask({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    List<String>? assignedMemberIds,
  }) : assignedMemberIds = assignedMemberIds ?? [];
}

class _MockMember {
  final String id;
  final String name;
  final String email;
  const _MockMember({required this.id, required this.name, required this.email});
}

const _members = [
  _MockMember(id: 'm1', name: 'Ayşe Kaya', email: 'ayse@example.com'),
  _MockMember(id: 'm2', name: 'Mehmet Demir', email: 'mehmet@example.com'),
  _MockMember(id: 'm3', name: 'Zeynep Çelik', email: 'zeynep@example.com'),
  _MockMember(id: 'm4', name: 'Ali Şahin', email: 'ali@example.com'),
];

// completions[memberId][taskId] = _TaskResult
class _TaskResult {
  final bool done;       // true=yaptım, false=yapamadım
  final String? note;   // yapamadım notu
  const _TaskResult({required this.done, this.note});
}

final Map<String, Map<String, _TaskResult>> _completions = {
  'm1': {
    '1': const _TaskResult(done: true),
    '2': const _TaskResult(done: true),
    '3': const _TaskResult(done: false, note: 'Gece geç oldu, fırsat bulamadım'),
    '4': const _TaskResult(done: true),
    '5': const _TaskResult(done: true),
  },
  'm2': {
    '1': const _TaskResult(done: true),
    '2': const _TaskResult(done: true),
    '3': const _TaskResult(done: true),
    '4': const _TaskResult(done: false, note: 'Evde yemek yoktu'),
    '5': const _TaskResult(done: false),
  },
  'm3': {
    '1': const _TaskResult(done: true),
    '2': const _TaskResult(done: false, note: 'Diz ağrısı vardı'),
  },
  'm4': {},
};

// ─── App ──────────────────────────────────────────────────────────────────────

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitCoach Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const _DemoSwitcher(),
    );
  }
}

class _DemoSwitcher extends StatefulWidget {
  const _DemoSwitcher();
  @override
  State<_DemoSwitcher> createState() => _DemoSwitcherState();
}

class _DemoSwitcherState extends State<_DemoSwitcher> {
  bool _isTrainer = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isTrainer ? const _TrainerDemo() : const _MemberDemo(memberId: 'm1', memberName: 'Ayşe'),
          Positioned(
            bottom: 90,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _SwitchBtn(label: 'Trainer', icon: Icons.sports, selected: _isTrainer, onTap: () => setState(() => _isTrainer = true)),
                _SwitchBtn(label: 'Üye', icon: Icons.person, selected: !_isTrainer, onTap: () => setState(() => _isTrainer = false)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SwitchBtn({required this.label, required this.icon, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: selected ? Colors.black : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: selected ? Colors.black : AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ─── Trainer Demo ─────────────────────────────────────────────────────────────

class _TrainerDemo extends StatefulWidget {
  const _TrainerDemo();
  @override
  State<_TrainerDemo> createState() => _TrainerDemoState();
}

class _TrainerDemoState extends State<_TrainerDemo> {
  int _tab = 0;

  // Tüm görevler burada tutulur, her iki tab da aynı listeyi görür
  final List<_MockTask> _tasks = [
    _MockTask(id: '1', title: 'Günde 2L Su İç', type: TaskType.water, description: 'Sabah, öğle ve akşam bölümlere ayır.', assignedMemberIds: ['m1', 'm2', 'm3', 'm4']),
    _MockTask(id: '2', title: 'Sabah Egzersizi', type: TaskType.exercise, description: '30 dakika kardiyo veya ağırlık çalışması.', assignedMemberIds: ['m1', 'm2', 'm3']),
    _MockTask(id: '3', title: 'Şükür Defteri', type: TaskType.gratitude, description: '3 şey için şükret ve yaz.', assignedMemberIds: ['m1', 'm2']),
    _MockTask(id: '4', title: 'Sağlıklı Kahvaltı', type: TaskType.nutrition, description: 'Protein ağırlıklı kahvaltı yap.', assignedMemberIds: ['m1', 'm4']),
    _MockTask(id: '5', title: '10.000 Adım', type: TaskType.steps, description: 'Gün içinde 10.000 adımı tamamla.', assignedMemberIds: ['m1']),
  ];

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _tab == 0
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Merhaba, Hande 👋', style: TextStyle(fontSize: 18)),
                Text(DateFormat('d MMMM yyyy', 'tr_TR').format(DateTime.now()), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ])
            : _tab == 1
                ? const Text('Görevler')
                : const Text('Ölçümler'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.4))),
            child: const Text('Demo', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _MembersTab(tasks: _tasks),
          _TasksTab(tasks: _tasks, onChanged: _rebuild),
          const _TrainerMeasurementsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people_outlined), activeIcon: Icon(Icons.people), label: 'Üyeler'),
          BottomNavigationBarItem(icon: Icon(Icons.task_outlined), activeIcon: Icon(Icons.task), label: 'Görevler'),
          BottomNavigationBarItem(icon: Icon(Icons.monitor_weight_outlined), activeIcon: Icon(Icons.monitor_weight), label: 'Ölçümler'),
        ],
      ),
    );
  }
}

// ─── Members Tab ──────────────────────────────────────────────────────────────

class _MembersTab extends StatefulWidget {
  final List<_MockTask> tasks;
  const _MembersTab({required this.tasks});
  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  _MockMember? _selected;

  @override
  Widget build(BuildContext context) {
    if (_selected != null) {
      return _MemberDetailView(
        member: _selected!,
        tasks: widget.tasks,
        onBack: () => setState(() => _selected = null),
      );
    }

    // Özet: tüm üyeler için bugün tamamlanan görev sayısı
    int totalCompleted = 0;
    int totalAssigned = 0;
    for (final m in _members) {
      final memberTasks = widget.tasks.where((t) => t.assignedMemberIds.contains(m.id)).toList();
      final mc = _completions[m.id] ?? {};
      totalAssigned += memberTasks.length;
      totalCompleted += memberTasks.where((t) => mc[t.id]?.done == true).length;
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // Özet kart
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            _Stat(value: '${_members.length}', label: 'Üye', icon: Icons.people),
            _Stat(value: '$totalCompleted', label: 'Tamamlandı', icon: Icons.check_circle),
            _Stat(value: '%${totalAssigned > 0 ? ((totalCompleted / totalAssigned) * 100).round() : 0}', label: 'Oran', icon: Icons.trending_up),
          ]),
        ),
        // Üye listesi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: _members.map((m) {
              final memberTasks = widget.tasks.where((t) => t.assignedMemberIds.contains(m.id)).toList();
              final mc = _completions[m.id] ?? {};
              final completed = memberTasks.where((t) => mc[t.id]?.done == true).length;
              final total = memberTasks.length;
              final progress = total > 0 ? completed / total : 0.0;
              final color = progress == 1.0 ? AppColors.primary : progress > 0.5 ? Colors.orangeAccent : total == 0 ? AppColors.textSecondary : AppColors.error;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => setState(() => _selected = m),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(m.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: progress, backgroundColor: AppColors.cardBorder, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0 ? 'Henüz görev atanmadı' : '$completed / $total görev tamamlandı',
                      style: TextStyle(color: total == 0 ? AppColors.textSecondary : AppColors.textSecondary, fontSize: 12),
                    ),
                  ]),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _Stat({required this.value, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Icon(icon, color: Colors.black87, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ]),
      );
}

class _MemberDetailView extends StatefulWidget {
  final _MockMember member;
  final List<_MockTask> tasks;
  final VoidCallback onBack;
  const _MemberDetailView({required this.member, required this.tasks, required this.onBack});
  @override
  State<_MemberDetailView> createState() => _MemberDetailViewState();
}

class _MemberDetailViewState extends State<_MemberDetailView> {
  _MockMember get member => widget.member;
  List<_MockTask> get tasks => widget.tasks;

  void _showTaskAssignment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${member.name} - Görev Ataması', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 4),
            Text('Hangi görevleri alacağını seç', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ...tasks.map((task) {
              final isAssigned = task.assignedMemberIds.contains(member.id);
              return CheckboxListTile(
                value: isAssigned,
                secondary: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: isAssigned ? AppColors.primary.withOpacity(0.15) : AppColors.surface, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(task.type.emoji, style: const TextStyle(fontSize: 20))),
                ),
                title: Text(task.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text(task.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                onChanged: (v) {
                  setModal(() {
                    if (v == true) {
                      task.assignedMemberIds.add(member.id);
                    } else {
                      task.assignedMemberIds.remove(member.id);
                    }
                  });
                  setState(() {});
                },
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tamam'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberTasks = tasks.where((t) => t.assignedMemberIds.contains(member.id)).toList();
    final mc = _completions[member.id] ?? {};
    final completed = memberTasks.where((t) => mc[t.id]?.done == true).length;
    final total = memberTasks.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: ListTile(
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
            title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('d MMMM yyyy', 'tr_TR').format(DateTime.now()), style: const TextStyle(color: AppColors.primary, fontSize: 12)),
            trailing: TextButton.icon(
              onPressed: () => _showTaskAssignment(context),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Görev Düzenle', style: TextStyle(fontSize: 12)),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
          child: Row(children: [
            SizedBox(
              width: 60, height: 60,
              child: Stack(fit: StackFit.expand, children: [
                CircularProgressIndicator(value: progress, strokeWidth: 6, backgroundColor: AppColors.cardBorder, valueColor: AlwaysStoppedAnimation<Color>(progress == 1.0 ? AppColors.primary : Colors.orangeAccent)),
                Center(child: Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ]),
            ),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$completed / $total görev', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(
                total == 0 ? 'Görev atanmadı' : progress == 1.0 ? 'Tüm görevler tamamlandı! 🎉' : 'tamamlandı',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ]),
          ]),
        ),
        total == 0
            ? const Expanded(child: Center(child: Text('Bu üyeye henüz görev atanmamış.', style: TextStyle(color: AppColors.textSecondary))))
            : Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: memberTasks.length,
                  itemBuilder: (context, index) {
                    final task = memberTasks[index];
                    final isDone = mc[task.id]?.done == true;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: isDone ? AppColors.primary.withOpacity(0.15) : AppColors.surface, borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text(task.type.emoji, style: const TextStyle(fontSize: 22))),
                        ),
                        title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w600, decoration: isDone ? TextDecoration.lineThrough : null, color: isDone ? AppColors.textSecondary : AppColors.textPrimary)),
                        subtitle: Builder(builder: (ctx) {
                          final result = (mc)[task.id];
                          final failNote = result?.done == false ? result?.note : null;
                          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (task.description.isNotEmpty) Text(task.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            if (result?.done == false) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.close, size: 12, color: AppColors.error),
                                  const SizedBox(width: 4),
                                  Text(
                                    failNote != null && failNote.isNotEmpty ? failNote : 'Yapamadım (neden belirtilmedi)',
                                    style: const TextStyle(color: AppColors.error, fontSize: 11),
                                  ),
                                ]),
                              ),
                            ],
                          ]);
                        }),
                        trailing: Icon(
                          isDone ? Icons.check_circle : (mc[task.id] != null ? Icons.cancel : Icons.radio_button_unchecked),
                          color: isDone ? AppColors.primary : (mc[task.id] != null ? AppColors.error : AppColors.textSecondary),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}

// ─── Tasks Tab ────────────────────────────────────────────────────────────────

class _TasksTab extends StatefulWidget {
  final List<_MockTask> tasks;
  final VoidCallback onChanged;
  const _TasksTab({required this.tasks, required this.onChanged});
  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  void _delete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Görevi Sil'),
        content: Text('"${widget.tasks[index].title}" silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.tasks.removeAt(index);
              widget.onChanged();
              setState(() {});
            },
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _openForm({_MockTask? existing, int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _TaskFormSheet(
        existing: existing,
        onSave: (task) {
          setState(() {
            if (index != null) {
              widget.tasks[index] = task;
            } else {
              widget.tasks.add(task);
            }
          });
          widget.onChanged();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widget.tasks.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.task_outlined, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text('Henüz görev yok', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                ElevatedButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('İlk Görevi Ekle')),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: widget.tasks.length,
              itemBuilder: (context, index) {
                final task = widget.tasks[index];
                // Kaç üyeye atanmış
                final assignedCount = task.assignedMemberIds.length;
                final assignedNames = _members
                    .where((m) => task.assignedMemberIds.contains(m.id))
                    .map((m) => m.name.split(' ').first)
                    .join(', ');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text(task.type.emoji, style: const TextStyle(fontSize: 22))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text(task.type.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ])),
                        IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary), onPressed: () => _openForm(existing: task, index: index)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: () => _delete(index)),
                      ]),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(task.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                      const SizedBox(height: 10),
                      // Atanan üyeler chip'leri
                      assignedCount == 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.error.withOpacity(0.3))),
                              child: const Text('Kimseye atanmadı', style: TextStyle(color: AppColors.error, fontSize: 11)),
                            )
                          : Wrap(spacing: 6, runSpacing: 6, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.people_outline, size: 12, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text('$assignedCount üye: $assignedNames', style: const TextStyle(color: AppColors.primary, fontSize: 11)),
                                ]),
                              ),
                            ]),
                    ]),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Görev Ekle'),
      ),
    );
  }
}

// ─── Task Form Sheet (Add / Edit) ─────────────────────────────────────────────

class _TaskFormSheet extends StatefulWidget {
  final _MockTask? existing;
  final void Function(_MockTask) onSave;
  const _TaskFormSheet({this.existing, required this.onSave});
  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TaskType _type;
  late List<String> _selectedMemberIds;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _type = widget.existing?.type ?? TaskType.custom;
    _selectedMemberIds = List<String>.from(widget.existing?.assignedMemberIds ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Başlık
          Row(children: [
            Text(isEdit ? 'Görevi Düzenle' : 'Yeni Görev', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),

          // Tip seçici
          const Text('Görev Tipi', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          SizedBox(
            height: 74,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: TaskType.values.map((type) {
                final isSel = _type == type;
                return GestureDetector(
                  onTap: () {
                    setState(() => _type = type);
                    if (_titleCtrl.text.isEmpty) _titleCtrl.text = type.label;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 10),
                    width: 70,
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSel ? AppColors.primary : AppColors.cardBorder, width: isSel ? 2 : 1),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(type.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(type.label, style: TextStyle(color: isSel ? AppColors.primary : AppColors.textSecondary, fontSize: 9), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Görev adı
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Görev Adı', hintText: 'Örn: Günde 2L su iç')),
          const SizedBox(height: 12),
          TextField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)')),
          const SizedBox(height: 20),

          // Üye ataması
          Row(children: [
            const Text('Üye Ataması', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() {
                if (_selectedMemberIds.length == _members.length) {
                  _selectedMemberIds.clear();
                } else {
                  _selectedMemberIds = _members.map((m) => m.id).toList();
                }
              }),
              child: Text(
                _selectedMemberIds.length == _members.length ? 'Tümünü Kaldır' : 'Tümünü Seç',
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
            child: Column(
              children: _members.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                final isSelected = _selectedMemberIds.contains(m.id);
                return Column(
                  children: [
                    CheckboxListTile(
                      value: isSelected,
                      title: Text(m.name, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(m.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      secondary: CircleAvatar(
                        radius: 18,
                        backgroundColor: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.card,
                        child: Text(m.name[0], style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      onChanged: (v) => setState(() {
                        if (v == true) _selectedMemberIds.add(m.id);
                        else _selectedMemberIds.remove(m.id);
                      }),
                    ),
                    if (i < _members.length - 1) const Divider(height: 1, indent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(context);
                widget.onSave(_MockTask(
                  id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  title: _titleCtrl.text.trim(),
                  type: _type,
                  description: _descCtrl.text.trim(),
                  assignedMemberIds: List.from(_selectedMemberIds),
                ));
              },
              child: Text(isEdit ? 'Güncelle' : 'Görevi Oluştur'),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Member Demo ──────────────────────────────────────────────────────────────

class _MemberDemo extends StatefulWidget {
  final String memberId;
  final String memberName;
  const _MemberDemo({required this.memberId, required this.memberName});
  @override
  State<_MemberDemo> createState() => _MemberDemoState();
}

class _MemberDemoState extends State<_MemberDemo> {
  // Üye için görevler (Ayşe'ye atananlar)
  final List<_MockTask> _memberTasks = [
    _MockTask(id: '1', title: 'Günde 2L Su İç', type: TaskType.water, description: 'Sabah, öğle ve akşam bölümlere ayır.'),
    _MockTask(id: '2', title: 'Sabah Egzersizi', type: TaskType.exercise, description: '30 dakika kardiyo veya ağırlık çalışması.'),
    _MockTask(id: '3', title: 'Şükür Defteri', type: TaskType.gratitude, description: '3 şey için şükret ve yaz.'),
    _MockTask(id: '4', title: 'Sağlıklı Kahvaltı', type: TaskType.nutrition, description: 'Protein ağırlıklı kahvaltı yap.'),
    _MockTask(id: '5', title: '10.000 Adım', type: TaskType.steps, description: 'Gün içinde 10.000 adımı tamamla.'),
  ];
  // null = henüz işlem yok, true = yapıldı, false = yapılamadı
  final List<bool?> _done = List.generate(5, (_) => null);
  final List<String?> _failNotes = List.generate(5, (_) => null);
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _tab == 0
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Merhaba, ${widget.memberName} 💪', style: const TextStyle(fontSize: 18)),
                Text(DateFormat('d MMMM yyyy', 'tr_TR').format(DateTime.now()), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ])
            : const Text('Geçmiş'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.4))),
            child: const Text('Demo', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _MemberTodayTab(
            tasks: _memberTasks,
            done: _done,
            failNotes: _failNotes,
            onDone: (i) => setState(() { _done[i] = true; _failNotes[i] = null; }),
            onFail: (i, note) => setState(() { _done[i] = false; _failNotes[i] = note; }),
            onReset: (i) => setState(() { _done[i] = null; _failNotes[i] = null; }),
          ),
          const _MemberHistoryTab(),
          _MemberMeasurementsScreen(memberId: widget.memberId),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today_outlined), activeIcon: Icon(Icons.today), label: 'Bugün'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Geçmiş'),
          BottomNavigationBarItem(icon: Icon(Icons.monitor_weight_outlined), activeIcon: Icon(Icons.monitor_weight), label: 'Ölçümler'),
        ],
      ),
    );
  }
}

class _MemberTodayTab extends StatelessWidget {
  final List<_MockTask> tasks;
  final List<bool?> done;
  final List<String?> failNotes;
  final void Function(int) onDone;
  final void Function(int, String?) onFail;
  final void Function(int) onReset;
  const _MemberTodayTab({required this.tasks, required this.done, required this.failNotes, required this.onDone, required this.onFail, required this.onReset});

  void _showFailDialog(BuildContext context, int index) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('${tasks[index].type.emoji} ${tasks[index].title}', style: const TextStyle(fontSize: 15)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Yapamadın, neden?', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Kısa bir not bırak (opsiyonel)...'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); onFail(index, null); }, child: const Text('Neden yok')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); onFail(index, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()); },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = done.where((d) => d == true).length;
    final total = tasks.length;
    final progress = total > 0 ? completed / total : 0.0;
    final isAllDone = completed == total && total > 0;

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAllDone ? [AppColors.primary, AppColors.primaryDark] : [AppColors.card, AppColors.surface],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: isAllDone ? null : Border.all(color: AppColors.cardBorder),
          ),
          child: Row(children: [
            SizedBox(
              width: 72, height: 72,
              child: Stack(fit: StackFit.expand, children: [
                CircularProgressIndicator(
                  value: progress, strokeWidth: 7,
                  backgroundColor: isAllDone ? Colors.black26 : AppColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(isAllDone ? Colors.black : AppColors.primary),
                ),
                Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$completed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isAllDone ? Colors.black : AppColors.primary)),
                  Text('/ $total', style: TextStyle(fontSize: 11, color: isAllDone ? Colors.black54 : AppColors.textSecondary)),
                ])),
              ]),
            ),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isAllDone ? 'Harika! Tamamladın! 🎉' : completed == 0 ? 'Hadi başlayalım!' : 'İyi gidiyorsun!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isAllDone ? Colors.black : AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(isAllDone ? 'Bugün tüm görevlerini yaptın!' : '${total - completed} görev kaldı',
                  style: TextStyle(color: isAllDone ? Colors.black54 : AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: isAllDone ? Colors.black26 : AppColors.cardBorder, valueColor: AlwaysStoppedAnimation<Color>(isAllDone ? Colors.black : AppColors.primary)),
              ),
            ])),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(tasks.length, (i) {
              final task = tasks[i];
              final status = done[i]; // null=bekliyor, true=yapıldı, false=yapılamadı
              final note = failNotes[i];

              Color cardColor = AppColors.card;
              Color borderColor = AppColors.cardBorder;
              double borderWidth = 1;
              if (status == true) { cardColor = AppColors.primary.withOpacity(0.08); borderColor = AppColors.primary.withOpacity(0.4); borderWidth = 1.5; }
              if (status == false) { cardColor = AppColors.error.withOpacity(0.06); borderColor = AppColors.error.withOpacity(0.35); borderWidth = 1.5; }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor, width: borderWidth)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    // Emoji ikon
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: status == true ? AppColors.primary.withOpacity(0.15) : status == false ? AppColors.error.withOpacity(0.12) : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(task.type.emoji, style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(task.title, style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15,
                        decoration: status == true ? TextDecoration.lineThrough : null,
                        color: status != null ? AppColors.textSecondary : AppColors.textPrimary,
                      )),
                      const SizedBox(height: 3),
                      Text(task.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    // Durum ikonu + sıfırla
                    if (status != null)
                      GestureDetector(
                        onTap: () => onReset(i),
                        child: Icon(
                          status == true ? Icons.check_circle : Icons.cancel,
                          color: status == true ? AppColors.primary : AppColors.error,
                          size: 28,
                        ),
                      ),
                  ]),
                  // Yapılamadı notu
                  if (status == false && note != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.notes, size: 14, color: AppColors.error),
                        const SizedBox(width: 6),
                        Expanded(child: Text(note, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                      ]),
                    ),
                  ],
                  // Aksiyon butonları (henüz işlem yapılmamışsa)
                  if (status == null) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onDone(i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withOpacity(0.4))),
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.check, color: AppColors.primary, size: 18),
                              SizedBox(width: 6),
                              Text('Yaptım', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showFailDialog(context, i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.error.withOpacity(0.35))),
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.close, color: AppColors.error, size: 18),
                              SizedBox(width: 6),
                              Text('Yapamadım', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ]),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Trainer Measurements Tab ─────────────────────────────────────────────────

class _TrainerMeasurementsTab extends StatefulWidget {
  const _TrainerMeasurementsTab();
  @override
  State<_TrainerMeasurementsTab> createState() => _TrainerMeasurementsTabState();
}

class _TrainerMeasurementsTabState extends State<_TrainerMeasurementsTab> {
  _MockMember? _selectedMember;

  @override
  Widget build(BuildContext context) {
    if (_selectedMember != null) {
      return _MemberMeasurementsView(
        member: _selectedMember!,
        onBack: () => setState(() => _selectedMember = null),
        onAdd: (m) => setState(() => _measurements.add(m)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.25))),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Üye seçerek ölçüm geçmişini görüntüleyebilir ve yeni ölçüm ekleyebilirsin.', style: TextStyle(color: AppColors.primary, fontSize: 13))),
          ]),
        ),
        const SizedBox(height: 16),
        ..._members.map((m) {
          final memberMs = _measurements.where((ms) => ms.memberId == m.id).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          final count = memberMs.length;
          final lastDate = count > 0 ? DateFormat('d MMM yyyy', 'tr_TR').format(memberMs.first.date) : 'Ölçüm yok';

          // Değişim hesabı (en eski vs en yeni)
          String weightChange = '';
          if (count >= 2) {
            final diff = (memberMs.first.weightKg ?? 0) - (memberMs.last.weightKg ?? 0);
            weightChange = diff <= 0 ? '${diff.toStringAsFixed(1)} kg' : '+${diff.toStringAsFixed(1)} kg';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () => setState(() => _selectedMember = m),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(m.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),
                Text('$count ölçüm · Son: $lastDate', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                if (weightChange.isNotEmpty)
                  Text('Kilo değişimi: $weightChange', style: TextStyle(color: weightChange.startsWith('-') ? AppColors.primary : AppColors.error, fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ),
          );
        }),
      ],
    );
  }
}

class _MemberMeasurementsView extends StatefulWidget {
  final _MockMember member;
  final VoidCallback onBack;
  final void Function(_Measurement) onAdd;
  const _MemberMeasurementsView({required this.member, required this.onBack, required this.onAdd});
  @override
  State<_MemberMeasurementsView> createState() => _MemberMeasurementsViewState();
}

class _MemberMeasurementsViewState extends State<_MemberMeasurementsView> {
  @override
  Widget build(BuildContext context) {
    final ms = _measurements.where((m) => m.memberId == widget.member.id).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: ListTile(
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
            title: Text(widget.member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${ms.length} ölçüm kaydı', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            trailing: ElevatedButton.icon(
              onPressed: () => _showAddMeasurement(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ekle', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36), padding: const EdgeInsets.symmetric(horizontal: 12)),
            ),
          ),
        ),
        if (ms.isEmpty)
          const Expanded(child: Center(child: Text('Henüz ölçüm girilmemiş.', style: TextStyle(color: AppColors.textSecondary))))
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Analiz kartı (ilk vs son)
                if (ms.length >= 2) _buildAnalysisCard(ms.first, ms.last),
                const SizedBox(height: 8),
                // Tüm ölçümler
                ...ms.reversed.map((m) => _MeasurementCard(measurement: m)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAnalysisCard(_Measurement first, _Measurement last) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
            child: const Text('Program Analizi', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Table(
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1.2), 3: FlexColumnWidth(1.2)},
              children: [
                _tableHeader(['Ölçüm', 'Başlangıç', 'Son', 'Fark']),
                _tableRow('Yağ Oranı (%)', _calcNavyBodyFat(gender: first.gender, heightCm: first.heightCm, neckCm: first.neckCm, waistCm: first.waistCm, hipCm: first.hipCm), _calcNavyBodyFat(gender: last.gender, heightCm: last.heightCm, neckCm: last.neckCm, waistCm: last.waistCm, hipCm: last.hipCm), suffix: '%', lowerIsBetter: true),
                _tableRow('Kilo (kg)', first.weightKg, last.weightKg, suffix: 'kg', lowerIsBetter: true),
                _tableRow('Boyun (cm)', first.neckCm, last.neckCm, suffix: 'cm', lowerIsBetter: true),
                _tableRow('Bel (cm)', first.waistCm, last.waistCm, suffix: 'cm', lowerIsBetter: true),
                _tableRow('Kalça (cm)', first.hipCm, last.hipCm, suffix: 'cm', lowerIsBetter: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${DateFormat('d MMM yyyy', 'tr_TR').format(first.date)} → ${DateFormat('d MMM yyyy', 'tr_TR').format(last.date)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  TableRow _tableHeader(List<String> cells) {
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.cardBorder))),
      children: cells.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(c, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
      )).toList(),
    );
  }

  TableRow _tableRow(String label, double? start, double? end, {required String suffix, required bool lowerIsBetter}) {
    final diff = (start != null && end != null) ? end - start : null;
    Color diffColor = AppColors.textSecondary;
    if (diff != null) {
      diffColor = (lowerIsBetter ? diff < 0 : diff > 0) ? AppColors.primary : AppColors.error;
    }
    final diffText = diff == null ? '-' : (diff > 0 ? '+${diff.toStringAsFixed(1)}' : diff.toStringAsFixed(1));

    return TableRow(children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(label, style: const TextStyle(fontSize: 12))),
      Text(start != null ? '${start.toStringAsFixed(1)}$suffix' : '-', style: const TextStyle(fontSize: 12)),
      Text(end != null ? '${end.toStringAsFixed(1)}$suffix' : '-', style: const TextStyle(fontSize: 12)),
      Text(diffText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: diffColor)),
    ]);
  }

  void _showAddMeasurement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _MeasurementFormSheet(
        memberId: widget.member.id,
        onSave: (m) {
          widget.onAdd(m);
          setState(() {});
        },
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final _Measurement measurement;
  const _MeasurementCard({required this.measurement});

  @override
  Widget build(BuildContext context) {
    final m = measurement;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(DateFormat('d MMMM yyyy', 'tr_TR').format(m.date), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            if (m.note != null) ...[
              const SizedBox(width: 8),
              Expanded(child: Text(m.note!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (m.weightKg != null) _MeasureTile(label: 'Kilo', value: '${m.weightKg!.toStringAsFixed(1)} kg', icon: '⚖️'),
              Builder(builder: (_) {
                final fat = _calcNavyBodyFat(gender: m.gender, heightCm: m.heightCm, neckCm: m.neckCm, waistCm: m.waistCm, hipCm: m.hipCm);
                return fat != null ? _MeasureTile(label: 'Yağ Oranı', value: '%${fat.toStringAsFixed(1)}', icon: '📊') : const SizedBox.shrink();
              }),
              if (m.heightCm != null) _MeasureTile(label: 'Boy', value: '${m.heightCm!.toStringAsFixed(0)} cm', icon: '📏'),
              if (m.neckCm != null) _MeasureTile(label: 'Boyun', value: '${m.neckCm!.toStringAsFixed(1)} cm', icon: '📐'),
              if (m.waistCm != null) _MeasureTile(label: 'Bel', value: '${m.waistCm!.toStringAsFixed(1)} cm', icon: '📐'),
              if (m.hipCm != null) _MeasureTile(label: 'Kalça', value: '${m.hipCm!.toStringAsFixed(1)} cm', icon: '📐'),
            ],
          ),
        ]),
      ),
    );
  }
}

class _MeasureTile extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _MeasureTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.cardBorder)),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10), textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─── Measurement Form Sheet ───────────────────────────────────────────────────

class _MeasurementFormSheet extends StatefulWidget {
  final String memberId;
  final void Function(_Measurement) onSave;
  const _MeasurementFormSheet({required this.memberId, required this.onSave});
  @override
  State<_MeasurementFormSheet> createState() => _MeasurementFormSheetState();
}

class _MeasurementFormSheetState extends State<_MeasurementFormSheet> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _neckCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _gender = 'K';

  @override
  void initState() {
    super.initState();
    for (final c in [_weightCtrl, _heightCtrl, _neckCtrl, _waistCtrl, _hipCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_weightCtrl, _heightCtrl, _neckCtrl, _waistCtrl, _hipCtrl, _noteCtrl]) c.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) => c.text.isEmpty ? null : double.tryParse(c.text.replaceAll(',', '.'));

  double? get _calculatedFat => _calcNavyBodyFat(
    gender: _gender,
    heightCm: _parse(_heightCtrl),
    neckCm: _parse(_neckCtrl),
    waistCm: _parse(_waistCtrl),
    hipCm: _parse(_hipCtrl),
  );

  @override
  Widget build(BuildContext context) {
    final fat = _calculatedFat;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Yeni Ölçüm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 4),
          // Tarih
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)), child: child!),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(DateFormat('d MMMM yyyy', 'tr_TR').format(_date), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          // Cinsiyet seçici
          const Text('Cinsiyet', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(children: [
            _GenderButton(label: 'Kadın', value: 'K', selected: _gender == 'K', onTap: () => setState(() => _gender = 'K')),
            const SizedBox(width: 10),
            _GenderButton(label: 'Erkek', value: 'E', selected: _gender == 'E', onTap: () => setState(() => _gender = 'E')),
          ]),
          const SizedBox(height: 20),
          // Ölçüm alanları — 2 sütun grid
          const Text('Vücut Ölçümleri', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(ctrl: _weightCtrl, label: 'Kilo (kg)', hint: '70.5')),
            const SizedBox(width: 12),
            Expanded(child: _Field(ctrl: _heightCtrl, label: 'Boy (cm)', hint: '165')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(ctrl: _neckCtrl, label: 'Boyun (cm)', hint: '34.0')),
            const SizedBox(width: 12),
            Expanded(child: _Field(ctrl: _waistCtrl, label: 'Bel (cm)', hint: '80.0')),
          ]),
          const SizedBox(height: 12),
          _Field(ctrl: _hipCtrl, label: 'Kalça (cm)', hint: '96.0'),
          const SizedBox(height: 16),
          // Hesaplanan yağ oranı önizlemesi
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: fat != null ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: fat != null ? AppColors.primary.withOpacity(0.4) : AppColors.cardBorder),
            ),
            child: Row(children: [
              const Text('📊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Vücut Yağ Oranı (U.S. Navy)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                fat != null
                    ? Text('%${fat.toStringAsFixed(1)}', style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold))
                    : const Text('Boy, boyun, bel ve kalça girilince hesaplanır', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          TextField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Not (opsiyonel)', hintText: 'Örn: Program başlangıcı')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onSave(_Measurement(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  memberId: widget.memberId,
                  date: _date,
                  gender: _gender,
                  fatPercent: fat,
                  weightKg: _parse(_weightCtrl),
                  heightCm: _parse(_heightCtrl),
                  neckCm: _parse(_neckCtrl),
                  waistCm: _parse(_waistCtrl),
                  hipCm: _parse(_hipCtrl),
                  note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
                ));
              },
              child: const Text('Ölçümü Kaydet'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _GenderButton({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.cardBorder, width: 1.5),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.black : AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  const _Field({required this.ctrl, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

// ─── Member Measurements Screen ───────────────────────────────────────────────

class _MemberMeasurementsScreen extends StatefulWidget {
  final String memberId;
  const _MemberMeasurementsScreen({required this.memberId});
  @override
  State<_MemberMeasurementsScreen> createState() => _MemberMeasurementsScreenState();
}

class _MemberMeasurementsScreenState extends State<_MemberMeasurementsScreen> {
  void _openForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _MeasurementFormSheet(
        memberId: widget.memberId,
        onSave: (m) => setState(() => _measurements.add(m)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ms = _measurements.where((m) => m.memberId == widget.memberId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ms.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.monitor_weight_outlined, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text('Henüz ölçüm yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('İlk ölçümünü girmek için aşağıdaki butona bas.', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _openForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Ölçüm Gir'),
                ),
              ]),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (ms.length >= 2) ...[
                  _buildMemberAnalysis(ms.first, ms.last),
                  const SizedBox(height: 8),
                ],
                ...ms.reversed.map((m) => _MeasurementCard(measurement: m)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Ölçüm Gir'),
      ),
    );
  }

  Widget _buildMemberAnalysis(_Measurement first, _Measurement last) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
          child: const Text('İlerleme Özeti', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              if (first.weightKg != null && last.weightKg != null)
                _ProgressChip(label: 'Kilo', diff: last.weightKg! - first.weightKg!, suffix: 'kg', lowerIsBetter: true),
              Builder(builder: (_) {
                final f1 = _calcNavyBodyFat(gender: first.gender, heightCm: first.heightCm, neckCm: first.neckCm, waistCm: first.waistCm, hipCm: first.hipCm);
                final f2 = _calcNavyBodyFat(gender: last.gender, heightCm: last.heightCm, neckCm: last.neckCm, waistCm: last.waistCm, hipCm: last.hipCm);
                return (f1 != null && f2 != null) ? _ProgressChip(label: 'Yağ %', diff: f2 - f1, suffix: '%', lowerIsBetter: true) : const SizedBox.shrink();
              }),
              if (first.waistCm != null && last.waistCm != null)
                _ProgressChip(label: 'Bel', diff: last.waistCm! - first.waistCm!, suffix: 'cm', lowerIsBetter: true),
              if (first.hipCm != null && last.hipCm != null)
                _ProgressChip(label: 'Kalça', diff: last.hipCm! - first.hipCm!, suffix: 'cm', lowerIsBetter: true),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final String label;
  final double diff;
  final String suffix;
  final bool lowerIsBetter;
  const _ProgressChip({required this.label, required this.diff, required this.suffix, required this.lowerIsBetter});

  @override
  Widget build(BuildContext context) {
    final isGood = lowerIsBetter ? diff < 0 : diff > 0;
    final color = isGood ? AppColors.primary : AppColors.error;
    final sign = diff > 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$sign${diff.toStringAsFixed(1)}$suffix', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
      ]),
    );
  }
}

class _MemberHistoryTab extends StatelessWidget {
  const _MemberHistoryTab();
  @override
  Widget build(BuildContext context) {
    final history = List.generate(7, (i) => {
      'date': DateTime.now().subtract(Duration(days: i + 1)),
      'completed': [5, 4, 2, 5, 3, 0, 5][i],
      'total': 5,
    });
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: history.length,
      itemBuilder: (context, i) {
        final h = history[i];
        final date = h['date'] as DateTime;
        final completed = h['completed'] as int;
        final total = h['total'] as int;
        final progress = total > 0 ? completed / total : 0.0;
        final color = progress == 1.0 ? AppColors.primary : progress > 0.5 ? Colors.orangeAccent : AppColors.error;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('${date.day}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(DateFormat('d MMMM, EEEE', 'tr_TR').format(date), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: AppColors.cardBorder, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 5))),
                  const SizedBox(width: 8),
                  Text('$completed/$total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ])),
            ]),
          ),
        );
      },
    );
  }
}
