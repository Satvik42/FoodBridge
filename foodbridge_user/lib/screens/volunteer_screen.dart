import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';

// ─── Volunteer Screen ─────────────────────────────────────────────────────
class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({super.key});
  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen>
    with SingleTickerProviderStateMixin {
  final _svc = FirebaseService();
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildBanner()),
          SliverToBoxAdapter(child: _buildTabBar()),
        ],
        body: TabBarView(controller: _tabCtrl, children: [
          _TasksTab(svc: _svc),
          const VolunteerCompletedScreen(),
        ]),
      ),
    );
  }

  Widget _buildAppBar() => SliverAppBar(
    pinned: true,
    backgroundColor: AppColors.primary,
    title: Text('Volunteer Hub', style: GoogleFonts.syne(
        fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
    actions: [
      IconButton(icon: const Icon(Icons.refresh_outlined, color: Colors.white),
          onPressed: () => setState(() {})),
      const SizedBox(width: 4),
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: () => _showProfileSheet(context, context.read<AppState>()),
          child: Consumer<AppState>(
            builder: (_, s, __) => AvatarCircle(
              initials: s.userName.isNotEmpty ? s.userName[0].toUpperCase() : 'V',
              bg: Colors.white.withOpacity(0.2), fg: Colors.white, size: 32,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildBanner() => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primary2],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("You're a Volunteer 🙌", style: GoogleFonts.syne(
            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 6),
        Text('AI handles 90% of assignments. ⭐ = auto-matched to you.',
            style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white70, height: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8)),
          child: Text('Tasks sorted by AI priority',
              style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ])),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle),
        child: const Text('🚴', style: TextStyle(fontSize: 32)),
      ),
    ]),
  );

  Widget _buildTabBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Container(
      decoration: BoxDecoration(color: AppColors.bg2,
          borderRadius: BorderRadius.circular(8)),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(color: AppColors.primary,
            borderRadius: BorderRadius.circular(6)),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3),
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w600),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        tabs: const [Tab(text: 'Active Tasks'), Tab(text: 'Completed')],
      ),
    ),
  );

  void _showProfileSheet(BuildContext ctx, AppState appState) {
    showModalBottomSheet(
      context: ctx, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(children: [
            AvatarCircle(initials: appState.userName[0].toUpperCase(),
                bg: AppColors.primary, fg: Colors.white, size: 50),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appState.userName, style: GoogleFonts.syne(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              Text('Volunteer', style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted)),
            ]),
          ]),
          const SizedBox(height: 24),
          const AppDivider(),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.coral),
            title: Text('Sign Out', style: GoogleFonts.syne(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
            contentPadding: EdgeInsets.zero,
            onTap: () async {
              await AuthService().signOut();
              appState.clearUser();
              if (c.mounted) Navigator.pop(c);
            },
          ),
        ]),
      ),
    );
  }
}

