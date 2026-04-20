import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../admin_theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/app_state.dart';
import '../widgets/admin_widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService();
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),

          // ── Real-time stats ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<AdminStats>(
              stream: svc.adminStatsStream(),
              builder: (_, snap) {
                final s = snap.data ?? const AdminStats();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(children: [

                    // Row 1: reports + active requests
                    Row(children: [
                      Expanded(child: AdminStatCard(
                        value: '${s.totalReports}',
                        label: 'Surplus Reports',
                        icon: Icons.inventory_2_outlined,
                        color: AdminColors.accent,
                        bg: AdminColors.accentL,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: AdminStatCard(
                        value: '${s.activeRequests}',
                        label: 'Active Requests',
                        icon: Icons.pending_outlined,
                        color: AdminColors.amber,
                        bg: AdminColors.amberL,
                      )),
                    ]),
                    const SizedBox(height: 12),

                    // Row 2: deliveries + avg time
                    Row(children: [
                      Expanded(child: AdminStatCard(
                        value: '${s.completedDeliveries}',
                        label: 'Deliveries Done',
                        icon: Icons.task_alt_outlined,
                        color: AdminColors.blue,
                        bg: AdminColors.blueL,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: AdminStatCard(
                        value: s.avgDeliveryMinutes > 0
                            ? '${s.avgDeliveryMinutes.toStringAsFixed(0)}m'
                            : '—',
                        label: 'Avg Delivery Time',
                        icon: Icons.timer_outlined,
                        color: AdminColors.purple,
                        bg: AdminColors.purpleL,
                      )),
                    ]),
                    const SizedBox(height: 12),

                    // Row 3: active vols + expired
                    Row(children: [
                      Expanded(child: AdminStatCard(
                        value: '${s.activeVolunteers}',
                        label: 'Active Volunteers',
                        icon: Icons.directions_bike_outlined,
                        color: AdminColors.accent,
                        bg: AdminColors.accentL,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: AdminStatCard(
                        value: '${s.expiredItems}',
                        label: 'Expired Items',
                        icon: Icons.warning_amber_outlined,
                        color: AdminColors.coral,
                        bg: AdminColors.coralL,
                      )),
                    ]),
                    const SizedBox(height: 12),

                    // Row 4: pending reports + smart matching
                    Row(children: [
                      Expanded(child: AdminStatCard(
                        value: '${s.pendingUserReports}',
                        label: 'Pending Reports',
                        icon: Icons.flag_outlined,
                        color: AdminColors.coral,
                        bg: AdminColors.coralL,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: AdminStatCard(
                        value: '${s.autoAssignedCount}',
                        label: 'Auto-Matched',
                        icon: Icons.auto_awesome_outlined,
                        color: AdminColors.blue,
                        bg: AdminColors.blueL,
                        delta: '${s.manualAssignedCount} manual',
                      )),
                    ]),

                    // ── Requests by area ─────────────────────────────
                    if (s.requestsByArea.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _AreaBreakdown(byArea: s.requestsByArea),
                    ],

                    // ── Volunteer performance ─────────────────────────
                    if (s.volunteerPerformance.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _VolunteerLeaderboard(perfs: s.volunteerPerformance),
                    ],
                  ]),
                );
              },
            ),
          ),

          // ── Live activity feed ────────────────────────────────────────
          const SliverToBoxAdapter(
            child: AdminSectionHeader(
              title: 'Live Activity Feed',
              subtitle: 'Real-time updates across all apps',
            ),
          ),

          SliverToBoxAdapter(
            child: StreamBuilder<List<FoodRequest>>(
              stream: svc.allRequestsStream(),
              builder: (_, snap) {
                if (!snap.hasData) return const Padding(
                  padding: EdgeInsets.all(16),
                  child: AdminLoadingCard(),
                );
                final items = snap.data!.take(8).toList();
                if (items.isEmpty) return const Padding(
                  padding: EdgeInsets.all(16),
                  child: AdminEmptyState(
                    icon: Icons.feed_outlined,
                    title: 'No activity yet',
                    subtitle:
                        'Actions from User and Volunteer apps appear here in real time.',
                  ),
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: items.map((r) => _ActivityTile(request: r)).toList(),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AdminColors.navy,
      title: Row(children: [
        Text('Food', style: GoogleFonts.syne(
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        Text('Bridge', style: GoogleFonts.syne(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: const Color(0xFF74C69D))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text('Admin', style: GoogleFonts.syne(
              fontSize: 10, color: Colors.white70,
              fontWeight: FontWeight.w600)),
        ),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: Row(children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50), shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text('Live', style: GoogleFonts.syne(
                fontSize: 11, color: Colors.white70)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.logout_outlined,
              color: Colors.white70, size: 20),
          onPressed: () async {
            final appState = context.read<AppState>();
            appState.clearUser();
          },
        ),
      ],
    );
  }
}

// ─── Requests by area breakdown ───────────────────────────────────────────
class _AreaBreakdown extends StatelessWidget {
  final Map<String, int> byArea;
  const _AreaBreakdown({required this.byArea});

  @override
  Widget build(BuildContext context) {
    final sorted = byArea.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value.toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Requests by Area', style: GoogleFonts.syne(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: AdminColors.textPrimary)),
        const SizedBox(height: 14),
        ...sorted.take(6).map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(
              width: 100,
              child: Text(e.key, style: GoogleFonts.dmSans(
                  fontSize: 12, color: AdminColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: e.value / maxVal,
                  minHeight: 8,
                  backgroundColor: AdminColors.bg2,
                  valueColor: const AlwaysStoppedAnimation(AdminColors.accent),
                ),
              ),
            ),
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
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Volunteer Performance', style: GoogleFonts.syne(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: AdminColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Sorted by tasks completed', style: GoogleFonts.dmSans(
            fontSize: 11, color: AdminColors.textMuted)),
        const SizedBox(height: 14),
        ...perfs.take(5).toList().asMap().entries.map((e) {
          final rank = e.key + 1;
          final p    = e.value;
          final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank.';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              SizedBox(
                width: 28,
                child: Text(medal, style: const TextStyle(fontSize: 15)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.volunteerName, style: GoogleFonts.syne(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AdminColors.textPrimary)),
                  Text(
                    p.avgDeliveryMinutes > 0
                        ? 'Avg ${p.avgDeliveryMinutes.toStringAsFixed(0)}m delivery'
                        : 'No delivery data',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AdminColors.textMuted),
                  ),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminColors.accentL,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${p.tasksCompleted} tasks',
                    style: GoogleFonts.syne(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AdminColors.accent)),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─── Activity feed tile ───────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final FoodRequest request;
  const _ActivityTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: request.statusBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(request.statusIcon, size: 16,
              color: request.statusColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.foodType, style: GoogleFonts.syne(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AdminColors.textPrimary)),
            Text('${request.location} · ${request.quantity}',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AdminColors.textMuted)),
            if (request.volunteerName != null)
              Text('Volunteer: ${request.volunteerName}',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AdminColors.blue)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AdminBadge(
            label: request.statusLabel,
            color: request.statusColor,
            bg: request.statusBg,
          ),
          const SizedBox(height: 4),
          AdminBadge(
            label: request.priority.label,
            color: request.priority.color,
            bg: request.priority.bg,
          ),
          const SizedBox(height: 4),
          Text(DateFormat('h:mm a').format(request.timestamp),
              style: GoogleFonts.dmSans(
                  fontSize: 10, color: AdminColors.textMuted)),
        ]),
      ]),
    );
  }
}
