import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_log_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'add_food_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime.now();

  String get _dateKey {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Future<void> _openAddFood(String memberId, MealType? preset) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFoodScreen(
          memberId: memberId,
          date: _dateKey,
          presetMealType: preset,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = context.read<AuthService>().currentUser!;

    return StreamBuilder<List<NutritionLogModel>>(
      stream: _firestoreService.watchNutritionLogsForMember(
        memberId: member.id,
        date: _dateKey,
      ),
      builder: (context, snap) {
        final logs = snap.data ?? [];

        final totalCalories = logs.fold(0.0, (s, l) => s + l.calories);
        final totalProtein = logs.fold(0.0, (s, l) => s + l.protein);
        final totalCarbs = logs.fold(0.0, (s, l) => s + l.carbs);
        final totalFat = logs.fold(0.0, (s, l) => s + l.fat);

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _DateNavigator(
                    selectedDate: _selectedDate,
                    isToday: _isToday,
                    onPrev: () => setState(() => _selectedDate =
                        _selectedDate.subtract(const Duration(days: 1))),
                    onNext: _isToday
                        ? null
                        : () => setState(() => _selectedDate =
                            _selectedDate.add(const Duration(days: 1))),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _MacrosSummaryCard(
                    calories: totalCalories,
                    protein: totalProtein,
                    carbs: totalCarbs,
                    fat: totalFat,
                  ),
                ),
                ...MealType.values.map((mealType) {
                  final mealLogs =
                      logs.where((l) => l.mealType == mealType).toList();
                  return SliverToBoxAdapter(
                    child: _MealSection(
                      mealType: mealType,
                      logs: mealLogs,
                      onAdd: () => _openAddFood(member.id, mealType),
                      onDelete: (log) =>
                          _firestoreService.deleteNutritionLog(log.id),
                    ),
                  );
                }),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'nutrition_fab',
                onPressed: () => _openAddFood(member.id, null),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DateNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _DateNavigator({
    required this.selectedDate,
    required this.isToday,
    required this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
          ),
          Expanded(
            child: Center(
              child: Text(
                isToday
                    ? 'Bugün'
                    : DateFormat('d MMMM, EEEE', 'tr_TR').format(selectedDate),
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: onNext == null ? AppColors.cardBorder : null,
            ),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _MacrosSummaryCard extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const _MacrosSummaryCard({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${calories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'Toplam kalori',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MacroRow(
            label: 'Protein',
            value: protein,
            color: const Color(0xFF2979FF),
            maxValue: 150,
          ),
          const SizedBox(height: 8),
          _MacroRow(
            label: 'Karbonhidrat',
            value: carbs,
            color: const Color(0xFFFFAB00),
            maxValue: 250,
          ),
          const SizedBox(height: 8),
          _MacroRow(
            label: 'Yağ',
            value: fat,
            color: AppColors.error,
            maxValue: 80,
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final double maxValue;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.color,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / maxValue).clamp(0.0, 1.0),
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${value.toStringAsFixed(1)}g',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}

class _MealSection extends StatelessWidget {
  final MealType mealType;
  final List<NutritionLogModel> logs;
  final VoidCallback onAdd;
  final Future<void> Function(NutritionLogModel) onDelete;

  const _MealSection({
    required this.mealType,
    required this.logs,
    required this.onAdd,
    required this.onDelete,
  });

  double get _totalCalories => logs.fold(0.0, (s, l) => s + l.calories);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(mealType.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(
                  mealType.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const Spacer(),
                if (logs.isNotEmpty)
                  Text(
                    '${_totalCalories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (logs.isNotEmpty) ...[
            const Divider(height: 1),
            ...logs.map(
              (log) => Dismissible(
                key: ValueKey(log.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                ),
                onDismissed: (_) => onDelete(log),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.foodName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${log.amount.toStringAsFixed(0)}g  '
                              'P: ${log.protein.toStringAsFixed(1)}  '
                              'K: ${log.carbs.toStringAsFixed(1)}  '
                              'Y: ${log.fat.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${log.calories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
