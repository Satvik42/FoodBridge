import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../admin_theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../widgets/admin_widgets.dart';

class AdminWasteScreen extends StatelessWidget {
  const AdminWasteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService();
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.navy,
        title: Text('Waste Management', style: GoogleFonts.syne(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<SurplusFood>>(
        stream: svc.allSurplusFoodStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          // Filter for expired items only
          final expired = snapshot.data!.where((s) => s.status == 'expired').toList();
          
          if (expired.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.recycling_rounded,
              title: 'No waste items',
              subtitle: 'Expired or spoiled food will appear here for redirection.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: expired.length,
            itemBuilder: (_, i) => _WasteItemCard(food: expired[i]),
          );
        },
      ),
    );
  }
}

class _WasteItemCard extends StatelessWidget {
  final SurplusFood food;
  const _WasteItemCard({required this.food});

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService();
    final timeSince = DateTime.now().difference(food.preparedTime);
    final hoursSince = timeSince.inHours;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(food.imageEmoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.foodType, style: GoogleFonts.syne(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary)),
                Text('${food.quantity} · ${food.location}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AdminColors.textMuted)),
              ],
            )),
            AdminBadge(
              label: 'Expired',
              color: AdminColors.coral,
              bg: AdminColors.coralL,
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.timer_outlined, size: 14, color: AdminColors.textMuted),
            const SizedBox(width: 6),
            Text('Prepared $hoursSince hours ago', style: GoogleFonts.dmSans(
                fontSize: 11, color: AdminColors.textSecondary)),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AdminColors.border),
          const SizedBox(height: 16),
          
          // Smart Suggestion
          Row(children: [
            const Icon(Icons.auto_awesome, size: 16, color: AdminColors.blue),
            const SizedBox(width: 8),
            Text('Suggested Action:', style: GoogleFonts.syne(
                fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.blue)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AdminColors.blueL,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                food.autoRoute.name.toUpperCase(),
                style: GoogleFonts.syne(
                    fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.blue),
              ),
            ),
          ]),
          
          const SizedBox(height: 20),
          Text('Redirection Options:', style: GoogleFonts.syne(
              fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ActionBtn(
              label: 'Biogas',
              icon: Icons.ev_station_rounded,
              color: const Color(0xFF4CAF50),
              onTap: () => svc.redirectWaste(food.id, 'biogas'),
            )),
            const SizedBox(width: 8),
            Expanded(child: _ActionBtn(
              label: 'Farmer',
              icon: Icons.agriculture_rounded,
              color: const Color(0xFFFF9800),
              onTap: () => svc.redirectWaste(food.id, 'farmer'),
            )),
            const SizedBox(width: 8),
            Expanded(child: _ActionBtn(
              label: 'Discard',
              icon: Icons.delete_outline_rounded,
              color: AdminColors.textMuted,
              onTap: () => svc.redirectWaste(food.id, 'discard'),
            )),
          ]),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label, required this.icon,
    required this.color, required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.syne(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}
