import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../admin_theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../widgets/admin_widgets.dart';

class AdminSurplusScreen extends StatefulWidget {
  const AdminSurplusScreen({super.key});
  @override
  State<AdminSurplusScreen> createState() => _AdminSurplusScreenState();
}

class _AdminSurplusScreenState extends State<AdminSurplusScreen>
    with SingleTickerProviderStateMixin {
  final _svc = FirebaseService();
  late TabController _tabs;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() => setState(() => _filterStatus = _tabStatus()));
  }

  String _tabStatus() {
    switch (_tabs.index) {
      case 1: return 'available';
      case 2: return 'accepted';
      case 3: return 'expired';
      default: return 'all';
    }
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.navy,
        title: Text('Surplus Food Control', style: GoogleFonts.syne(
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
                Tab(text: 'Available'),
                Tab(text: 'Accepted'),
                Tab(text: 'Expired'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<SurplusFood>>(
        stream: _svc.allSurplusFoodStream(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(
              child: CircularProgressIndicator(color: AdminColors.accent));

          if (snap.hasError) return AdminEmptyState(
            icon: Icons.error_outline,
            title: 'Error',
            subtitle: snap.error.toString(),
          );

          final all = snap.data!;
          final filtered = _filterStatus == 'all'
              ? all
              : all.where((s) => s.status == _filterStatus).toList();

          if (filtered.isEmpty) return const AdminEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Nothing here',
            subtitle: 'No surplus food in this category.',
          );

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _SurplusCard(
              item: filtered[i],
              onExpire: () => _expire(filtered[i]),
              onDelete: () => _delete(filtered[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _expire(SurplusFood item) async {
    final ok = await showAdminConfirmDialog(context,
      title: 'Mark as Expired?',
      body: '"${item.foodType}" will be marked expired and removed from the food feed.',
      confirmLabel: 'Mark Expired',
    );
    if (!ok || !mounted) return;
    await _svc.markSurplusExpired(item.id);
    _snack('Marked as expired', AdminColors.amber);
  }

  Future<void> _delete(SurplusFood item) async {
    final ok = await showAdminConfirmDialog(context,
      title: 'Delete Report?',
      body: 'This will permanently delete "${item.foodType}" and cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    await _svc.deleteSurplusFood(item.id);
    _snack('Report deleted', AdminColors.coral);
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

class _SurplusCard extends StatelessWidget {
  final SurplusFood item;
  final VoidCallback onExpire;
  final VoidCallback onDelete;

  const _SurplusCard({required this.item, required this.onExpire, required this.onDelete});

  Color get _statusColor {
    switch (item.status) {
      case 'available': return AdminColors.accent;
      case 'accepted':  return AdminColors.blue;
      case 'expired':   return AdminColors.coral;
      default:          return AdminColors.textMuted;
    }
  }

  Color get _statusBg {
    switch (item.status) {
      case 'available': return AdminColors.accentL;
      case 'accepted':  return AdminColors.blueL;
      case 'expired':   return AdminColors.coralL;
      default:          return AdminColors.bg2;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Header
          Row(children: [
            Text(item.imageEmoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.foodType, style: GoogleFonts.syne(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary)),
                Text(item.location, style: GoogleFonts.dmSans(
                    fontSize: 12, color: AdminColors.textMuted)),
              ],
            )),
            AdminBadge(label: item.status.toUpperCase(),
                color: _statusColor, bg: _statusBg),
          ]),
          const SizedBox(height: 10),
          Text(item.description, style: GoogleFonts.dmSans(
              fontSize: 12, color: AdminColors.textSecondary, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),

          // Meta row
          Wrap(spacing: 12, runSpacing: 6, children: [
            _meta(Icons.scale_outlined, item.quantity),
            _meta(Icons.person_outline, 'By: ${item.createdByName}'),
            _meta(Icons.schedule_outlined,
                DateFormat('MMM d, h:mm a').format(item.timestamp)),
            if (item.acceptedBy != null)
              _meta(Icons.directions_bike_outlined,
                  'Volunteer: ${item.acceptedByName ?? item.acceptedBy}'),
          ]),
          const SizedBox(height: 12),

          // Admin actions
          if (item.status != 'expired') Row(children: [
            if (item.status == 'available')
              SuccessButton(
                label: 'Mark Expired',
                icon: Icons.warning_amber_outlined,
                onTap: onExpire,
                color: AdminColors.amber,
                bg: AdminColors.amberL,
              ),
            const Spacer(),
            DangerButton(
              label: 'Delete',
              icon: Icons.delete_outline,
              onTap: onDelete,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: AdminColors.textMuted),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.dmSans(
          fontSize: 11, color: AdminColors.textSecondary)),
    ],
  );
}
