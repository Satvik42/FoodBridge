import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../admin_theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/app_state.dart';
import '../widgets/admin_widgets.dart';
import 'admin_waste_resource_screen.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _svc = FirebaseService();
  bool _sweeping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: StreamBuilder<AdminStats>(
              stream: _svc.adminStatsStream(),
              builder: (_, snap) {
                final s = snap.data ?? const AdminStats();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(children: [

                    // ── AI Insights panel ──────────────────────────────
                    if (s.aiInsights.isNotEmpty) ...[
                      _AiInsightsPanel(insights: s.aiInsights),
                      const SizedBox(height: 16),
                    ],

                    // ── Core stats ─────────────────────────────────────
                    Row(children: [
                      Expanded(child: AdminStatCard(
                        value: '${s.foodSavedCount}', label: 'Food Items Saved',
                        icon: Icons.eco_outlined,
                        color: AdminColors.accent, bg: AdminColors.accentL,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: AdminStatCard(
                        value: '${s.wasteRedirectedCount}', label: 'Waste Redirected',
                        icon: Icons.recycling_outlined,
                        color: AdminColors.purple, bg: AdminColors.purpleL,
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: AdminStatCard(
                        value: '${s.activeRequests}', label: 'Active Requests',
                        icon: Icons.pending_outlined,
                        color: AdminColors.amber, bg: AdminColors.amberL,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: AdminStatCard(
                        value: s.avgDeliveryMinutes > 0
                            ? '${s.avgDeliveryMinutes.toStringAsFixed(0)}m'
                            : '—',
                        label: 'Avg Delivery',
                        icon: Icons.timer_outlined,
                        color: AdminColors.blue, bg: AdminColors.blueL,
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: AdminStatCard(
                        value: '${s.activeVolunteers}', label: 'Active Volunteers',
                        icon: Icons.directions_bike_outlined,
                        color: AdminColors.accent, bg: AdminColors.accentL,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: AdminStatCard(
                        value: '${s.autoAssignedCount}',
                        label: 'AI Auto-Assigned',
                        icon: Icons.auto_awesome_outlined,
                        color: AdminColors.blue, bg: AdminColors.blueL,
                        delta: '${s.manualAssignedCount} manual',
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: AdminStatCard(
                        value: '${s.expiredItems}', label: 'Expired Items',
                        icon: Icons.warning_amber_outlined,
                        color: AdminColors.coral, bg: AdminColors.coralL,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: AdminStatCard(
                        value: '${s.pendingUserReports}', label: 'Pending Reports',
                        icon: Icons.flag_outlined,
                        color: AdminColors.coral, bg: AdminColors.coralL,
                      )),
                    ]),

                    // ── Auto sweep button ──────────────────────────────
                    const SizedBox(height: 16),
                    _AutoSweepCard(
                      sweeping: _sweeping,
                      onSweep: () => _runSweep(context),
                    ),

                    // ── Waste to Resource Nav ───────────────────────────
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminWasteResourceScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AdminColors.purple.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminColors.purple.withOpacity(0.15), width: 0.5),
                        ),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: AdminColors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.recycling_outlined, size: 18, color: AdminColors.purple),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Waste to Resource Management', style: GoogleFonts.syne(
                                fontSize: 13, fontWeight: FontWeight.w700, color: AdminColors.textPrimary)),
                            Text('Divert food waste to compost, biogas, or feed',
                                style: GoogleFonts.dmSans(fontSize: 11, color: AdminColors.textMuted)),
                          ])),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AdminColors.textMuted),
                        ]),
                      ),
                    ),

                    // ── Requests by area ───────────────────────────────
                    if (s.requestsByArea.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _AreaBreakdown(byArea: s.requestsByArea),
                    ],

                    // ── Volunteer performance ──────────────────────────
                    if (s.volunteerPerformance.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _VolunteerLeaderboard(perfs: s.volunteerPerformance),
                    ],
                  ]),
                );
              },
            ),
          ),

          // ── Live feed ─────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: AdminSectionHeader(
              title: 'Live Activity Feed',
              subtitle: 'Real-time AI-processed updates',
            ),
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<List<FoodRequest>>(
              stream: _svc.allRequestsStream(),
              builder: (_, snap) {
                if (!snap.hasData) return const Padding(
                  padding: EdgeInsets.all(16), child: AdminLoadingCard());
                final items = snap.data!.take(8).toList();
                if (items.isEmpty) return const Padding(
                  padding: EdgeInsets.all(16),
                  child: AdminEmptyState(icon: Icons.feed_outlined,
                      title: 'No activity yet',
                      subtitle: 'AI-processed actions appear here in real time.'));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: items.map((r) => _ActivityTile(request: r)).toList()),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) => SliverAppBar(
    pinned: true,
    backgroundColor: AdminColors.navy,
    title: Row(children: [
      Text('Food', style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
      Text('Bridge', style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF74C69D))),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(5)),
        child: Text('AI Admin', style: GoogleFonts.syne(
            fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600)),
      ),
    ]),
    actions: [
      Container(margin: const EdgeInsets.only(right: 4),
          child: Row(children: [
            Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('Live', style: GoogleFonts.syne(fontSize: 11, color: Colors.white70)),
          ])),
      IconButton(
        icon: const Icon(Icons.logout_outlined, color: Colors.white70, size: 20),
        onPressed: () => context.read<AppState>().clearUser(),
      ),
    ],
  );

  Future<void> _runSweep(BuildContext ctx) async {
    setState(() => _sweeping = true);
    final result = await _svc.runAutoMaintenanceSweep();
    setState(() => _sweeping = false);
    if (!ctx.mounted) return;
    final msg = 'Sweep complete: ${result['expired']} expired, '
        '${result['redirected']} redirected, ${result['cancelled']} cancelled.';
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(fontSize: 13)),
      backgroundColor: AdminColors.accent, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ─── AI Insights panel ────────────────────────────────────────────────────
