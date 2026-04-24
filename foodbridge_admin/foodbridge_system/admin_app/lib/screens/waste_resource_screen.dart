import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin_theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';

class WasteResourceScreen extends StatefulWidget {
  const WasteResourceScreen({super.key});
  @override
  State<WasteResourceScreen> createState() => _WasteResourceScreenState();
}

class _WasteResourceScreenState extends State<WasteResourceScreen> {
  final _svc = FirebaseService();
  Stream<List<SurplusFood>>? _redirectedStream;

  @override
  void initState() {
    super.initState();
    _redirectedStream = _svc.allSurplusFoodStream().map((list) => 
      list.where((s) => s.status == 'redirected' && 
                 !(s.expiryStatus.toLowerCase() == 'fresh' && s.wasteType == 'biogas')).toList());
  }

  static const _eco1   = Color(0xFF2D6A4F);
  static const _eco2   = Color(0xFF52B788);
  static const _eco3   = Color(0xFFD8F3DC);
  static const _eco4   = Color(0xFFB7E4C7);
  static const _amber  = Color(0xFFBA7517);
  static const _amberL = Color(0xFFFAEEDA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildImpactStrip(),
              const SizedBox(height: 24),
              _buildLiveAutomationHeader(),
              const SizedBox(height: 12),
              _buildLiveAutomationFeed(),
              const SizedBox(height: 24),
              _buildRecipientSection(),
              const SizedBox(height: 16),
              _buildNearbyCard(),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _eco3, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.recycling_rounded, color: _eco1, size: 20),
          ),
          const SizedBox(width: 10),
          Text('Waste to Resource Monitor',
              style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: AdminColors.textPrimary)),
        ]),
        const SizedBox(height: 6),
        Text('100% Autonomous AI redirection of food waste into resources.',
            style: GoogleFonts.dmSans(fontSize: 13, color: AdminColors.textMuted, height: 1.4)),
      ],
    );
  }

  Widget _buildImpactStrip() {
    return StreamBuilder<AdminStats>(
      stream: _svc.adminStatsStream(),
      builder: (context, snap) {
        final s = snap.data;
        final stats = [
          {'val': '${s?.wasteRedirectedCount ?? 0}', 'label': 'Items diverted',  'icon': Icons.recycling_rounded},
          {'val': '18',   'label': 'Farmers linked',   'icon': Icons.agriculture_outlined},
          {'val': '6',    'label': 'Biogas units',      'icon': Icons.bolt_outlined},
        ];
        return Row(
          children: stats.map((item) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: item == stats.last ? 0 : 10),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: _eco3,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _eco4, width: 0.5),
              ),
              child: Column(children: [
                Icon(item['icon'] as IconData, size: 18, color: _eco1),
                const SizedBox(height: 6),
                Text(item['val'] as String,
                    style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: _eco1)),
                const SizedBox(height: 2),
                Text(item['label'] as String,
                    style: GoogleFonts.dmSans(fontSize: 10, color: _eco2),
                    textAlign: TextAlign.center),
              ]),
            ),
          )).toList(),
        );
      }
    );
  }

  Widget _buildLiveAutomationHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _eco1.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _eco1.withAlpha(51)),
      ),
      child: Row(children: [
        const Icon(Icons.auto_awesome, color: _eco1, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI Autonomous Engine: ACTIVE',
              style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: _eco1)),
          Text('Monitoring all reports. Expired/Near-expiry items are redirected automatically.',
              style: GoogleFonts.dmSans(fontSize: 11, color: _eco2)),
        ])),
      ]),
    );
  }

  Widget _buildLiveAutomationFeed() {
    return StreamBuilder<List<SurplusFood>>(
      stream: _redirectedStream,
      builder: (context, snap) {
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AdminColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.border, width: 0.5),
            ),
            child: Column(children: [
              const Icon(Icons.radar_rounded, size: 40, color: AdminColors.textMuted),
              const SizedBox(height: 12),
              Text('Scanning for Waste...',
                  style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w600, color: AdminColors.textSecondary)),
              Text('AI is monitoring surplus reports in the background.',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AdminColors.textMuted)),
            ]),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Autonomous Decisions',
                style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textSecondary)),
            const SizedBox(height: 12),
            ...items.take(10).map((s) => _buildAutomationTile(s)),
          ],
        );
      },
    );
  }

  Widget _buildAutomationTile(SurplusFood s) {
    final isBiogas = s.wasteType == 'biogas';
    final color = isBiogas ? Color(0xFFBA7517) : _eco1;
    final bg = isBiogas ? Color(0xFFFAEEDA) : _eco3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border, width: 0.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(isBiogas ? Icons.bolt_outlined : Icons.agriculture_outlined, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(s.foodType, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AdminColors.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(4)),
              child: Text(s.expiryStatus.toUpperCase(), style: GoogleFonts.syne(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
            ),
          ]),
          Text('Redirected to ${isBiogas ? "Biogas Plant" : "Local Farmers"} \u00b7 ${s.quantity}',
              style: GoogleFonts.dmSans(fontSize: 11, color: AdminColors.textMuted)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('COMPLETED', style: GoogleFonts.syne(fontSize: 9, fontWeight: FontWeight.w800, color: _eco2)),
          Text('By AI Engine', style: GoogleFonts.dmSans(fontSize: 9, color: AdminColors.textMuted)),
        ]),
      ]),
    );
  }

  Widget _buildRecipientSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Where Does It Go?', 'learn more'),
          const SizedBox(height: 14),
          _RecipientCard(
            title: 'Farmers', subtitle: 'Compost & organic manure',
            description: 'Cooked and raw food waste is composted and converted into nutrient-rich manure for local farmers, reducing chemical fertilizer dependency.',
            icon: Icons.agriculture_outlined,
            iconBg: AdminColors.accentL, iconColor: AdminColors.accent,
            tags: const ['Compost', 'Organic Manure', 'Soil Health'],
            impact: 'Saves \u20b9800/ton in fertilizer costs',
          ),
          const SizedBox(height: 10),
          _RecipientCard(
            title: 'Small Industries', subtitle: 'Biogas & recycling units',
            description: 'Packaged and bulk food waste is processed by local biogas plants and recycling units to generate clean energy and reduce landfill pressure.',
            icon: Icons.factory_outlined,
            iconBg: AdminColors.amberL, iconColor: AdminColors.amber,
            tags: const ['Biogas', 'Clean Energy', 'Zero Landfill'],
            impact: 'Generates 0.5 m\u00b3 biogas per kg of waste',
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyCard() {
    final nearby = [
      {'name': 'Green Earth Farm',   'type': 'Farmer \u00b7 Compost',    'dist': '2.3 km', 'accepts': 'Cooked \u00b7 Raw',   'color': AdminColors.accentL, 'tcolor': AdminColors.accent},
      {'name': 'Surabhi Organics',   'type': 'Farmer \u00b7 Manure',     'dist': '4.1 km', 'accepts': 'Raw \u00b7 Packaged', 'color': AdminColors.accentL, 'tcolor': AdminColors.accent},
      {'name': 'BioEnergy Blr',      'type': 'Industry \u00b7 Biogas',   'dist': '5.8 km', 'accepts': 'All types',            'color': AdminColors.amberL,  'tcolor': AdminColors.amber},
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Nearby Recipients', 'Bengaluru \u00b7 sorted by distance'),
          const SizedBox(height: 14),
          ...nearby.map((r) => _NearbyRow(recipient: r)),
        ],
      ),
    );
  }

  Widget _cardTitle(String title, String sub) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: AdminColors.textPrimary)),
      Text(sub,   style: GoogleFonts.dmSans(fontSize: 11, color: AdminColors.textMuted)),
    ]);
  }
}

