import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/measurement_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class MeasurementsScreen extends StatelessWidget {
  final UserModel member;
  final bool canAdd; // true for trainer, false for member viewing own

  const MeasurementsScreen({
    super.key,
    required this.member,
    this.canAdd = true,
  });

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: Text('${member.name} – Ölçümler')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context, service),
              icon: const Icon(Icons.add),
              label: const Text('Ölçüm Ekle'),
            )
          : null,
      body: StreamBuilder<List<MeasurementModel>>(
        stream: service.watchMeasurementsForMember(member.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monitor_weight_outlined,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('Henüz ölçüm yok',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    canAdd ? 'İlk ölçümü eklemek için + butonuna bas.' : 'Eğitmenin ölçüm eklediğinde burada görünür.',
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCards(list: list),
              const SizedBox(height: 20),
              const Text('Geçmiş Ölçümler',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...list.map((m) => _MeasurementCard(
                    measurement: m,
                    onDelete: canAdd ? () => service.deleteMeasurement(m.id) : null,
                  )),
            ],
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext context, FirestoreService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddMeasurementSheet(memberId: member.id, service: service),
    );
  }
}

// ─── Summary Cards ────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final List<MeasurementModel> list;
  const _SummaryCards({required this.list});

  @override
  Widget build(BuildContext context) {
    final latest = list.first;
    final oldest = list.last;
    final weightDiff = list.length > 1 ? latest.weightKg - oldest.weightKg : null;
    final fatDiff = (list.length > 1 && latest.bodyFatPercent != null && oldest.bodyFatPercent != null)
        ? latest.bodyFatPercent! - oldest.bodyFatPercent!
        : null;

    return Row(
      children: [
        _SummaryTile(
          label: 'Son Ağırlık',
          value: '${latest.weightKg.toStringAsFixed(1)} kg',
          sub: weightDiff != null
              ? '${weightDiff >= 0 ? '+' : ''}${weightDiff.toStringAsFixed(1)} kg'
              : null,
          subColor: weightDiff != null ? (weightDiff <= 0 ? AppColors.primary : AppColors.error) : null,
        ),
        const SizedBox(width: 12),
        _SummaryTile(
          label: 'Vücut Yağı',
          value: latest.bodyFatPercent != null
              ? '%${latest.bodyFatPercent!.toStringAsFixed(1)}'
              : '—',
          sub: fatDiff != null
              ? '${fatDiff >= 0 ? '+' : ''}${fatDiff.toStringAsFixed(1)}%'
              : null,
          subColor: fatDiff != null ? (fatDiff <= 0 ? AppColors.primary : AppColors.error) : null,
        ),
        const SizedBox(width: 12),
        _SummaryTile(
          label: 'Ölçüm Sayısı',
          value: '${list.length}',
          sub: DateFormat('d MMM', 'tr_TR').format(oldest.date),
          subColor: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? subColor;
  const _SummaryTile({required this.label, required this.value, this.sub, this.subColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub!, style: TextStyle(fontSize: 11, color: subColor ?? AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Measurement Card ─────────────────────────────────────────────────────────

class _MeasurementCard extends StatelessWidget {
  final MeasurementModel measurement;
  final VoidCallback? onDelete;
  const _MeasurementCard({required this.measurement, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final m = measurement;
    final fat = m.bodyFatPercent;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(DateFormat('d MMMM yyyy', 'tr_TR').format(m.date),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (fat != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('%${fat.toStringAsFixed(1)} yağ',
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmDelete(context),
                    child: const Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _Chip('Ağırlık', '${m.weightKg} kg'),
                _Chip('Boy', '${m.heightCm} cm'),
                _Chip('Boyun', '${m.neckCm} cm'),
                _Chip('Bel', '${m.waistCm} cm'),
                if (m.hipCm != null) _Chip('Kalça', '${m.hipCm} cm'),
              ],
            ),
            if (m.note != null && m.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(m.note!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
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
        title: const Text('Ölçümü Sil'),
        content: const Text('Bu ölçümü silmek istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () { Navigator.pop(context); onDelete!(); },
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  const _Chip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            TextSpan(text: value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─── Add Measurement Sheet ────────────────────────────────────────────────────

class _AddMeasurementSheet extends StatefulWidget {
  final String memberId;
  final FirestoreService service;
  const _AddMeasurementSheet({required this.memberId, required this.service});

  @override
  State<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  String _gender = 'E';
  bool _isLoading = false;

  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _neckCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose(); _heightCtrl.dispose(); _neckCtrl.dispose();
    _waistCtrl.dispose(); _hipCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  double? get _previewFat {
    final w = double.tryParse(_waistCtrl.text);
    final n = double.tryParse(_neckCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    final hip = double.tryParse(_hipCtrl.text);
    if (w == null || n == null || h == null || h <= 0) return null;
    try {
      if (_gender == 'K') {
        if (hip == null || hip <= 0 || w + hip - n <= 0) return null;
        return (163.205 * log(w + hip - n) / ln10 - 97.684 * log(h) / ln10 - 78.387).clamp(1.0, 60.0);
      } else {
        if (w - n <= 0) return null;
        return (86.010 * log(w - n) / ln10 - 70.041 * log(h) / ln10 + 36.76).clamp(1.0, 60.0);
      }
    } catch (_) { return null; }
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    final neck = double.tryParse(_neckCtrl.text);
    final waist = double.tryParse(_waistCtrl.text);
    final hip = double.tryParse(_hipCtrl.text);

    if (weight == null || height == null || neck == null || waist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ağırlık, boy, boyun ve bel zorunlu.')));
      return;
    }
    if (_gender == 'K' && hip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kadın için kalça ölçüsü gerekli.')));
      return;
    }

    setState(() => _isLoading = true);
    final m = MeasurementModel(
      id: '',
      memberId: widget.memberId,
      date: DateTime.now(),
      gender: _gender,
      weightKg: weight,
      heightCm: height,
      neckCm: neck,
      waistCm: waist,
      hipCm: hip,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    await widget.service.addMeasurement(m);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewFat;
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Ölçüm Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            // Gender selector
            Row(
              children: [
                _GenderBtn(label: 'Erkek', value: 'E', selected: _gender == 'E',
                    onTap: () => setState(() => _gender = 'E')),
                const SizedBox(width: 12),
                _GenderBtn(label: 'Kadın', value: 'K', selected: _gender == 'K',
                    onTap: () => setState(() => _gender = 'K')),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _NumField(ctrl: _waistCtrl, label: 'Bel (cm)', onChanged: (_) => setState(() {}))),
              const SizedBox(width: 12),
              Expanded(child: _NumField(ctrl: _neckCtrl, label: 'Boyun (cm)', onChanged: (_) => setState(() {}))),
            ]),
            const SizedBox(height: 12),
            if (_gender == 'K') ...[
              _NumField(ctrl: _hipCtrl, label: 'Kalça (cm)', onChanged: (_) => setState(() {})),
              const SizedBox(height: 12),
            ],
            Row(children: [
              Expanded(child: _NumField(ctrl: _weightCtrl, label: 'Ağırlık (kg)')),
              const SizedBox(width: 12),
              Expanded(child: _NumField(ctrl: _heightCtrl, label: 'Boy (cm)', onChanged: (_) => setState(() {}))),
            ]),
            const SizedBox(height: 12),
            _NumField(ctrl: _noteCtrl, label: 'Not (isteğe bağlı)', isNumber: false),
            if (preview != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text('Tahmini Vücut Yağı: %${preview.toStringAsFixed(1)}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderBtn extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _GenderBtn({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.primary : AppColors.cardBorder, width: selected ? 2 : 1),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
          ),
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool isNumber;
  final ValueChanged<String>? onChanged;
  const _NumField({required this.ctrl, required this.label, this.isNumber = true, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}