class _AiInsightsPanel extends StatelessWidget {
  final List<AiInsight> insights;
  const _AiInsightsPanel({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            const Icon(Icons.auto_awesome, size: 16, color: AdminColors.navy),
            const SizedBox(width: 8),
            Text('AI Insights', style: GoogleFonts.syne(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AdminColors.textPrimary)),
            const Spacer(),
            Text('${insights.length} active', style: GoogleFonts.dmSans(
                fontSize: 11, color: AdminColors.textMuted)),
          ]),
        ),
        const Divider(height: 1, color: AdminColors.divider),
        ...insights.map((ins) => _InsightTile(insight: ins)),
      ]),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final AiInsight insight;
  const _InsightTile({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.divider, width: 0.5))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: insight.bg,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(insight.icon, size: 16, color: insight.color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(insight.message, style: GoogleFonts.dmSans(
              fontSize: 12, color: AdminColors.textSecondary, height: 1.4)),
          if (insight.actionLabel != null) ...[
            const SizedBox(height: 6),
            Text(insight.actionLabel!, style: GoogleFonts.syne(
                fontSize: 10, fontWeight: FontWeight.w700, color: insight.color)),
          ],
        ])),
      ]),
    );
  }
}

// ─── Auto sweep card ──────────────────────────────────────────────────────
class _AutoSweepCard extends StatelessWidget {
  final bool sweeping;
  final VoidCallback onSweep;
  const _AutoSweepCard({required this.sweeping, required this.onSweep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.accent.withOpacity(0.2), width: 0.8),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AdminColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.auto_awesome, size: 18, color: AdminColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('AI Autonomous Management', style: GoogleFonts.syne(
                fontSize: 13, fontWeight: FontWeight.w800, color: AdminColors.textPrimary)),
            const SizedBox(width: 6),
            const Icon(Icons.check_circle, size: 12, color: AdminColors.accent),
          ]),
          Text('Auto-redirecting expired food to Biogas & Farmers in real-time',
              style: GoogleFonts.dmSans(fontSize: 11, color: AdminColors.textMuted)),
        ])),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AdminColors.accent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('ACTIVE', style: GoogleFonts.syne(
              fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
        ),
      ]),
    );
  }
}