class _RecipientCard extends StatelessWidget {
  final String title, subtitle, description, impact;
  final IconData icon;
  final Color iconBg, iconColor;
  final List<String> tags;

  const _RecipientCard({
    required this.title, required this.subtitle, required this.description,
    required this.icon, required this.iconBg, required this.iconColor,
    required this.tags, required this.impact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: iconColor)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AdminColors.textPrimary)),
            Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: AdminColors.textMuted)),
          ])),
        ]),
        const SizedBox(height: 12),
        Text(description, style: GoogleFonts.dmSans(fontSize: 12, color: AdminColors.textSecondary, height: 1.6)),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6,
          children: tags.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: iconColor.withAlpha(76), width: 0.5),
            ),
            child: Text(t, style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w600, color: iconColor)),
          )).toList(),
        ),
      ]),
    );
  }
}

class _NearbyRow extends StatelessWidget {
  final Map<String, dynamic> recipient;
  const _NearbyRow({required this.recipient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: recipient['color'] as Color, borderRadius: BorderRadius.circular(8)),
          child: Icon(
            (recipient['type'] as String).contains('Farm') ? Icons.agriculture_outlined : Icons.factory_outlined,
            size: 18, color: recipient['tcolor'] as Color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(recipient['name'] as String,
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AdminColors.textPrimary)),
          Text('${recipient['type']} \u00b7 Accepts: ${recipient['accepts']}',
              style: GoogleFonts.dmSans(fontSize: 11, color: AdminColors.textMuted)),
        ])),
        Text(recipient['dist'] as String,
            style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w600, color: recipient['tcolor'] as Color)),
      ]),
    );
  }
}
