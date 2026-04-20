import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/common.dart';

class WasteResourceScreen extends StatefulWidget {
  const WasteResourceScreen({super.key});

  @override
  State<WasteResourceScreen> createState() => _WasteResourceScreenState();
}

class _WasteResourceScreenState extends State<WasteResourceScreen> {
  // Form state
  String _foodCategory = 'Cooked';
  String _expiryStatus = 'Near Expiry';
  String _redirectTo = 'Farmers (Compost / Manure)';
  String _quantity = '';
  String _location = '';
  bool _submitted = false;

  final _quantityCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  // Which recipient card is expanded
  String? _expandedRecipient;

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ─── Eco color palette (extends AppColors) ──────────────────────────────
  static const _eco1 = Color(0xFF2D6A4F);  // deep forest green
  static const _eco2 = Color(0xFF52B788);  // mid green
  static const _eco3 = Color(0xFFD8F3DC);  // pale mint
  static const _eco4 = Color(0xFFB7E4C7);  // soft green border
  static const _amber = Color(0xFFBA7517);
  static const _amberL = Color(0xFFFAEEDA);
  static const _coral = Color(0xFFD85A30);
  static const _coralL = Color(0xFFFAECE7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildImpactStrip(),
              const SizedBox(height: 20),
              _buildFormCard(),
              const SizedBox(height: 16),
              _buildRecipientSection(),
              const SizedBox(height: 16),
              _buildNearbyCard(),
              if (_submitted) ...[
                const SizedBox(height: 16),
                _buildImpactResult(),
              ],
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _eco3,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.recycling_rounded,
                  color: _eco1, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Waste to Resource',
                style: GoogleFonts.syne(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 6),
        Text('Turn food waste into compost, biogas, or animal feed',
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.textMuted, height: 1.4)),
      ],
    );
  }

  // ─── Impact stat strip ───────────────────────────────────────────────────
  Widget _buildImpactStrip() {
    final stats = [
      {'val': '2.4T', 'label': 'Waste diverted', 'icon': Icons.eco_outlined},
      {'val': '18', 'label': 'Farmers linked', 'icon': Icons.agriculture_outlined},
      {'val': '6', 'label': 'Biogas units', 'icon': Icons.bolt_outlined},
    ];
    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
                right: s == stats.last ? 0 : 10),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: _eco3,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _eco4, width: 0.5),
            ),
            child: Column(
              children: [
                Icon(s['icon'] as IconData, size: 18, color: _eco1),
                const SizedBox(height: 6),
                Text(s['val'] as String,
                    style: GoogleFonts.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _eco1)),
                const SizedBox(height: 2),
                Text(s['label'] as String,
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: _eco2),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Report Form ─────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Report Waste Food', 'quick form'),
          const SizedBox(height: 16),

          // Food category chips
          _fieldLabel('Food Category'),
          const SizedBox(height: 8),
          _chipRow(
            options: const ['Cooked', 'Raw', 'Packaged'],
            selected: _foodCategory,
            icons: const [
              Icons.soup_kitchen_outlined,
              Icons.grass_outlined,
              Icons.inventory_2_outlined,
            ],
            onTap: (v) => setState(() => _foodCategory = v),
          ),
          const SizedBox(height: 16),

          // Expiry status chips
          _fieldLabel('Expiry Status'),
          const SizedBox(height: 8),
          _expiryChips(),
          const SizedBox(height: 16),

          // Redirect to chips
          _fieldLabel('Redirect Waste To'),
          const SizedBox(height: 8),
          _redirectChips(),
          const SizedBox(height: 16),

          // Quantity
          _fieldLabel('Quantity'),
          const SizedBox(height: 6),
          TextField(
            controller: _quantityCtrl,
            onChanged: (v) => _quantity = v,
            decoration: const InputDecoration(
              hintText: 'e.g. 5kg, 20 plates, 2 bags',
              prefixIcon: Icon(Icons.scale_outlined,
                  size: 18, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 14),

          // Location
          _fieldLabel('Pickup Location'),
          const SizedBox(height: 6),
          TextField(
            controller: _locationCtrl,
            onChanged: (v) => _location = v,
            decoration: const InputDecoration(
              hintText: 'e.g. Indiranagar, 12th Main',
              prefixIcon: Icon(Icons.location_on_outlined,
                  size: 18, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleSubmit,
              icon: const Icon(Icons.recycling_rounded, size: 18),
              label: const Text('Submit & Find Recipients →'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _eco1,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: GoogleFonts.syne(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipRow({
    required List<String> options,
    required String selected,
    required List<IconData> icons,
    required ValueChanged<String> onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.asMap().entries.map((e) {
        final isOn = selected == e.value;
        return GestureDetector(
          onTap: () => onTap(e.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isOn ? _eco1 : AppColors.bg2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOn ? _eco1 : AppColors.border,
                width: isOn ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icons[e.key],
                    size: 15,
                    color: isOn ? Colors.white : AppColors.textMuted),
                const SizedBox(width: 6),
                Text(e.value,
                    style: GoogleFonts.syne(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isOn ? Colors.white : AppColors.textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _expiryChips() {
    final opts = [
      {'label': 'Near Expiry', 'icon': Icons.schedule_outlined, 'color': _amber, 'bg': _amberL},
      {'label': 'Expired', 'icon': Icons.warning_amber_outlined, 'color': _coral, 'bg': _coralL},
    ];
    return Row(
      children: opts.map((o) {
        final isOn = _expiryStatus == o['label'];
        final color = o['color'] as Color;
        final bg = o['bg'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _expiryStatus = o['label'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: o == opts.last ? 0 : 10),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isOn ? color.withOpacity(0.12) : AppColors.bg2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isOn ? color : AppColors.border,
                    width: isOn ? 1.5 : 0.5),
              ),
              child: Column(
                children: [
                  Icon(o['icon'] as IconData,
                      size: 20, color: isOn ? color : AppColors.textMuted),
                  const SizedBox(height: 5),
                  Text(o['label'] as String,
                      style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOn ? color : AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _redirectChips() {
    final opts = [
      {'label': 'Farmers (Compost / Manure)', 'icon': Icons.agriculture_outlined},
      {'label': 'Industries (Biogas / Recycling)', 'icon': Icons.factory_outlined},
    ];
    return Column(
      children: opts.map((o) {
        final isOn = _redirectTo == o['label'];
        return GestureDetector(
          onTap: () => setState(() => _redirectTo = o['label'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isOn ? _eco3 : AppColors.bg2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isOn ? _eco2 : AppColors.border,
                  width: isOn ? 1.5 : 0.5),
            ),
            child: Row(
              children: [
                Icon(o['icon'] as IconData,
                    size: 18,
                    color: isOn ? _eco1 : AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(o['label'] as String,
                      style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isOn ? _eco1 : AppColors.textSecondary)),
                ),
                if (isOn)
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: _eco1),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Recipient detail cards ───────────────────────────────────────────────
  Widget _buildRecipientSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Where Does It Go?', 'learn more'),
          const SizedBox(height: 14),
          _RecipientCard(
            title: 'Farmers',
            subtitle: 'Compost & organic manure',
            description:
                'Cooked and raw food waste is composted and converted into nutrient-rich manure for local farmers, reducing chemical fertilizer dependency.',
            icon: Icons.agriculture_outlined,
            iconBg: AppColors.greenLight,
            iconColor: AppColors.green,
            tags: const ['Compost', 'Organic Manure', 'Soil Health'],
            impact: 'Saves ₹800/ton in fertilizer costs',
            isExpanded: _expandedRecipient == 'Farmers',
            onTap: () => setState(() =>
                _expandedRecipient =
                    _expandedRecipient == 'Farmers' ? null : 'Farmers'),
          ),
          const SizedBox(height: 10),
          _RecipientCard(
            title: 'Small Industries',
            subtitle: 'Biogas & recycling units',
            description:
                'Packaged and bulk food waste is processed by local biogas plants and recycling units to generate clean energy and reduce landfill pressure.',
            icon: Icons.factory_outlined,
            iconBg: AppColors.amberLight,
            iconColor: AppColors.amber,
            tags: const ['Biogas', 'Clean Energy', 'Zero Landfill'],
            impact: 'Generates 0.5 m³ biogas per kg of waste',
            isExpanded: _expandedRecipient == 'Industries',
            onTap: () => setState(() =>
                _expandedRecipient =
                    _expandedRecipient == 'Industries' ? null : 'Industries'),
          ),
        ],
      ),
    );
  }

  // ─── Nearby recipients ────────────────────────────────────────────────────
  Widget _buildNearbyCard() {
    final nearby = [
      {
        'name': 'Green Earth Farm',
        'type': 'Farmer · Compost',
        'dist': '2.3 km',
        'accepts': 'Cooked · Raw',
        'color': AppColors.greenLight,
        'tcolor': AppColors.green,
      },
      {
        'name': 'Surabhi Organics',
        'type': 'Farmer · Manure',
        'dist': '4.1 km',
        'accepts': 'Raw · Packaged',
        'color': AppColors.greenLight,
        'tcolor': AppColors.green,
      },
      {
        'name': 'BioEnergy Blr',
        'type': 'Industry · Biogas',
        'dist': '5.8 km',
        'accepts': 'All types',
        'color': AppColors.amberLight,
        'tcolor': AppColors.amber,
      },
      {
        'name': 'EcoRecycle Hub',
        'type': 'Industry · Recycling',
        'dist': '7.2 km',
        'accepts': 'Packaged',
        'color': AppColors.amberLight,
        'tcolor': AppColors.amber,
      },
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Nearby Recipients', 'Bengaluru · sorted by distance'),
          const SizedBox(height: 14),
          ...nearby.map((r) => _NearbyRow(recipient: r)),
        ],
      ),
    );
  }

  // ─── Impact result after submit ──────────────────────────────────────────
  Widget _buildImpactResult() {
    final isFarmer = _redirectTo.contains('Farmer');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _eco3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _eco4, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _eco1,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.eco_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text('Environmental Impact',
                  style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _eco1)),
            ],
          ),
          const SizedBox(height: 14),
          _impactRow(
            Icons.check_circle_rounded,
            'Report submitted successfully!',
            '${_foodCategory} food · ${_expiryStatus} · redirected to ${isFarmer ? "Farmers" : "Industry"}',
          ),
          const SizedBox(height: 8),
          _impactRow(
            Icons.co2,
            isFarmer
                ? 'CO₂ emissions avoided'
                : 'Clean energy generated',
            isFarmer
                ? 'Approx. 1.2 kg CO₂ saved per kg composted'
                : 'Approx. 0.5 m³ biogas per kg processed',
          ),
          const SizedBox(height: 8),
          _impactRow(
            Icons.recycling,
            'Landfill waste diverted',
            'This waste will NOT go to landfill — it becomes a resource',
          ),
          const SizedBox(height: 8),
          _impactRow(
            Icons.notifications_outlined,
            '2 recipients notified',
            'Nearest ${isFarmer ? "farmer" : "industry"} will contact you within 2 hours',
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _eco1,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '🌱  Every kg you divert keeps Bengaluru greener',
              textAlign: TextAlign.center,
              style: GoogleFonts.syne(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _impactRow(IconData icon, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _eco1),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.syne(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _eco1)),
              Text(sub,
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: _eco2,
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  Widget _cardTitle(String title, String sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.syne(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        Text(sub,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text.toUpperCase(),
        style: GoogleFonts.syne(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.3));
  }

  void _handleSubmit() {
    setState(() => _submitted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Waste reported! Recipients notified.',
            style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: _eco1,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─── Recipient expandable card ─────────────────────────────────────────────
class _RecipientCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final List<String> tags;
  final String impact;
  final bool isExpanded;
  final VoidCallback onTap;

  const _RecipientCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.tags,
    required this.impact,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isExpanded ? iconBg.withOpacity(0.6) : AppColors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isExpanded
                ? iconColor.withOpacity(0.35)
                : AppColors.border,
            width: isExpanded ? 1 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: iconBg, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.syne(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text(subtitle,
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Text(description,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.6)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: iconColor.withOpacity(0.3),
                                width: 0.5),
                          ),
                          child: Text(t,
                              style: GoogleFonts.syne(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: iconColor)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.bolt_outlined, size: 14, color: iconColor),
                  const SizedBox(width: 5),
                  Text(impact,
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: iconColor)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Nearby recipient row ──────────────────────────────────────────────────
class _NearbyRow extends StatelessWidget {
  final Map<String, dynamic> recipient;
  const _NearbyRow({required this.recipient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: recipient['color'] as Color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              (recipient['type'] as String).contains('Farm')
                  ? Icons.agriculture_outlined
                  : Icons.factory_outlined,
              size: 18,
              color: recipient['tcolor'] as Color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipient['name'] as String,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                Text(
                    '${recipient['type']} · Accepts: ${recipient['accepts']}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(recipient['dist'] as String,
                  style: GoogleFonts.syne(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: recipient['tcolor'] as Color)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('Contact',
                    style: GoogleFonts.syne(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
