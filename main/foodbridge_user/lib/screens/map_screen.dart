import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../widgets/common.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final _svc = FirebaseService();
  FoodListing? _selected;
  Size _canvasSize = Size.zero;
  String _mapMode = 'supply';  // 'supply' | 'demand' | 'both'

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FoodListing>>(
      stream: _svc.listingsStream(),
      builder: (context, supplySnap) {
        return StreamBuilder<List<FoodRequest>>(
          stream: _svc.mapDemandStream(),
          builder: (context, demandSnap) {
            final listings = supplySnap.data ?? sampleListings;
            final demands  = demandSnap.data ?? [];

            return Scaffold(
              backgroundColor: AppColors.bg,
              appBar: AppBar(
                backgroundColor: AppColors.primary,
                title: Text('Food Map', style: GoogleFonts.syne(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Colors.white)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              body: Column(
                children: [
                  // ── Legend + mode switcher ─────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(children: [
                      _legendDot(AppColors.primary2, 'Fresh'),
                      const SizedBox(width: 12),
                      _legendDot(AppColors.amberMid, 'Near Expiry'),
                      const SizedBox(width: 12),
                      _legendDot(AppColors.coral, 'High Demand'),
                      const Spacer(),
                      _ModeChip(
                        label: 'Supply',
                        active: _mapMode == 'supply',
                        onTap: () => setState(() => _mapMode = 'supply'),
                      ),
                      const SizedBox(width: 6),
                      _ModeChip(
                        label: 'Demand',
                        active: _mapMode == 'demand',
                        onTap: () => setState(() => _mapMode = 'demand'),
                      ),
                      const SizedBox(width: 6),
                      _ModeChip(
                        label: 'Both',
                        active: _mapMode == 'both',
                        onTap: () => setState(() => _mapMode = 'both'),
                      ),
                    ]),
                  ),

                  // ── Map canvas ─────────────────────────────────────
                  Expanded(
                    flex: 3,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _canvasSize = Size(
                            constraints.maxWidth, constraints.maxHeight);
                        return GestureDetector(
                          onTapDown: (d) =>
                              _handleTap(d.localPosition, listings, demands),
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (_, __) => CustomPaint(
                              size: Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight),
                              painter: _MapPainter(
                                listings:  _mapMode != 'demand' ? listings : [],
                                demands:   _mapMode != 'supply' ? demands  : [],
                                selected:  _selected,
                                pulse:     _pulse.value,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Bottom panel ───────────────────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(color: Color(0x14000000),
                            blurRadius: 12, offset: Offset(0, -3)),
                      ],
                    ),
                    child: _selected != null
                        ? _SelectedPanel(
                            listing: _selected!,
                            onClose: () => setState(() => _selected = null),
                          )
                        : _ListingPreviewList(
                            listings: listings,
                            demands: demands,
                            mapMode: _mapMode,
                            onTap: (l) => setState(() => _selected = l),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleTap(Offset pos, List<FoodListing> listings,
      List<FoodRequest> demands) {
    final w = _canvasSize.width  > 0 ? _canvasSize.width  : 400.0;
    final h = _canvasSize.height > 0 ? _canvasSize.height : 400.0;
    for (final l in listings) {
      final x = l.mapX * w;
      final y = l.mapY * h;
      if ((pos.dx - x).abs() < 32 && (pos.dy - y).abs() < 32) {
        setState(() => _selected = l);
        return;
      }
    }
    setState(() => _selected = null);
  }

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: GoogleFonts.dmSans(
          fontSize: 11, color: AppColors.textSecondary)),
    ],
  );
}

// ─── Map CustomPainter with supply + demand layers ────────────────────────
extension on FoodListing {
  double get mapX => (lng - 77.50) / (77.80 - 77.50);
  double get mapY => 1 - (lat - 12.91) / (13.02 - 12.91);
}
extension on FoodRequest {
  double get mapX => (lng - 77.50) / (77.80 - 77.50);
  double get mapY => 1 - (lat - 12.91) / (13.02 - 12.91);
}

class _MapPainter extends CustomPainter {
  final List<FoodListing> listings;
  final List<FoodRequest> demands;
  final FoodListing? selected;
  final double pulse;

  _MapPainter({required this.listings, required this.demands,
      this.selected, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFE8F0E4));

    // Grid
    final roadP  = Paint()..color = Colors.white.withOpacity(0.7)..strokeWidth = 2;
    final minorP = Paint()..color = Colors.white.withOpacity(0.4)..strokeWidth = 1;
    for (int i = 1; i < 6; i++) {
      canvas.drawLine(Offset(size.width * i / 6, 0),
          Offset(size.width * i / 6, size.height), roadP);
      canvas.drawLine(Offset(0, size.height * i / 6),
          Offset(size.width, size.height * i / 6), roadP);
    }
    for (int i = 1; i < 12; i++) {
      canvas.drawLine(Offset(size.width * i / 12, 0),
          Offset(size.width * i / 12, size.height), minorP);
      canvas.drawLine(Offset(0, size.height * i / 12),
          Offset(size.width, size.height * i / 12), minorP);
    }

    // ── Demand heat circles (semi-transparent red) ─────────────────
    for (final d in demands) {
      final x = d.mapX * size.width;
      final y = d.mapY * size.height;
      canvas.drawCircle(Offset(x, y), 28,
          Paint()..color = const Color(0xFFD85A30).withOpacity(0.12));
    }

    // ── Supply markers ─────────────────────────────────────────────
    for (final l in listings) {
      final x = l.mapX * size.width;
      final y = l.mapY * size.height;
      final isSelected = selected == l;
      final markerColor = l.priority == Priority.high
          ? const Color(0xFFD85A30)
          : l.statusColor;

      if (isSelected) {
        canvas.drawCircle(Offset(x, y), 28 * pulse,
            Paint()..color = markerColor.withOpacity(0.2));
        canvas.drawCircle(Offset(x, y), 20 * pulse,
            Paint()..color = markerColor.withOpacity(0.15));
      }

      // Shadow
      canvas.drawCircle(Offset(x + 2, y + 2), isSelected ? 16 : 12,
          Paint()..color = Colors.black.withOpacity(0.12));

      // Circle — high priority gets coral fill
      canvas.drawCircle(Offset(x, y), isSelected ? 16 : 12,
          Paint()..color = markerColor);
      canvas.drawCircle(Offset(x, y), isSelected ? 16 : 12,
          Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);

      // Emoji
      final tp = TextPainter(
        text: TextSpan(text: l.imageEmoji,
            style: TextStyle(fontSize: isSelected ? 14 : 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));

      // Distance
      if (!isSelected && l.distanceKm > 0) {
        final dist = TextPainter(
          text: TextSpan(text: '${l.distanceKm}km',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                  color: markerColor)),
          textDirection: TextDirection.ltr,
        )..layout();
        dist.paint(canvas, Offset(x - dist.width / 2, y + 14));
      }
    }

    // User location
    final ux = size.width * 0.48, uy = size.height * 0.55;
    canvas.drawCircle(Offset(ux, uy), 10,
        Paint()..color = const Color(0xFF1A73E8));
    canvas.drawCircle(Offset(ux, uy), 10,
        Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(Offset(ux, uy), 20,
        Paint()..color = const Color(0xFF1A73E8).withOpacity(0.12));
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.selected != selected || old.pulse != pulse ||
      old.listings.length != listings.length ||
      old.demands.length != demands.length;
}

// ─── Selected listing panel — with prep time + priority ──────────────────
class _SelectedPanel extends StatefulWidget {
  final FoodListing listing;
  final VoidCallback onClose;
  const _SelectedPanel({required this.listing, required this.onClose});

  @override
  State<_SelectedPanel> createState() => _SelectedPanelState();
}

class _SelectedPanelState extends State<_SelectedPanel> {
  final _svc = FirebaseService();
  bool _requesting = false;
  bool _requested  = false;

  Future<void> _handleRequest() async {
    if (_requested || _requesting) return;
    setState(() => _requesting = true);
    try {
      await _svc.createRequest(
        foodId:   widget.listing.isSurplus
            ? widget.listing.surplusId
            : widget.listing.id,
        foodType: widget.listing.foodType,
        location: widget.listing.location,
        quantity: widget.listing.quantity,
      );
      if (!mounted) return;
      setState(() { _requesting = false; _requested = true; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request sent for ${widget.listing.foodType}!',
            style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      setState(() => _requesting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request failed: $e',
            style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppColors.coral, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l   = widget.listing;
    final age = DateTime.now().difference(l.postedAt);
    final ageStr = age.inMinutes < 60
        ? '${age.inMinutes}m ago'
        : age.inHours < 24
            ? '${age.inHours}h ago'
            : DateFormat('MMM d').format(l.postedAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text(l.imageEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.foodType, style: GoogleFonts.syne(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              Text('${l.donorName} · ${l.location}',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          )),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 6, children: [
          StatusBadge(label: l.statusLabel,
              color: l.statusColor, bg: l.statusBg),
          StatusBadge(label: l.quantity,
              color: AppColors.primary, bg: AppColors.primaryXL,
              icon: Icons.scale_outlined),
          StatusBadge(
            label: l.priority.label,
            color: l.priority.color, bg: l.priority.bg,
            icon: Icons.flag_outlined,
          ),
          StatusBadge(
            label: 'Prepared $ageStr',
            color: AppColors.textMuted, bg: AppColors.bg2,
            icon: Icons.schedule_outlined,
          ),
          if (l.distanceKm > 0)
            StatusBadge(label: '${l.distanceKm} km',
                color: AppColors.blue, bg: AppColors.blueL,
                icon: Icons.near_me_outlined),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.directions_outlined, size: 16),
              label: const Text('Navigate'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (_requesting || _requested) ? null : _handleRequest,
              icon: _requesting
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(_requested
                      ? Icons.check_circle_outline
                      : Icons.food_bank_outlined,
                      size: 16),
              label: Text(_requesting
                  ? 'Sending…'
                  : _requested ? 'Requested ✓' : 'Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _requested ? AppColors.primaryL : AppColors.primary,
                foregroundColor:
                    _requested ? AppColors.primary : Colors.white,
                disabledBackgroundColor: _requested
                    ? AppColors.primaryL
                    : AppColors.primary.withOpacity(0.6),
                disabledForegroundColor: _requested
                    ? AppColors.primary : Colors.white70,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─── Preview list ─────────────────────────────────────────────────────────
class _ListingPreviewList extends StatelessWidget {
  final List<FoodListing> listings;
  final List<FoodRequest> demands;
  final String mapMode;
  final ValueChanged<FoodListing> onTap;

  const _ListingPreviewList({
    required this.listings,
    required this.demands,
    required this.mapMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(children: [
          Expanded(child: Text('Tap a marker to view details',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted))),
          if (demands.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.coralL,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.coral.withOpacity(0.3), width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on, size: 11, color: AppColors.coral),
                const SizedBox(width: 4),
                Text('${demands.length} active requests',
                    style: GoogleFonts.syne(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppColors.coral)),
              ]),
            ),
          if (demands.isNotEmpty) const SizedBox(width: 8),
          Text('${listings.length} spots', style: GoogleFonts.syne(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.primary2)),
        ]),
      ),
      SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          itemCount: listings.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final l = listings[i];
            return GestureDetector(
              onTap: () => onTap(l),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: l.priority == Priority.high
                      ? AppColors.coralL.withOpacity(0.5)
                      : l.statusBg.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: l.priority == Priority.high
                          ? AppColors.coral.withOpacity(0.4)
                          : l.statusColor.withOpacity(0.3),
                      width: 0.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(l.imageEmoji,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l.foodType, style: GoogleFonts.syne(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                      Row(children: [
                        if (l.priority == Priority.high)
                          Text('🔴 ', style: const TextStyle(fontSize: 9)),
                        Text(
                          l.distanceKm > 0
                              ? '${l.distanceKm} km'
                              : 'Nearby',
                          style: GoogleFonts.dmSans(
                              fontSize: 10, color: AppColors.textMuted),
                        ),
                      ]),
                    ],
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// ─── Mode chip ────────────────────────────────────────────────────────────
class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.bg2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border, width: 0.5),
        ),
        child: Text(label, style: GoogleFonts.syne(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}