// ─── Tasks tab ────────────────────────────────────────────────────────────
class _TasksTab extends StatelessWidget {
  final FirebaseService svc;
  const _TasksTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    final uid = svc.currentUserId;
    return StreamBuilder<List<FoodRequest>>(
      stream: svc.activeTasksStream(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return const EmptyState(icon: Icons.task_outlined,
              title: 'No active tasks',
              subtitle: 'AI will auto-assign tasks as food requests come in.');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final r = requests[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SmartTaskCard(
                request: r,
                isAutoAssigned: r.assignedVolunteerId == uid,
                isSuggested: r.suggestedVolunteerId == uid && r.assignedVolunteerId == null,
                onAccept: () => _handleAccept(ctx, r),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleAccept(BuildContext ctx, FoodRequest req) async {
    try {
      await svc.acceptTask(req.id);
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Task accepted! Head to ${req.location}',
            style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppColors.coral, behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ─── Smart Task Card — AI-driven action display ───────────────────────────
class _SmartTaskCard extends StatefulWidget {
  final FoodRequest request;
  final bool isAutoAssigned;   // AI already assigned this to me
  final bool isSuggested;      // AI suggests me, waiting for confirm
  final VoidCallback onAccept;

  const _SmartTaskCard({
    required this.request,
    required this.isAutoAssigned,
    required this.isSuggested,
    required this.onAccept,
  });

  @override
  State<_SmartTaskCard> createState() => _SmartTaskCardState();
}

class _SmartTaskCardState extends State<_SmartTaskCard> {
  final _svc       = FirebaseService();
  bool _accepting  = false;
  bool _completing = false;
  bool _accepted   = false;

  bool get _showMarkDone =>
      _accepted ||
      widget.isAutoAssigned ||
      widget.request.status == RequestStatus.accepted;

  @override
  Widget build(BuildContext context) {
    final req   = widget.request;
    final prio  = req.priority;

    // Card border highlights
    Color? borderColor;
    if (widget.isAutoAssigned) borderColor = AppColors.primary2;
    else if (widget.isSuggested) borderColor = AppColors.amberMid;

    return Container(
      decoration: BoxDecoration(
        color: widget.isAutoAssigned
            ? AppColors.primaryXL
            : AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: borderColor != null ? 1.5 : 0.5,
        ),
        boxShadow: widget.isAutoAssigned ? [
          BoxShadow(color: AppColors.primary.withOpacity(0.08),
              blurRadius: 12, offset: const Offset(0, 4)),
        ] : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── AI Action Banner (replaces manual buttons for auto-assigned) ──
        if (widget.isAutoAssigned) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(
                '🤖 AI assigned this to you — ready for pickup',
                style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Colors.white),
              )),
            ]),
          ),
          const SizedBox(height: 10),
        ] else if (widget.isSuggested) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.amberL,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.amberMid.withOpacity(0.4))),
            child: Row(children: [
              const Text('⭐ ', style: TextStyle(fontSize: 13)),
              Expanded(child: Text('AI recommends this for you',
                  style: GoogleFonts.dmSans(fontSize: 11,
                      color: AppColors.amber, fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 10),
        ],

        // ── Header ────────────────────────────────────────────────────
        Row(children: [
          Text('🚚', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(req.foodType, style: GoogleFonts.syne(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
            Text(req.quantity, style: GoogleFonts.dmSans(
                fontSize: 12, color: AppColors.textMuted)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusBadge(label: prio.label, color: prio.color, bg: prio.bg),
            const SizedBox(height: 4),
            Text('${_ageStr(req.timestamp)} ago', style: GoogleFonts.dmSans(
                fontSize: 10, color: AppColors.textMuted)),
          ]),
        ]),

        const SizedBox(height: 14),
        const AppDivider(),
        const SizedBox(height: 12),

        // ── Route ─────────────────────────────────────────────────────
        _routeRow(Icons.trip_origin, 'Pickup', req.location,
            AppColors.primary, AppColors.primaryL),
        Container(margin: const EdgeInsets.only(left: 11),
            width: 1.5, height: 16, color: AppColors.divider),
        _routeRow(Icons.location_on, 'Deliver to', 'Requester Location',
            AppColors.coral, AppColors.coralL),

        const SizedBox(height: 14),

        // ── Action area ───────────────────────────────────────────────
        _showMarkDone
            ? Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Navigate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  onPressed: _completing ? null : _handleComplete,
                  icon: _completing
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.task_alt_outlined, size: 16),
                  label: Text(_completing ? 'Saving…' : 'Mark Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary2, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )),
              ])
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _accepting ? null : _handleAccept,
                  icon: _accepting
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(_accepting ? 'Accepting…' : 'Accept Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
      ]),
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _accepting = true);
    try {
      await _svc.acceptTask(widget.request.id);
      if (!mounted) return;
      setState(() { _accepting = false; _accepted = true; });
      widget.onAccept();
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppColors.coral, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _handleComplete() async {
    setState(() => _completing = true);
    try {
      await _svc.completeTask(widget.request.id);
      if (!mounted) return;
      setState(() => _completing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🎉 Task completed!',
            style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppColors.primary2, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _completing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppColors.coral, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  String _ageStr(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    return '${d.inHours}h';
  }

  Widget _routeRow(IconData icon, String label, String value, Color c, Color bg) =>
    Row(children: [
      Container(width: 24, height: 24,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: c)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
        Text(value, style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
      ]),
    ]);
}

// ─── Completed screen with performance stats ──────────────────────────────
class VolunteerCompletedScreen extends StatefulWidget {
  const VolunteerCompletedScreen({super.key});
  @override
  State<VolunteerCompletedScreen> createState() => _VCSState();
}

class _VCSState extends State<VolunteerCompletedScreen> {
  final _svc = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FoodRequest>>(
      stream: _svc.completedRequestsStream(),
      builder: (_, snap) {
        final completed = snap.data ?? [];
        if (completed.isEmpty) {
          return const EmptyState(icon: Icons.task_alt_outlined,
              title: 'No completed tasks yet',
              subtitle: 'AI-assigned tasks will appear here once delivered.');
        }
        final timed = completed.where((r) =>
            r.acceptedTime != null && r.completedTime != null).toList();
        final avgMins = timed.isEmpty ? 0.0 :
            timed.fold<int>(0, (s, r) =>
                s + r.completedTime!.difference(r.acceptedTime!).inMinutes) /
            timed.length;
        final autoCount = completed.where((r) => r.assignedVolunteerId != null).length;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: completed.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryXL,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary3.withOpacity(0.3), width: 0.5),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(children: [
                      Text('${completed.length}', style: GoogleFonts.syne(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                      Text('Done', style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textMuted)),
                    ])),
                    Container(width: 1, height: 40, color: AppColors.divider),
                    Expanded(child: Column(children: [
                      Text(timed.isEmpty ? '—' : '${avgMins.toStringAsFixed(0)}m',
                          style: GoogleFonts.syne(fontSize: 22,
                              fontWeight: FontWeight.w700, color: AppColors.primary)),
                      Text('Avg Delivery', style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textMuted)),
                    ])),
                    Container(width: 1, height: 40, color: AppColors.divider),
                    Expanded(child: Column(children: [
                      Text('$autoCount', style: GoogleFonts.syne(fontSize: 22,
                          fontWeight: FontWeight.w700, color: AppColors.blue)),
                      Text('Auto-assigned', style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textMuted)),
                    ])),
                  ]),
                ),
              );
            }
            final r = completed[i - 1];
            final mins = r.deliveryMinutes;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                color: AppColors.primaryXL,
                child: Row(children: [
                  const Text('✅', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.foodType, style: GoogleFonts.syne(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                    Text(r.location, style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (r.assignedVolunteerId != null)
                      Row(children: [
                        const Icon(Icons.auto_awesome, size: 10, color: AppColors.blue),
                        const SizedBox(width: 4),
                        Text('AI assigned', style: GoogleFonts.dmSans(
                            fontSize: 10, color: AppColors.blue)),
                      ]),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    StatusBadge(label: 'Done', color: AppColors.primary,
                        bg: AppColors.primaryL, icon: Icons.check_circle_outline),
                    if (mins != null) ...[
                      const SizedBox(height: 4),
                      Text('${mins}m', style: GoogleFonts.syne(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.textMuted)),
                    ],
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}