// ─── Area breakdown ───────────────────────────────────────────────────────
class _AreaBreakdown extends StatelessWidget {
  final Map<String, int> byArea;
  const _AreaBreakdown({required this.byArea});

  @override
  Widget build(BuildContext context) {
    final sorted = byArea.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV = sorted.first.value.toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminColors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Requests by Area', style: GoogleFonts.syne(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: AdminColors.textPrimary)),
        const SizedBox(height: 14),
        ...sorted.take(6).map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(width: 100, child: Text(e.key, style: GoogleFonts.dmSans(
                fontSize: 12, color: AdminColors.textSecondary),
                overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: e.value / maxV, minHeight: 8,
                backgroundColor: AdminColors.bg2,
                valueColor: const AlwaysStoppedAnimation(AdminColors.accent),
              ),
            )),
            const SizedBox(width: 8),
            Text('${e.value}', style: GoogleFonts.syne(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AdminColors.textPrimary)),
          ]),
        )),
      ]),
    );
  }
}

// ─── Volunteer leaderboard ────────────────────────────────────────────────
class _VolunteerLeaderboard extends StatelessWidget {
  final List<VolunteerPerformance> perfs;
  const _VolunteerLeaderboard({required this.perfs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AdminColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminColors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Volunteer Performance', style: GoogleFonts.syne(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: AdminColors.textPrimary)),
        const SizedBox(height: 4),
        Text('AI-computed scores (speed + completion + responsiveness)',
            style: GoogleFonts.dmSans(fontSize: 11, color: AdminColors.textMuted)),
        const SizedBox(height: 14),
        ...perfs.take(5).toList().asMap().entries.map((e) {
          final rank  = e.key + 1;
          final p     = e.value;
          final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank.';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              SizedBox(width: 28, child: Text(medal, style: const TextStyle(fontSize: 15))),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.volunteerName, style: GoogleFonts.syne(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: AdminColors.textPrimary)),
                Text(p.avgDeliveryMinutes > 0
                    ? 'Avg ${p.avgDeliveryMinutes.toStringAsFixed(0)}m · Score: ${p.performanceScore.toStringAsFixed(0)}'
                    : 'Score: ${p.performanceScore.toStringAsFixed(0)}',
                    style: GoogleFonts.dmSans(fontSize: 11, color: AdminColors.textMuted)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AdminColors.accentL,
                    borderRadius: BorderRadius.circular(6)),
                child: Text('${p.tasksCompleted} tasks', style: GoogleFonts.syne(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.accent)),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─── Activity tile ────────────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final FoodRequest request;
  const _ActivityTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final isAuto = request.assignedVolunteerId != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border, width: 0.5)),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: request.statusBg,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(request.statusIcon, size: 16, color: request.statusColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(request.foodType, style: GoogleFonts.syne(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AdminColors.textPrimary)),
          Text('${request.location} · ${request.quantity}',
              style: GoogleFonts.dmSans(fontSize: 11, color: AdminColors.textMuted)),
          if (request.volunteerName != null)
            Row(children: [
              if (isAuto) ...[
                const Icon(Icons.auto_awesome, size: 10, color: AdminColors.blue),
                const SizedBox(width: 3),
              ],
              Text(request.volunteerName!, style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: isAuto ? AdminColors.blue : AdminColors.textMuted)),
            ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AdminBadge(label: request.statusLabel,
              color: request.statusColor, bg: request.statusBg),
          const SizedBox(height: 4),
          AdminBadge(label: request.priority.label,
              color: request.priority.color, bg: request.priority.bg),
          const SizedBox(height: 4),
          Text(DateFormat('h:mm a').format(request.timestamp),
              style: GoogleFonts.dmSans(fontSize: 10, color: AdminColors.textMuted)),
        ]),
      ]),
    );
  }
}
