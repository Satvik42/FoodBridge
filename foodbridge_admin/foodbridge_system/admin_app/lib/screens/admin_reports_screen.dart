import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../admin_theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../widgets/admin_widgets.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  final _svc = FirebaseService();
  late TabController _tabs;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.navy,
        title: Text('User Reports', style: GoogleFonts.syne(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: AdminColors.navy,
            child: TabBar(
              controller: _tabs,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: Color(0xFF74C69D), width: 2.5),
                insets: EdgeInsets.symmetric(horizontal: 16),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700),
              tabs: const [Tab(text: 'Pending'), Tab(text: 'Resolved')],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<UserReport>>(
        stream: _svc.allUserReportsStream(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
              child: CircularProgressIndicator(color: AdminColors.accent));

          final all      = snap.data!;
          final pending  = all.where((r) => r.status == 'pending').toList();
          final resolved = all.where((r) => r.status == 'resolved').toList();

          return TabBarView(
            controller: _tabs,
            children: [
              _ReportList(reports: pending,  svc: _svc, showActions: true),
              _ReportList(reports: resolved, svc: _svc, showActions: false),
            ],
          );
        },
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  final List<UserReport> reports;
  final FirebaseService svc;
  final bool showActions;

  const _ReportList({required this.reports, required this.svc, required this.showActions});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return AdminEmptyState(
        icon: Icons.flag_outlined,
        title: showActions ? 'No pending reports' : 'No resolved reports',
        subtitle: showActions
            ? 'All user reports have been addressed.'
            : 'Resolved reports will appear here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: reports.length,
      itemBuilder: (ctx, i) => _ReportCard(
        report: reports[i],
        svc: svc,
        showActions: showActions,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final UserReport report;
  final FirebaseService svc;
  final bool showActions;

  const _ReportCard({required this.report, required this.svc, required this.showActions});

  static const _typeColors = {
    ReportType.spoiledFood:       AdminColors.coral,
    ReportType.incorrectLocation: AdminColors.amber,
    ReportType.notAvailable:      AdminColors.blue,
    ReportType.other:             AdminColors.purple,
  };
  static const _typeBgs = {
    ReportType.spoiledFood:       AdminColors.coralL,
    ReportType.incorrectLocation: AdminColors.amberL,
    ReportType.notAvailable:      AdminColors.blueL,
    ReportType.other:             AdminColors.purpleL,
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[report.reportType] ?? AdminColors.textMuted;
    final bg    = _typeBgs[report.reportType]    ?? AdminColors.bg2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(report.reportTypeIcon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.reportTypeLabel, style: GoogleFonts.syne(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary)),
                Text('User: ${report.userId.length > 10 ? report.userId.substring(0, 10) + '…' : report.userId}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AdminColors.textMuted)),
              ],
            )),
            AdminBadge(
              label: report.status.toUpperCase(),
              color: report.status == 'resolved' ? AdminColors.accent : AdminColors.coral,
              bg: report.status == 'resolved' ? AdminColors.accentL : AdminColors.coralL,
            ),
          ]),
          const SizedBox(height: 10),
          Text(report.description, style: GoogleFonts.dmSans(
              fontSize: 13, color: AdminColors.textSecondary, height: 1.5)),
          const SizedBox(height: 8),
          Text(DateFormat('MMM d, y · h:mm a').format(report.timestamp),
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: AdminColors.textMuted)),
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(children: [
              SuccessButton(
                label: 'Resolve',
                icon: Icons.check_circle_outline,
                onTap: () async {
                  await svc.resolveUserReport(report.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Report resolved',
                          style: GoogleFonts.dmSans(fontSize: 13)),
                      backgroundColor: AdminColors.accent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  }
                },
              ),
              const Spacer(),
              DangerButton(
                label: 'Delete',
                icon: Icons.delete_outline,
                onTap: () async {
                  final ok = await showAdminConfirmDialog(context,
                    title: 'Delete Report?',
                    body: 'This will permanently delete this report.',
                  );
                  if (!ok || !context.mounted) return;
                  await svc.deleteUserReport(report.id);
                },
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
