import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/firestore_service.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class AddTaskScreen extends StatefulWidget {
  final String trainerId;
  final TaskModel? existingTask;

  const AddTaskScreen({
    super.key,
    required this.trainerId,
    this.existingTask,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _firestoreService = FirestoreService();

  TaskType _selectedType = TaskType.custom;
  List<String> _selectedMemberIds = [];
  List<UserModel> _members = [];
  bool _isLoading = false;
  bool _loadingMembers = true;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final task = widget.existingTask!;
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _selectedType = task.type;
      _selectedMemberIds = List.from(task.assignedMemberIds);
    }
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members =
        await _firestoreService.getMembersForTrainer(widget.trainerId);
    setState(() {
      _members = members;
      _loadingMembers = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final task = TaskModel(
      id: _isEditing ? widget.existingTask!.id : const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      trainerId: widget.trainerId,
      assignedMemberIds: _selectedMemberIds,
      isActive: true,
      createdAt: _isEditing
          ? widget.existingTask!.createdAt
          : DateTime.now(),
    );

    if (_isEditing) {
      await _firestoreService.updateTask(task);
    } else {
      await _firestoreService.createTask(task);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Görevi Düzenle' : 'Görev Ekle'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTypePicker(),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Görev Adı',
                hintText: 'Örn: Günde 2L su iç',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Görev adı gerekli' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Açıklama (opsiyonel)',
                hintText: 'Göreve dair detaylar...',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Üye Ataması',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _loadingMembers
                ? const Center(child: CircularProgressIndicator())
                : _members.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Text(
                          'Henüz üye yok. Üyeler kayıt olduğunda burada görünecek.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : _buildMemberList(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : Text(_isEditing ? 'Güncelle' : 'Görevi Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Görev Tipi',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: TaskType.values.length,
            itemBuilder: (context, index) {
              final type = TaskType.values[index];
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedType = type);
                  if (_titleController.text.isEmpty) {
                    _titleController.text = type.label;
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  width: 72,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.cardBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(type.emoji,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        type.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemberList() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Tümünü Seç'),
            trailing: Checkbox(
              value: _selectedMemberIds.length == _members.length &&
                  _members.isNotEmpty,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedMemberIds = _members.map((m) => m.id).toList();
                  } else {
                    _selectedMemberIds = [];
                  }
                });
              },
            ),
          ),
          const Divider(height: 1),
          ..._members.map((member) {
            final isSelected = _selectedMemberIds.contains(member.id);
            return CheckboxListTile(
              value: isSelected,
              title: Text(member.name),
              subtitle: Text(member.email,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedMemberIds.add(member.id);
                  } else {
                    _selectedMemberIds.remove(member.id);
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }
}
