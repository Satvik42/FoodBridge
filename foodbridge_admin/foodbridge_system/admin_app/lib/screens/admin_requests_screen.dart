import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../admin_theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../widgets/admin_widgets.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});
  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen>
    with SingleTickerProviderStateMixin {
  final _svc = FirebaseService();
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  String _tabFilter(int i) {
    switch (i) {
      case 1:  return 'pending';
      case 2:  return 'accepted';
      case 3:  return 'completed';
      default: return 'all';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.navy,
        title: Text('Requests Monitor', style: GoogleFonts.syne(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: AdminColors.navy,
            child: TabBar(
              controller: _tabs,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: Color(0xFF74C69D), width: 2.5),
                insets: EdgeInsets.symmetric(horizontal: 12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: GoogleFonts.syne(
                  fontSize: 11, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Pending'),
                Tab(text: 'Accepted'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<FoodRequest>>(
        stream: _svc.allRequestsStream(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
              child: CircularProgressIndicator(color: AdminColors.accent));

          final all = snap.data!;

          return TabBarView(
            controller: _tabs,
            children: List.generate(4, (i) {
              final filter = _tabFilter(i);
              final items  = filter == 'all'
                  ? all
                  : all.where((r) => r.status.name == filter).toList();

              if (items.isEmpty) return const AdminEmptyState(
                icon: Icons.inbox_outlined,
                title: 'Nothing here',
                subtitle: 'No requests in this category.',
              );

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: items.length,
                itemBuilder: (_, j) => _RequestCard(
                  request: items[j],
                  onForceAssign: () => _forceAssign(items[j]),
                  onForceComplete: () => _forceComplete(items[j]),
                  onDelete: () => _delete(items[j]),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Future<void> _forceAssign(FoodRequest req) async {
    // Fetch available volunteers
    final volunteers = await _svc.getAvailableVolunteers();
    if (!mounted) return;

    if (volunteers.isEmpty) {
      _snack('No available volunteers found.', AdminColors.amber);
      return;
    }

    // Show volunteer picker
    final picked = await showDialog<AppUser>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Assign Volunteer', style: GoogleFonts.syne(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AdminColors.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: volunteers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final v = volunteers[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AdminColors.accentL,
                  child: Text(v.name.isNotEmpty ? v.name[0].toUpperCase() : 'V',
                      style: GoogleFonts.syne(
                          color: AdminColors.accent,
                          fontWeight: FontWeight.w700)),
                ),
                title: Text(v.name, style: GoogleFonts.syne(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AdminColors.textPrimary)),
                subtitle: Text(v.isAvailable ? 'Available' : 'Busy',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: v.isAvailable
                            ? AdminColors.accent : AdminColors.coral)),
                onTap: () => Navigator.pop(ctx, v),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.syne(
                color: AdminColors.textMuted)),
          ),
        ],
      ),
    );

    if (picked == null || !mounted) return;

    final ok = await showAdminConfirmDialog(context,
      title: 'Force Assign?',
      body: 'Assign "${req.foodType}" to ${picked.name}?',
      confirmLabel: 'Assign',
      confirmColor: AdminColors.blue,
    );
    if (!ok || !mounted) return;
    await _svc.adminForceAssign(req.id, picked.uid, picked.name);
    _snack('Assigned to ${picked.name}', AdminColors.blue);
  }

  Future<void> _forceComplete(FoodRequest req) async {
    final ok = await showAdminConfirmDialog(context,
      title: 'Force Complete?',
      body: 'Mark this request as completed by admin override.',
      confirmLabel: 'Force Complete',
      confirmColor: AdminColors.blue,
    );
    if (!ok || !mounted) return;
    await _svc.adminForceComplete(req.id);
    _snack('Force completed', AdminColors.blue);
  }

  Future<void> _delete(FoodRequest req) async {
    final ok = await showAdminConfirmDialog(context,
      title: 'Delete Request?',
      body: 'Permanently delete the request for "${req.foodType}".',
    );
    if (!ok || !mounted) return;
    await _svc.deleteRequest(req.id);
    _snack('Request deleted', AdminColors.coral);
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ─── Request card with full lifecycle view ────────────────────────────────
class _RequestCard extends StatelessWidget {
  final FoodRequest request;
  final VoidCallback onForceAssign;
  final VoidCallback onForceComplete;
  final VoidCallback onDelete;

  const _RequestCard({
    required this.request,
    required this.onForceAssign,
    required this.onForceComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final mins = request.deliveryMinutes;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: request.priority == Priority.high
              ? AdminColors.coral.withOpacity(0.3)
              : AdminColors.border,
          width: request.priority == Priority.high ? 1 : 0.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ────────────────────────────────────────────────────
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: request.statusBg,
                borderRadius: BorderRadius.circular(8)),
            child: Icon(request.statusIcon, size: 18,
                color: request.statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.foodType, style: GoogleFonts.syne(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary)),
              Text('${request.location} · ${request.quantity}',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AdminColors.textMuted)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            AdminBadge(label: request.statusLabel,
                color: request.statusColor, bg: request.statusBg,
                icon: request.statusIcon),
            const SizedBox(height: 4),
            AdminBadge(label: request.priority.label,
                color: request.priority.color, bg: request.priority.bg,
                icon: Icons.flag_outlined),
          ]),
        ]),

        const SizedBox(height: 12),

        // ── Full lifecycle ────────────────────────────────────────────
        _LifecycleTimeline(request: request),
        const SizedBox(height: 10),

        // ── Meta ──────────────────────────────────────────────────────
        Wrap(spacing: 14, runSpacing: 6, children: [
          _chip(Icons.person_outline,
              'User: ${request.userId.length > 8 ? '${request.userId.substring(0, 8)}…' : request.userId}'),
          if (request.volunteerName != null)
            _chip(Icons.directions_bike_outlined,
                'Vol: ${request.volunteerName}'),
          if (request.suggestedVolunteerId != null)
            _chip(Icons.auto_awesome_outlined, 'Auto-matched'),
          if (request.matchConfidence > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AdminColors.accentL,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AdminColors.accent.withOpacity(0.3), width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.psychology_outlined, size: 10, color: AdminColors.accent),
                const SizedBox(width: 4),
                Text('${request.matchConfidence}% Confidence',
                    style: GoogleFonts.syne(
                        fontSize: 9, fontWeight: FontWeight.w800, color: AdminColors.accent)),
              ]),
            ),
          if (request.adminOverride)
            _chip(Icons.admin_panel_settings_outlined, 'Admin override'),
          if (mins != null)
            _chip(Icons.timer_outlined, '${mins}m delivery'),
        ]),

        const SizedBox(height: 12),

        // ── Admin actions ─────────────────────────────────────────────
        Row(children: [
          if (request.status == RequestStatus.pending)
            SuccessButton(
              label: 'Assign',
              icon: Icons.person_add_outlined,
              onTap: onForceAssign,
              color: AdminColors.blue,
              bg: AdminColors.blueL,
            ),
          if (request.status == RequestStatus.pending ||
              request.status == RequestStatus.accepted) ...[
            const SizedBox(width: 8),
            SuccessButton(
              label: 'Force Done',
              icon: Icons.task_alt_outlined,
              onTap: onForceComplete,
            ),
          ],
          const Spacer(),
          if (request.status != RequestStatus.completed)
            DangerButton(
              label: 'Delete',
              icon: Icons.delete_outline,
              onTap: onDelete,
            ),
        ]),
      ]),
    );
  }

  Widget _chip(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: AdminColors.textMuted),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.dmSans(
          fontSize: 11, color: AdminColors.textSecondary)),
    ],
  );
}

