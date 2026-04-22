import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';

// ─── Volunteer main screen ────────────────────────────────────────────────
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
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildVolunteerBanner()),
          SliverToBoxAdapter(child: _buildTabBar()),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _AvailableTasksTab(svc: _svc),
            const VolunteerCompletedScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.primary,
      title: Text('Volunteer Hub', style: GoogleFonts.syne(
          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_outlined, color: Colors.white),
          onPressed: () => setState(() {}),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _showProfileSheet(context, context.read<AppState>()),
            child: Consumer<AppState>(
              builder: (_, appState, __) => AvatarCircle(
                initials: appState.userName.isNotEmpty
                    ? appState.userName[0].toUpperCase() : 'V',
                bg: Colors.white.withOpacity(0.2),
                fg: Colors.white, size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVolunteerBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primary2],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("You're a Volunteer 🙌", style: GoogleFonts.syne(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 6),
            Text('Tasks are sorted by priority. ⭐ = suggested for you based on your location.',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: Colors.white70, height: 1.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Tap a task to accept it',
                  style: GoogleFonts.syne(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ],
        )),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: const Text('🚴', style: TextStyle(fontSize: 32)),
        ),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg2, borderRadius: BorderRadius.circular(8)),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(3),
          dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w600),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Available Tasks'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Row(children: [
            AvatarCircle(
              initials: appState.userName[0].toUpperCase(),
              bg: AppColors.primary, fg: Colors.white, size: 50,
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appState.userName, style: GoogleFonts.syne(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              Text(appState.isVolunteer ? 'Volunteer' : 'Food Recipient',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textMuted)),
            ]),
          ]),
          const SizedBox(height: 24),
          const AppDivider(),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
            title: Text(
              appState.isVolunteer ? 'Switch to User Mode' : 'Switch to Volunteer Mode',
              style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
            contentPadding: EdgeInsets.zero,
            onTap: () async {
              final newRole = appState.isVolunteer ? UserRole.user : UserRole.volunteer;
              await AuthService().updateUserRole(appState.userId, newRole);
              appState.setRole(newRole);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.coral),
            title: Text('Sign Out', style: GoogleFonts.syne(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
            contentPadding: EdgeInsets.zero,
            onTap: () async {
              await AuthService().signOut();
              appState.clearUser();
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ]),
      ),
    );
  }
}

// ─── Available tasks tab ──────────────────────────────────────────────────
class _AvailableTasksTab extends StatelessWidget {
  final FirebaseService svc;
  const _AvailableTasksTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    final currentUid = svc.currentUserId;

    return StreamBuilder<List<FoodRequest>>(
      stream: svc.activeTasksStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load tasks',
            subtitle: snapshot.error.toString(),
          );
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const EmptyState(
            icon: Icons.task_outlined,
            title: 'No pending tasks',
            subtitle: 'New tasks appear here when users request food.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: requests.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TaskCard(
              request: requests[i],
              isSuggestedForMe: requests[i].suggestedVolunteerId == currentUid,
              onAccept: () => _handleAccept(context, requests[i]),
            ),
          ),
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
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ─── Completed tasks screen ───────────────────────────────────────────────
class VolunteerCompletedScreen extends StatefulWidget {
  const VolunteerCompletedScreen({super.key});
  @override
  State<VolunteerCompletedScreen> createState() => _VolunteerCompletedScreenState();
}

class _VolunteerCompletedScreenState extends State<VolunteerCompletedScreen> {
  final _svc = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FoodRequest>>(
      stream: _svc.completedRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final completed = snapshot.data ?? [];
        if (completed.isEmpty) {
          return const EmptyState(
            icon: Icons.task_alt_outlined,
            title: 'No completed tasks yet',
            subtitle: 'Accept a task and mark it done — it will appear here.',
          );
        }

        // Compute total delivery time for personal stats
        final timed = completed.where((r) =>
            r.acceptedTime != null && r.completedTime != null).toList();
        final avgMins = timed.isEmpty ? 0.0 :
            timed.fold<int>(0, (s, r) =>
                s + r.completedTime!.difference(r.acceptedTime!).inMinutes) /
            timed.length;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: completed.length + 1,
          itemBuilder: (_, i) {
            // Personal stats header
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
                      Text('Total Done', style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textMuted)),
                    ])),
                    Container(width: 1, height: 40, color: AppColors.divider),
                    Expanded(child: Column(children: [
                      Text(timed.isEmpty ? '—' : '${avgMins.toStringAsFixed(0)}m',
                          style: GoogleFonts.syne(
                              fontSize: 22, fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      Text('Avg Delivery', style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textMuted)),
                    ])),
                  ]),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CompletedTaskCard(request: completed[i - 1]),
            );
          },
        );
      },
    );
  }
}

