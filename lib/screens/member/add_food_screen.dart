import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/nutrition_log_model.dart';
import '../../services/nutrition_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AddFoodScreen extends StatefulWidget {
  final String memberId;
  final String date;
  final MealType? presetMealType;

  const AddFoodScreen({
    super.key,
    required this.memberId,
    required this.date,
    this.presetMealType,
  });

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _nutritionService = NutritionService();
  final _firestoreService = FirestoreService();
  final _searchCtrl = TextEditingController();

  List<FoodSearchResult> _results = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _nutritionService.searchFood(query);
      if (mounted) {
        setState(() {
          // Yeni sonuç gelmediyse eski listeyi koru
          if (results.isNotEmpty) _results = results;
          _isSearching = false;
        });
      }
    });
  }

  void _showAddSheet(FoodSearchResult food) {
    // Eğer porsiyon tanımlıysa varsayılan "1 adet", yoksa "100g"
    final bool hasServing = food.servingGrams != null && food.servingLabel != null;
    bool useServing = hasServing;
    final servingCountCtrl = TextEditingController(text: '1');
    final gramCtrl = TextEditingController(
        text: hasServing ? food.servingGrams!.toStringAsFixed(0) : '100');
    MealType selectedMeal = widget.presetMealType ?? MealType.snack;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          double gramsForCalc;
          if (useServing && food.servingGrams != null) {
            final count = double.tryParse(servingCountCtrl.text) ?? 1;
            gramsForCalc = food.servingGrams! * count;
          } else {
            gramsForCalc = double.tryParse(gramCtrl.text) ?? 100;
          }
          final displayCal =
              (food.caloriesPer100g * gramsForCalc / 100).toStringAsFixed(0);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              24, 16, 24,
              MediaQuery.of(sheetCtx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (food.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          food.imageUrl!,
                          width: 56, height: 56, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    if (food.imageUrl != null) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(food.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          if (food.brand.isNotEmpty)
                            Text(food.brand,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '100g başına: ${food.caloriesPer100g.toStringAsFixed(0)} kcal  '
                  'P: ${food.proteinPer100g.toStringAsFixed(1)}g  '
                  'K: ${food.carbsPer100g.toStringAsFixed(1)}g  '
                  'Y: ${food.fatPer100g.toStringAsFixed(1)}g',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                // Adet / Gram toggle (sadece yerel yiyeceklerde porsiyon varsa)
                if (hasServing) ...[
                  Row(
                    children: [
                      _ModeBtn(
                        label: food.servingLabel!,
                        selected: useServing,
                        onTap: () => setSheetState(() => useServing = true),
                      ),
                      const SizedBox(width: 8),
                      _ModeBtn(
                        label: 'Gram (g)',
                        selected: !useServing,
                        onTap: () => setSheetState(() => useServing = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (useServing && hasServing)
                  TextField(
                    controller: servingCountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Adet / Porsiyon',
                      suffixText: food.servingLabel,
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  )
                else
                  TextField(
                    controller: gramCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Miktar',
                      suffixText: 'g',
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                const SizedBox(height: 16),
                const Text('Öğün',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: MealType.values.map((m) {
                    final isSelected = selectedMeal == m;
                    return ChoiceChip(
                      label: Text('${m.emoji} ${m.label}'),
                      selected: isSelected,
                      onSelected: (_) =>
                          setSheetState(() => selectedMeal = m),
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.cardBorder,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final grams = gramsForCalc;
                      if (grams <= 0) return;

                      final log = NutritionLogModel(
                        id: '',
                        memberId: widget.memberId,
                        date: widget.date,
                        mealType: selectedMeal,
                        foodName: food.name,
                        calories: food.caloriesPer100g * grams / 100,
                        protein: food.proteinPer100g * grams / 100,
                        carbs: food.carbsPer100g * grams / 100,
                        fat: food.fatPer100g * grams / 100,
                        amount: grams,
                        createdAt: DateTime.now(),
                      );

                      await _firestoreService.addNutritionLog(log);

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${food.name} eklendi'),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Text('Ekle ($displayCal kcal)'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Besin Ekle')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Ara... (ör: elma, tavuk, yoğurt)',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          if (_isSearching)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: AppColors.cardBorder,
            ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🍽️', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          _searchCtrl.text.isEmpty
                              ? 'Besin aramak için yukarıya yaz'
                              : _isSearching
                                  ? 'Aranıyor...'
                                  : 'Sonuç bulunamadı',
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final r = _results[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: SizedBox(
                            width: 48,
                            height: 48,
                            child: r.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      r.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _FoodIcon(r.name),
                                    ),
                                  )
                                : _FoodIcon(r.name),
                          ),
                          title: Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: r.brand.isNotEmpty
                              ? Text(
                                  r.brand,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                )
                              : null,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${r.caloriesPer100g.toStringAsFixed(0)} kcal',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const Text(
                                '/100g',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11),
                              ),
                            ],
                          ),
                          onTap: () => _showAddSheet(r),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeBtn(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _FoodIcon extends StatelessWidget {
  final String name;
  const _FoodIcon(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