// ─── Lifecycle timeline for each request ─────────────────────────────────
class _LifecycleTimeline extends StatelessWidget {
  final FoodRequest request;
  const _LifecycleTimeline({required this.request});

  @override
  Widget build(BuildContext context) {
    final events = <_LifecycleEvent>[
      _LifecycleEvent(
        icon: Icons.add_circle_outline,
        label: 'Created',
        time: request.timestamp,
        color: AdminColors.accent,
        done: true,
      ),
      _LifecycleEvent(
        icon: Icons.check_circle_outline,
        label: 'Accepted',
        time: request.acceptedTime,
        color: AdminColors.blue,
        done: request.acceptedTime != null,
      ),
      _LifecycleEvent(
        icon: Icons.task_alt_outlined,
        label: 'Completed',
        time: request.completedTime,
        color: AdminColors.accent,
        done: request.completedTime != null,
      ),
    ];

    return Row(
      children: events.asMap().entries.map((e) {
        final ev = e.value;
        final isLast = e.key == events.length - 1;
        return Expanded(
          child: Row(children: [
            Column(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: ev.done ? ev.color : AdminColors.bg2,
                  shape: BoxShape.circle,
                ),
                child: Icon(ev.icon, size: 14,
                    color: ev.done ? Colors.white : AdminColors.textMuted),
              ),
              const SizedBox(height: 3),
              Text(ev.label, style: GoogleFonts.dmSans(
                  fontSize: 9, color: ev.done
                      ? AdminColors.textSecondary : AdminColors.textMuted)),
              if (ev.time != null)
                Text(DateFormat('h:mm a').format(ev.time!),
                    style: GoogleFonts.syne(
                        fontSize: 8, fontWeight: FontWeight.w700,
                        color: AdminColors.textPrimary)),
            ]),
            if (!isLast) Expanded(child: Container(
              height: 1.5,
              margin: const EdgeInsets.only(bottom: 16),
              color: ev.done ? ev.color.withOpacity(0.4) : AdminColors.divider,
            )),
          ]),
        );
      }).toList(),
    );
  }
}

class _LifecycleEvent {
  final IconData icon;
  final String label;
  final DateTime? time;
  final Color color;
  final bool done;
  const _LifecycleEvent({
    required this.icon, required this.label, required this.time,
    required this.color, required this.done,
  });
}