// ─── Task card — with priority badge + suggested highlight ────────────────
class _TaskCard extends StatefulWidget {
  final FoodRequest request;
  final bool isSuggestedForMe;
  final VoidCallback onAccept;

  const _TaskCard({
    required this.request,
    required this.isSuggestedForMe,
    required this.onAccept,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  final _svc       = FirebaseService();
  bool _accepting  = false;
  bool _completing = false;
  bool _accepted   = false;

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final priority = req.priority;
    final isSuggested = widget.isSuggestedForMe;

    return Container(
      decoration: BoxDecoration(
        color: _accepted
            ? AppColors.primaryXL
            : isSuggested
                ? AppColors.primaryXL
                : AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuggested
              ? AppColors.primary2.withOpacity(0.6)
              : AppColors.border,
          width: isSuggested ? 1.5 : 0.5,
        ),
        boxShadow: isSuggested
            ? [BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────
          Row(children: [
            Text('🚚', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (isSuggested) ...[
                    const Text('⭐ ', style: TextStyle(fontSize: 13)),
                  ],
                  Expanded(
                    child: Text(req.foodType, style: GoogleFonts.syne(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                  ),
                ]),
                Text(req.quantity, style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textMuted)),
              ],
            )),
              // Priority badge
              StatusBadge(
                label: priority.label,
                color: priority.color,
                bg: priority.bg,
              ),
              const SizedBox(height: 4),
              // Time age
              Text(_ageMinutes(req.timestamp),
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: AppColors.textMuted)),
            ]),
          ]),

          if (isSuggested) ...[
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryL,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('⭐ Best Match',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Confidence: 95%',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.primary)),
              ),
            ]),
          ],

          const SizedBox(height: 14),
          const AppDivider(),
          const SizedBox(height: 12),

          // Route
          _routeRow(Icons.trip_origin, 'Pickup', req.location,
              AppColors.primary, AppColors.primaryL),
          Container(
              margin: const EdgeInsets.only(left: 11),
              width: 1.5, height: 16, color: AppColors.divider),
          _routeRow(Icons.location_on, 'Deliver to', 'Requester Location',
              AppColors.coral, AppColors.coralL),

          const SizedBox(height: 14),

          // Action buttons
          _accepted
              ? Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Navigate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _completing ? null : _handleComplete,
                      icon: _completing
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.task_alt_outlined, size: 16),
                      label: Text(_completing ? 'Saving…' : 'Mark Done'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary2,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ]),
              if (_accepted) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleMarkExpired(context),
                    icon: const Icon(Icons.warning_amber_rounded, size: 16),
                    label: const Text('Report as Expired / Spoiled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.coral,
                      side: const BorderSide(color: AppColors.coral),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
              if (!_accepted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _accepting ? null : _handleAccept,
                    icon: _accepting
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(_accepting ? 'Accepting…' : 'Accept Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
        ],
      ),
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
        content: Text('🎉 Task completed! Great work!',
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

  Future<void> _handleMarkExpired(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text('Report Expired?', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        content: Text('Mark this food as expired or spoiled? It will be redirected for waste management.',
            style: GoogleFonts.dmSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true),
              child: const Text('Yes, Report', style: TextStyle(color: AppColors.coral))),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _svc.markExpiredAndCancelRequest(widget.request.foodId, widget.request.id);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Food reported as expired. Admin notified.',
            style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppColors.coral, behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppColors.coral, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  String _ageMinutes(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _routeRow(IconData icon, String label, String value,
      Color color, Color bg) {
    return Row(children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 12, color: color),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.dmSans(
            fontSize: 10, color: AppColors.textMuted)),
        Text(value, style: GoogleFonts.syne(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis),
      ]),
    ]);
  }
}

// ─── Completed task card with delivery time ───────────────────────────────
class _CompletedTaskCard extends StatelessWidget {
  final FoodRequest request;
  const _CompletedTaskCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final mins = request.deliveryMinutes;
    return AppCard(
      color: AppColors.primaryXL,
      child: Row(children: [
        const Text('✅', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.foodType, style: GoogleFonts.syne(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text(request.location, style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(request.quantity, style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textSecondary)),
          ],
        )),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          StatusBadge(
            label: 'Done',
            color: AppColors.primary, bg: AppColors.primaryL,
            icon: Icons.check_circle_outline,
          ),
          if (mins != null) ...[
            const SizedBox(height: 4),
            Text('${mins}m', style: GoogleFonts.syne(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.textMuted)),
          ],
        ]),
      ]),
    );
  }
}
