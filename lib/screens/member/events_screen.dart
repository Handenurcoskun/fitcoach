import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class MemberEventsScreen extends StatelessWidget {
  const MemberEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser!;
    if (user.trainerId == null) {
      return const Center(child: Text('Bir eğitmene bağlı değilsiniz.'));
    }
    final firestoreService = FirestoreService();
    return StreamBuilder<List<EventModel>>(
      stream: firestoreService
          .watchUpcomingEventsForMember(user.trainerId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_outlined, size: 64, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text('Yaklaşan etkinlik yok',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, i) =>
              _MemberEventCard(event: events[i], userId: user.id),
        );
      },
    );
  }
}

class _MemberEventCard extends StatefulWidget {
  final EventModel event;
  final String userId;
  const _MemberEventCard({required this.event, required this.userId});

  @override
  State<_MemberEventCard> createState() => _MemberEventCardState();
}

class _MemberEventCardState extends State<_MemberEventCard> {
  bool _loading = false;
  final _svc = FirestoreService();

  Future<void> _toggle() async {
    setState(() => _loading = true);
    if (widget.event.isJoined(widget.userId)) {
      await _svc.leaveEvent(eventId: widget.event.id, userId: widget.userId);
    } else {
      await _svc.joinEvent(eventId: widget.event.id, userId: widget.userId);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final joined = widget.event.isJoined(widget.userId);
    final full = widget.event.isFull && !joined;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.event.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(DateFormat('d MMM y, HH:mm', 'tr').format(widget.event.dateTime),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(widget.event.location,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  widget.event.capacity > 0
                      ? '${widget.event.participants.length}/${widget.event.capacity} katılımcı'
                      : '${widget.event.participants.length} katılımcı',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _loading
                    ? const Center(child: SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                    : full
                        ? OutlinedButton(
                            onPressed: null,
                            child: const Text('Kontenjan Dolu'),
                          )
                        : ElevatedButton.icon(
                            onPressed: _toggle,
                            icon: Icon(joined ? Icons.check_circle : Icons.add_circle_outline,
                                size: 18),
                            label: Text(joined ? 'Katılacağım ✓' : 'Katılacağım'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: joined ? AppColors.success : AppColors.primary,
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(widget.event.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _Row(Icons.calendar_today_outlined,
                  DateFormat('d MMMM y, HH:mm', 'tr').format(widget.event.dateTime)),
              const SizedBox(height: 8),
              _Row(Icons.location_on_outlined, widget.event.location),
              const SizedBox(height: 8),
              _Row(Icons.people_outline,
                  widget.event.capacity > 0
                      ? '${widget.event.participants.length}/${widget.event.capacity} katılımcı'
                      : '${widget.event.participants.length} katılımcı'),
              if (widget.event.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Açıklama',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                Text(widget.event.description,
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Row(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
