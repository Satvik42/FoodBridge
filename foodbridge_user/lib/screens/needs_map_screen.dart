import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/data.dart';
import '../widgets/common.dart';

class NeedsMapScreen extends StatefulWidget {
  const NeedsMapScreen({super.key});

  @override
  State<NeedsMapScreen> createState() => _NeedsMapScreenState();
}

class _NeedsMapScreenState extends State<NeedsMapScreen> {
  AreaZone? _selected;

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
              const SectionHeader(
                  title: 'Needs Heatmap',
                  subtitle: 'tap zone for details'),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bengaluru — Priority Zones',
                        style: GoogleFonts.syne(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: GestureDetector(
                        onTapDown: (d) => _handleMapTap(d.localPosition),
                        child: CustomPaint(
                          size: const Size(double.infinity, 240),
                          painter: _MapPainter(
                              zones: sampleZones,
                              selected: _selected),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Legend(color: AppColors.coralMid, label: 'Critical'),
                        const SizedBox(width: 16),
                        _Legend(color: AppColors.amberMid, label: 'High'),
                        const SizedBox(width: 16),
                        _Legend(color: AppColors.greenMid, label: 'Moderate'),
                        const SizedBox(width: 16),
                        _Legend(color: const Color(0xFF85B7EB), label: 'Low'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_selected != null) _buildDetailCard(_selected!),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: sampleZones.map(_buildZoneCard).toList(),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMapTap(Offset pos) {
    const w = 400.0, h = 240.0;
    for (final zone in sampleZones) {
      final zx = zone.mapX * w;
      final zy = zone.mapY * h;
      final radius = 20 + (zone.score / 100) * 35;
      if ((pos.dx - zx).abs() < radius && (pos.dy - zy).abs() < radius) {
        setState(() => _selected = zone);
        return;
      }
    }
    setState(() => _selected = null);
  }

  Widget _buildDetailCard(AreaZone zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: zone.scoreColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zone.scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.name,
                    style: GoogleFonts.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(zone.topNeed,
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            children: [
              Text('${zone.score}',
                  style: GoogleFonts.syne(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: zone.scoreColor)),
              Text('urgency score',
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(AreaZone zone) {
    return GestureDetector(
      onTap: () => setState(() => _selected = zone),
      child: Container(
        decoration: BoxDecoration(
          color: _selected == zone ? zone.scoreColor.withValues(alpha: 0.07) : AppColors.bg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selected == zone
                ? zone.scoreColor.withValues(alpha: 0.4)
                : AppColors.border,
            width: _selected == zone ? 1.5 : 0.5,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(zone.name,
                style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            Text('${zone.score}',
                style: GoogleFonts.syne(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: zone.scoreColor)),
            Text(zone.topNeed,
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            SeverityBar(
                fraction: zone.score / 100,
                color: zone.scoreColor,
                height: 5),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final List<AreaZone> zones;
  final AreaZone? selected;

  _MapPainter({required this.zones, this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF2F0E8);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(0)),
        bgPaint);

    // draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0x18000000)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 5; i++) {
      canvas.drawLine(Offset(size.width * i / 5, 0),
          Offset(size.width * i / 5, size.height), gridPaint);
      canvas.drawLine(Offset(0, size.height * i / 5),
          Offset(size.width, size.height * i / 5), gridPaint);
    }

    for (final zone in zones) {
      final x = zone.mapX * size.width;
      final y = zone.mapY * size.height;
      final r = 18.0 + (zone.score / 100) * 32;
      final isSelected = selected == zone;

      final fillPaint = Paint()..color = zone.bubbleColor;
      final strokePaint = Paint()
        ..color = zone.scoreColor.withValues(alpha: isSelected ? 1.0 : 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 1.2;

      canvas.drawCircle(Offset(x, y), r, fillPaint);
      canvas.drawCircle(Offset(x, y), r, strokePaint);

      final nameTp = TextPainter(
        text: TextSpan(
          text: zone.name,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: zone.scoreColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: r * 2.2);
      nameTp.paint(canvas, Offset(x - nameTp.width / 2, y - 9));

      final scoreTp = TextPainter(
        text: TextSpan(
          text: '${zone.score}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: zone.scoreColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      scoreTp.paint(canvas, Offset(x - scoreTp.width / 2, y + 2));
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.selected != selected || old.zones != zones;
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
